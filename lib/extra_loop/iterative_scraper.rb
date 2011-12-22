class IterativeScraper < ScraperBase

  module Exceptions
    class NonGetAsyncRequestNotYetImplemented < StandardError; end
  end


  #
  # Public
  #
  # Initializes an iterative scraper (i.e. a scraper which can extract data from a list of several web pages).
  # 
  # urls      -  One or an array of several urls.
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
  # IterativeScraper.new("https://www.google.com/search?tbm=nws&q=Egypt", :log => {
  #     :appenders => [ 'example.log', :stderr],
  #     :log_level => :debug
  #
  #   }).set_iteration(:start, (1..101).step(10))
  #
  # # Iterates over the first 10 pages of Google News search results for the query 'Egypt' first, and then
  # # for the query 'Syria', issuing HTTP requests asynchronously, and ignoring ssl certificate verification.
  #
  # IterativeScraper.new([
  #     https://www.google.com/search?tbm=nws&q=Egypt",
  #     https://www.google.com/search?tbm=nws&q=Syria"
  #   ], {:async => true,  }, {:disable_ssl_peer_verification => true
  #
  # }).set_iteration(:start, (1..101).step(10))
  #
  # Returns itself.
  #

  def initialize(urls, options = {}, arguments = {})
    super([], options, arguments)

    @base_urls = Array(urls)
    @iteration_set = []
    @iteration_extractor = nil
    @iteration_extractor_args = nil
    @iteration_count = 0
    @iteration_param = nil
    @iteration_param_value = nil
    self
  end


  # Public
  #
  # Specifies the collection of values over which the scraper should iterate. 
  # At each iteration, the current value in the iteration set will be included as part of the request parameters.
  #
  # param - the name of the iteration parameter.
  # args  - Either an array of values, or a set the arguments to initialize an Extractor object.
  #
  # Examples:
  #
  #  # Explicitly specify the iteration set (can be either a range or an array).
  #
  #   IterativeScraper.new("http://my-site.com/events").
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
  #  IterativeScraper.new("http://my-site.com/events").
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
      @iteration_extractor_args = [:pagination, *args]
    end
    set_iteration_param(param)
    self
  end



  def run
    @base_urls.each do |pattern|
      # run an extra iteration when the arguments for extractoing the iteration set have not been provided
      (run_iteration(pattern); @iteration_count += 1 ) if @iteration_extractor_args

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


  # 
  # Runs an iteration performing an HTTP request per time (
  # calls ScraperBase#run at each request)
  #
  # url - the current iteration's url.
  #
  # Returns nothing
  #

  def run_iteration(url)
    @urls = Array(url)
    update_request_params!
    run_super(:run)
  end

  #
  # Runs an iteration asynchronously
  #
  # url - The current iteration's url.
  #
  # Returns nothing.
  #
  #
  def run_iteration_async(url)
    error_message = "When then option 'async' is set to true the IterativeScraper class currently supports only HTTP method 'get'." +
      "If you have to use another HTTP method, you must set the 'async' option to false."

    raise NonGetAsyncRequestNotYetImplemented error_message unless @request_arguments[:method].nil? || @request_arguments[:method].downcase.to_sym == :get

    @urls << add_iteration_param(url)

    if @iteration_set.size - 1 == @iteration_count
      run_super(:run)
    end
  end


  #
  # Dynamically updates the request parameter hash with the 
  # current iteration parameter value.
  #
  #
  # Returns nothing.
  #

  def update_request_params!
    offset = @iteration_set.at(@iteration_count) || default_offset
    @request_arguments[:params] ||= {}
    @request_arguments[:params][@iteration_param.to_sym] = offset
  end


  #
  # Ads the current iteration offset to a url as a GET parameter.
  #
  # url - the url to be update
  #
  # Returns a url with the current iteration value represented as a get parameter.
  #
  def add_iteration_param(url)
    offset = @iteration_set.at(@iteration_count) || default_offset
    param = "#{@iteration_param}=#{offset}"
    parsed_url = URI::parse(url)

    if parsed_url.query
      parsed_url.query += param
    else
      parsed_url.query =  param
    end
    parsed_url.to_s
  end

  #
  # Utility function for calling a superclass instance method.
  #
  # (currently used to call ScraperBase#run).
  #

  def run_super(method, args=[])
    self.class.superclass.instance_method(method).bind(self).call(*args)
  end


  def issue_request(url)
    super(url)
    # clear previous value of iteration parameter
    @request_arguments[:params].delete(@iteration_param.to_sym) if @request_arguments[:params] && @request_arguments[:params].any?
  end


  # 
  # Overrides ScraperBase#handle_response in order to apply the proc used to dynamically extract the iteration set.
  # The proc called only once, only if it has been provided.
  #
  # returns nothing.
  #

  def handle_response(response)
    format = run_super(:detect_format, response.headers_hash['Content-Type']) 
    extractor_class = format == :json ? JsonExtractor : DomExtractor
    @iteration_extractor =  extractor_class.new(*@iteration_extractor_args)  if @iteration_extractor_args
    @iteration_set = Array(default_offset) + extract_iteration_set(response) if @response_count == 0 && @iteration_extractor
    super(response)
  end


  # 
  # Runs the extractor provided in order to dynamically fetch the array of values needed for the iterative scrape.
  #
  # Returns the iteration set as an array of strings.
  #
  #

  def extract_iteration_set(response)
    @iteration_extractor.extract_list(response.body).map(&:to_s)
  end
end
