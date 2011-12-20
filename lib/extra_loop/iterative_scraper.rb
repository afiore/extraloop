class IterativeScraper < ScraperBase


  #
  # Public
  #
  # Initializes an iterative scraper (i.e. a scraper which can extract data from a list of several web pages).
  # 
  # urls      -  One (or an array of) url pattern/s.
  # options   -  A hash of scraper options (optional).
  #   async : Wether or not the scraper should issue HTTP requests synchronously or asynchronously (defaults to false).
  #   log   : Logging options (set to false to completely suppress logging).
  #   hydra : A list of arguments to be passed in when initializing the HTTP queue (see Typheous#Hydra).
  # arguments - Hash of arguments to be passed to the Typhoeus HTTP client (optional).
  #
  #
  # Examples:
  #
  # # Iterates over the first 10 pages of Google News search result for the query 'Egypt'.
  #
  # IterativeScraper.new("https://www.google.com/search?tbm=nws&q=Egypt&start=:start", :log => {
  #     :appenders => [ 'example.log', :stderr],
  #     :log_level => :debug
  #
  #   }).set_iteration(:start, (1..101).step(10))
  #
  # # Iterates over the first 10 pages of Google News search results for the query 'Egypt' first, and then
  # # for the query 'Syria', issuing HTTP requests asynchronously, and ignoring ssl certificate verification.
  #
  # IterativeScraper.new([
  #     https://www.google.com/search?tbm=nws&q=Egypt&start=:start",
  #     https://www.google.com/search?tbm=nws&q=Syria&start=:start"
  #   ], {:async => true,  }, {:disable_ssl_peer_verification => true
  #
  # }).set_iteration(:start, (1..101).step(10))
  #
  # Returns itself.
  #

  def initialize(urls, options = {}, arguments = {})
    super([], options, arguments)

    @url_patterns = Array(urls)
    @iteration_set = []
    @iteration_extractor = nil
    @iteration_count = 0
    @iteration_param = nil
    @iteration_param_value = nil
    self
  end


  # Public
  #
  # Specifies the collection of values over which the scraper should iterate (Values will be interpolated one by one into the scraper URL pattern/s).
  #
  # param - the name of the parameter to interpolate (NOTE: this is probably not needed).
  # args  - Either an array of values, or a set the arguments to initialize an Extractor object.
  #
  # Examples:
  #
  #  # Explicitly specify the iteration set (can be either a range or an array).
  #
  #   IterativeScraper.new("http://my-site.com/events?p=:p").
  #     set_iteration(:p, 1..10).
  #
  #  # Pass in a code block to dynamically extract the iteration set from the document.
  #  # The code block will be passed to generate an Extractor that will be run at the first
  #  # iteration. The iteration will not continue if the proc will return return a non empty 
  #  # set of values.
  #
  #  fetch_page_numbers = proc { |elements|
  #    elements.map { |a|
  #       a.attr(:href).match(/p=(\d+)/)
  #       $1
  #    }.reject { |p| p == 1 }
  #  }
  #
  #  IterativeScraper.new("http://my-site.com/events?p=:p").
  #    set_iteration(:p, "div#pagination a", fetch_page_numbers)
  #
  #
  # Returns itself.
  #

  def set_iteration(param, *args)
    #TODO: allow passing ranges as well as arrays
    if args.first.respond_to?(:map)
      @iteration_set = Array(args.first).map &:to_s
    else
      @iteration_extractor = Extractor.new(:pagination, *args)
    end
    set_iteration_param(param)
    self
  end

  def run
    @url_patterns.each do |pattern|

      # run an extra iteration when the iteration set has not been provided
      (run_iteration(pattern); @iteration_count += 1 ) if @iteration_extractor 

      while @iteration_set.at(@iteration_count)
        method = @options[:async] ? :run_iteration_async : :run_iteration
        send(method, pattern)
        @iteration_count += 1
      end

      #reset all counts
      @queued_count = 0
      @response_count = 0
      @iteration_count = 0
    end
    self
  end

  protected

  # TODO: Interpolation should work also with non GET parameters..
  #
  # Interal method used to set the parameter which will be interpolated during the scrape iterations.
  #
  # param - a symbol or a hash containing the parameter name (as the key) and its default value.
  #
  # Returns nothing.
  #
  # 
  def set_iteration_param(param)
    if param.respond_to?(:keys)
      @iteration_param = param.keys.first
      @iteration_param_value = param.values.first
    else
      @iteration_param = param
    end
  end

  def default_offset
    @iteration_param_value or "1"
  end

  def run_iteration(url_pattern)
    url = interpolate_url(url_pattern)
    @urls = Array(url)
    run_super(:run)
  end

  def run_iteration_async(url_pattern)
    @urls << interpolate_url(url_pattern)
    if @iteration_set.empty?
      run_super(:run)
    end
  end

  #interpolate the url 

  def interpolate_url(url)
    offset = @iteration_set.at(@iteration_count) || default_offset
    url.gsub(":#{@iteration_param.to_s}", offset)
  end

  #
  # Utility function for calling a superclass instance method.
  #
  # (currently used to call ScraperBase#run).
  #

  def run_super(method, args=[])
    self.class.superclass.instance_method(method).bind(self).call
  end

  def handle_response(response)
    @iteration_set = Array(default_offset) + extract_iteration_set(response) if @response_count == 0 && @iteration_extractor
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
