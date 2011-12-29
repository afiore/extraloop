require 'helpers/spec_helper'
include Helpers::Scrapers

describe ScraperBase do
  before do
    @fixture_doc = File.open("fixtures/doc.html", 'r') do |file|
      file.read
    end
  end

  before(:each) do
    @scraper = ScraperBase.new("http://localhost/fixture")
  end


  describe "#loop_on" do
    subject { @scraper.loop_on("bla.bla") }
    it { should be_an_instance_of(ScraperBase) }
  end

  describe "#extract" do
    subject { @scraper.extract("fieldname", "bla.bla") }
    it { should be_an_instance_of(ScraperBase) }
  end

  describe "#set_hook" do
    subject { @scraper.set_hook(:after, proc {}) }
    it { should be_an_instance_of(ScraperBase)  }
  end

  describe "#set_hook" do
    it "should raise exception if no proc is provided" do
      expect { @scraper.set_hook(:after, :method) }.to raise_exception(ScraperBase::Exceptions::HookArgumentError)
    end
  end

  context "request params in both the url and the arguments hash" do
    describe "#run" do
      before do

        @request_args = {}
        url = "http://localhost/whatever?q=stuff&p=1&limit=100"
        stub_http do |hydra, request, response|
          @request_args = request.params
          hydra.stub(:get, request.url).and_return(response)
        end

        any_instance_of(ExtractionLoop) do |extraloop|
          stub(extraloop).run {}
        end

        @scraper = ScraperBase.new(url, {}, {
          :params => { :limit => 250 }
        }).loop_on(".stuff").run
      end

      it "should merge URL and request parameters" do
        @request_args[:p].to_s.should eql("1")
        @request_args[:q].to_s.should eql("stuff")
        @request_args[:limit].to_s.should eql("250")
      end 
    end
  end

  context "single url, no options provided (async => false)" do
    describe "#run" do
      before do
        @url = "http://localhost/fixture"
        results = []

        stub_http({}, :body => @fixture_doc) do |hydra, request, response|
          hydra.stub(:get, request.url).and_return(response)
        end

        @scraper = ScraperBase.new(@url).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:data, proc { |records| records.each { |record| results << record }})

        @results = results
      end


      it "Should handle response" do
        @scraper.run
        @results.should_not be_empty
        @results.all? { |record| record.extracted_at && record.url && record.filename }.should be_true
      end
    end
  end

  context "multiple urls (async => false)" do
    describe "#run" do
      before do
        @urls = [
          "http://localhost/fixture1",
          "http://localhost/fixture2",
          "http://localhost/fixture3",
        ]
        results = []
        @hydra_run_call_count = 0

        stub_http do |hydra, request, response|
          @urls.each { |url| hydra.stub(:get, url).and_return(response) }
          stub.proxy(hydra).run { @hydra_run_call_count += 1  }
        end

        @scraper = ScraperBase.new(@urls, :log => false).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:data, proc { |records| records.each { |record| results << record } })

        @results = results

        @fake_loop = Object.new
        stub(@fake_loop).run { }
        stub(@fake_loop).environment { ExtractionEnvironment.new }
        stub(@fake_loop).records { Array(1..3).map { |n| Object.new } }

        mock(ExtractionLoop).new(is_a(DomExtractor), is_a(Array), is_a(String), is_a(Hash), is_a(ScraperBase)).times(3) { @fake_loop  }
      end


      it "Should handle response" do
        @scraper.run
        @results.size.should eql(9)
        @hydra_run_call_count.should eql(@urls.size)
      end
    end
  end


  context "multiple urls (async => true)" do
    describe "#run" do
      before do
        @urls = [
          "http://localhost/fixture1",
          "http://localhost/fixture2",
          "http://localhost/fixture3",
          "http://localhost/fixture4",
          "http://localhost/fixture5",
        ]
        results = []
        @hydra_run_call_count = 0

        stub_http({}, :body => @fixture_doc) do |hydra, request, response|
          @urls.each { |url| hydra.stub(:get, url).and_return(response) }
          stub.proxy(hydra).run { @hydra_run_call_count+=1 }
        end

        @scraper = ScraperBase.new(@urls, :async => true).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:data, proc { |records| records.each { |record| results << record } })

        @results = results

        @fake_loop = Object.new
        stub(@fake_loop).run { }
        stub(@fake_loop).environment { ExtractionEnvironment.new }
        stub(@fake_loop).records { Array(1..3).map { |n| Object.new } }

        mock(ExtractionLoop).new(is_a(DomExtractor), is_a(Array), is_a(String), is_a(Hash), is_a(ScraperBase)).times(@urls.size) { @fake_loop  }
      end


      it "Should handle response" do
        @scraper.run
        @results.size.should eql(@urls.size * 3)
        @hydra_run_call_count.should eql(1)
      end
    end
  end

end
