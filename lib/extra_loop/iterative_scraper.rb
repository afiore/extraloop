class IterativeScraper < ScraperBase
  def initialize(urls, options = {}, arguments)
    super([], options, arguments)

    @url_patterns = Array(urls)
    @iteration_set = []
    @iteration_extractor = nil
    @iteration_count = 0
    @iteration_param = nil
    @iteration_param_value = nil
  end


  # Public
  #
  # Sets the scraper iteration by providing either a collection of values (to be interpolated into the URL patterns)
  # or an extractor block to produce such values.
  #
  # param - the name of the parameter to interpolate (NOTE: this is probably not needed).
  # args  - Either an array of values, or a set the arguments to initialize an Extractor object.
  #
  # Returns itself.
  #

  def set_iteration(param, *args)
    if args.first.respond_to?(:map)
      @iteration_set = Array(collection).map &:to_s
    else
      @iteration_extractor = Extractor.new(:pagination, *args)
    end
    set_iteration_param(param)
    self
  end

  def run
    @url_patterns.each do |pattern|
      run_iteration(pattern)

      while @iteration_set.any?
        method = @options[:async] ? :run_iteration_async : :run_iteration
        self.send(method, pattern)
        @iteration_count += 1
      end

      #reset all counts
      @queued_count = 0
      @response_count = 0
      @iteration_count = 0
    end
  end

  protected
  def set_iteration_param(param)
    if param.respond_to?(:keys)
      @iteration_param = param.keys.first
      @iteration_param_value = param.values.first
    else
      @iteration_param = param
    end
  end

  def current_offset
    # start without specifying an offset if the iteration set not been determined yet
    (@iteration_set.empty?) ? self.default_offset :  @iteration_set.shift
  end

  def default_offset
    @iteration_param_value or "1"
  end

  def run_iteration(url_pattern)
    @urls = Array(url_pattern.gsub(":#{@iteration_param.to_s}", current_offset))
    run_super(:run)
  end

  def run_iteration_async(url_pattern)
    @urls << interpolate_url(url_pattern)
    if @iteration_set.empty?
      run_super(:run)
    end
  end

  def interpolate_url(url, offset=nil)
    offset ||= current_offset
    url.gsub(":#{@iteration_param.to_s}", offset)
  end


  def run_super(method)
    self.class.superclass.instance_method(method).bind(self).call
  end

  def handle_response(response)
    @iteration_set = extract_iteration_set(response) if @response_count == 0 && @iteration_extractor
    super(response)
  end

  # 
  # Runs the extractor provided in order to dynamically fetch the array of values needed for the iterative scrape.
  #
  # Returns an array of strings.
  #
  #

  def extract_iteration_set(response)
    @iteration_extractor.extract_list(response.body).map(&:to_s)
  end
end
