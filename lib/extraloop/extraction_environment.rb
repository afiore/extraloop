module ExtraLoop
  # This class acts as a virtual environment within 
  # which Hook handlers and extractors run (through #run)

  class ExtractionEnvironment
    attr_accessor :document
    attr_reader :scraper

    def initialize(scraper=nil, document=nil, records=nil)

      if scraper
        @options  = scraper.options
        @results  = scraper.results
        @scraper  = scraper
      end
      @document = document
      @records  = records
    end

    def run(*arguments, &block)
      self.instance_exec(*arguments, &block)
    end
  end
end
