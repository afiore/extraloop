require 'helpers/spec_helper'

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
    it { should eql(@scraper) }
  end

  describe "#extract" do
    subject { @scraper.extract("fieldname", "bla.bla") }
    it { should eql(@scraper) }
  end

  describe "#set_hook" do
    subject { @scraper.set_hook(:after, proc {}) }
    it { should eql(@scraper)}
  end

  describe "#set_hook" do
    it "should raise exception if no proc is provided" do
      expect { @scraper.set_hook(:after, :method) }.to raise_exception(ScraperBase::Exceptions::HookArgumentError)
    end
  end

  context "single url, no options provided (async => false)" do
    describe "#run" do
      before do
        @url = "http://localhost/fixture"
        @results = []

        @hydra = Typhoeus::Hydra.new
        stub(Typhoeus::Hydra).new { @hydra }

        @response = Typhoeus::Response.new(:code => 200, :headers => "", :body => @fixture_doc)

        stub.proxy(Typhoeus::Request).new(@url, anything) do |request|
          @hydra.stub(:get, @url).and_return(@response)
          request
        end

        @scraper = ScraperBase.new(@url).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:on_data, proc { |records| @results=records })
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
        @results = []

        @hydra = Typhoeus::Hydra.new

        #as this is a synchronous scraper, Hydra run should be called thrice
        stub.proxy(@hydra).run.times(3)
        stub(Typhoeus::Hydra).new { @hydra }

        @response = Typhoeus::Response.new(:code => 200, :headers => "", :body => @fixture_doc)

        stub.proxy(Typhoeus::Request).new(anything, anything) do |request|
          @hydra.stub(:get, @url).and_return(@response)
          request
        end

        @scraper = ScraperBase.new(@urls, :log => false).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:on_data, proc { |records| records.each { |record| @results << record } })


        @fake_loop = Object.new
        stub(@fake_loop).run { }
        stub(@fake_loop).records { Array(1..3).map { |n| Object.new } }

        mock(ExtractionLoop).new(is_a(Extractor), is_a(Array), is_a(String), is_a(Hash)).times(3) { @fake_loop  }
      end


      it "Should handle response" do
        @scraper.run
        @results.size.should eql(9)
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
        @results = []

        @hydra = Typhoeus::Hydra.new

        #as this is an asynchronous scraper, Hydra run should be called only once
        stub.proxy(@hydra).run.times(1)
        stub(Typhoeus::Hydra).new { @hydra }

        @response = Typhoeus::Response.new(:code => 200, :headers => "", :body => @fixture_doc)

        stub.proxy(Typhoeus::Request).new(anything, anything) do |request|
          @hydra.stub(:get, @url).and_return(@response)
          request
        end

        @scraper = ScraperBase.new(@urls, :async => true).
          loop_on("ul li.file a").
            extract(:url, :href).
            extract(:filename).
          set_hook(:on_data, proc { |records| records.each { |record| @results << record } })


        @fake_loop = Object.new
        stub(@fake_loop).run { }
        stub(@fake_loop).records { Array(1..3).map { |n| Object.new } }

        mock(ExtractionLoop).new(is_a(Extractor), is_a(Array), is_a(String), is_a(Hash)).times(5) { @fake_loop  }
      end


      it "Should handle response" do
        @scraper.run
        @results.size.should eql(@urls.size * 3)
      end
    end
  end

end
