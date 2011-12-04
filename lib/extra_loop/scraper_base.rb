class ScraperBase
  module Exceptions
    class HookError < StandardError
    end
  end

  attr_reader :results

  def initialize(urls, arguments = {}, options = {})
    @urls = Array(urls)
    @loop_extractor = nil
    @loop = nil

    @extractors = []
    @request_arguments = arguments

    @options = OpenStruct.new
    @options.marshal_load({
      :async => false
    }.merge(options))

    @storage = nil
    @storage_collection = nil

    @response_count = 0
    @queued_count = 0

    @hooks = {}
    @failed_requests = []

    hydra_options = @options.hydra? && @option.hydra.marshal_dump || {:max_concurrency => 10}
    @hydra = Typhoeus::Hydra.new hydra_options
    self
  end

  #def set_storage(dataset, collection)
  #  @storage = dataset
  #  @storage_collection = collection
  #  self
  #end

  def set_hook(hookname, handler)
    raise Exceptions::HookError "handler must be a callable proc" unless handler.respond_to?(:call)
    @hooks[hookname.to_sym] = handler
    self
  end


  # Public: Sets the scraper extraction loop.
  #
  # Delegates to Extractor, will raise an exception if neither a selector, a block, or an attribute name is provided.
  #
  #
  # selector  - The CSS3 selector identifying the node list over which iterate (optional).
  # callback  - A block of code (optional).
  # attribute - An attribute name (optional).
  #
  # Returns itself.
  #

  def loop_on(*args)
    @loop_extractor = Extractor.new(*args.insert(0, nil))
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

  def extract(*args)
    @extractors << Extractor.new(*args)
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

      if @options.async
        if url == @urls.last
          puts "calling Hydra#run"
          @hydra.run
        end
      else
        puts "calling hydra#run"
        @hydra.run
      end
    end
  end

  protected

  def run_hook(hook, arguments)
    @hooks[hook].call(*arguments) if @hooks.has_key?(hook)
  end

  def handle_response(response)
    @response_count+=1
    puts "response ##{@response_count} of #{@queued_count}, status code: [#{response.code}], URL fragment: ...#{response.effective_url.split('/').last}"
    @loop = ExtractionLoop.new(@loop_extractor, @extractors, response.body, response.effective_url)
    @loop.run

    run_hook(:on_data, [@loop.records, response.effective_url, response])
    store_records(@loop.records) if @storage
  end

  def store_records(records)
    @storage.batch_set(@storage_collection, records.collect(&:marshal_dump))
  end

  def issue_request(url)
    arguments = {
      'headers' => {
        'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0a2) Gecko/20110613 Firefox/6.0a2',
        'accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
       }
    }
    arguments.merge!(@request_arguments)
    request = Typhoeus::Request.new(*[url, arguments])

    request.on_complete do |response|
      handle_response(response)
    end

    puts "==> queueing url: #{url}"
    @queued_count += 1
    @hydra.queue(request)
  end
end
