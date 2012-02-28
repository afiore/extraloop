module ExtraLoop
  class ScraperBase
    include Hookable
    include Utils::Support

    attr_reader :results, :options

    #
    # Public: Initalizes a web scraper.
    #
    # urls      - One or several urls.
    # options   - Hash of scraper options
    #   async        : Whether the scraper should issue HTTP requests in series or in parallel (set to false to suppress logging completely).
    #   log          : logging options (defaults to standard error).
    #     appenders    : specifies where the log messages should be appended to (defaults to standard error).
    #     log_level    : specifies the log level (defaults to info).
    # arguments - Hash of arguments to be passed to the Typhoeus HTTP client (optional).
    #
    #
    #
    # Returns itself.
    #

    def initialize(urls, options = {}, arguments = {})
      @urls = Array(urls)
      @loop_extractor_args = nil
      @extractor_args = []
      @loop = nil

      @request_arguments = arguments

      @options = {
        :async  => false
      }.merge(options)


      @response_count = 0
      @queued_count = 0

      @hooks = {}
      @failed_requests = []

      hydra_options = @options[:hydra] && @options[:hydra][:max_concurrency] || {:max_concurrency => 10}
      @hydra = Typhoeus::Hydra.new hydra_options
      self
    end


    # Public: Sets the scraper extraction loop.
    #
    # Delegates to Extractor, will raise an exception if neither a selector, a block, or an attribute name is provided.
    #
    #
    # selector  - The CSS3 selector identifying the node list over which iterate (optional).
    # attribute - An attribute name (optional).
    #
    # callback  - A block of code (optional).
    #
    # Returns itself.
    #

    def loop_on(*args, &block)
      args << block if block
      # we prepend a nil value, as the loop extractor does not need to specify a field name
      @loop_extractor_args = args.insert(0, nil)
      self
    end

    # Public: Registers a new extractor to be added to the loop.
    #
    # Delegates to Extractor, will raise an exception if neither a selector, a block, or an attribute name is provided.
    #
    # selector  - The CSS3 selector identifying the node list over which iterate (optional).
    # callback  - A block of code (optional).
    # attribute - An attribute name (optional).
    #
    # Returns itself.
    #
    #

    def extract(*args, &block)
      args << block if block
      @extractor_args << args
      self
    end

    #
    # Public: Runs the main scraping loop.
    #
    # Returns nothing
    #
    def run
      @urls.each do |url|
        issue_request(url)

        # if the scraper is asynchronous start processing the Hydra HTTP queue 
        # only after that the last url has been appended to the queue (see #issue_request).
        #
        if @options[:async]
          if url == @urls.last
            @hydra.run
          end
        else
          @hydra.run
        end
      end
      self
    end

    protected

    def issue_request(url)

      @request_arguments[:params] = merge_request_parameters(url)
      url_without_params = url.gsub(/\?.*/,"")

      arguments = {
        'headers' => [
          'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0a2) Gecko/20110613 Firefox/6.0a2',
          'accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
        ].join("\n")
      }

      arguments.merge!(@request_arguments)
      request = Typhoeus::Request.new(*[url_without_params, arguments])

      request.on_complete do |response|
        handle_response(response)
      end

      log("queueing url: #{url}, params #{arguments[:params]}", :debug)
      @queued_count += 1
      @hydra.queue(request)
    end

    def merge_request_parameters(url)
      url_params = URI::parse(url).extend(Utils::URIAddition).query_hash
      return @request_arguments[:params] || {} unless url_params && url_params.respond_to?(:merge)

      params = symbolize_keys(@request_arguments[:params] ||= {})
      url_params.merge(params)
    end

    def handle_response(response)
      @response_count += 1
      @loop = prepare_loop(response)
      log("response ##{@response_count} of #{@queued_count}, status code: [#{response.code}], URL fragment: ...#{response.effective_url.split('/').last if response.effective_url}")

      @loop.run
      @environment = @loop.environment
      run_hook(:data, [@loop.records, response])
      #TODO: add hock for scraper completion (useful in iterative scrapes).
    end

    def prepare_loop(response)
      content_type = response.headers_hash.fetch('Content-Type', nil)
      format = @options[:format] || detect_format(content_type)

      extractor_classname = "#{format.to_s.capitalize}Extractor"
      extractor_class = ExtraLoop.const_defined?(extractor_classname) && ExtraLoop.const_get(extractor_classname) || DomExtractor

      @loop_extractor_args.insert(1, ExtractionEnvironment.new(self))
      loop_extractor = extractor_class.new(*@loop_extractor_args)

      # There is no point in parsing response.body more than once, so we reuse
      # the first parsed document

      document = loop_extractor.parse(response.body)

      extractors = @extractor_args.map do |args|
        args.insert(1, ExtractionEnvironment.new(self, document))
        extractor_class.new(*args)
      end

      ExtractionLoop.new(loop_extractor, extractors, document, @hooks, self)
    end

    def detect_format(content_type)
      #TODO: add support for xml/rdf documents
      if content_type && content_type =~ /json$/
        :json
      elsif content_type && content_type =~ /(csv)|(comma-separated-values)$/
        :csv
      else
        :html
      end
    end

  end

end
