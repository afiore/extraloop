require 'helpers/spec_helper'
include Helpers::Scrapers

describe IterativeScraper do
  before(:each) do
    @fixture_doc ||= proc {
      file = File.open("fixtures/doc.html", "r")
      file_content = file.read
      file.close
      file_content
    }.call
  end

  describe "#initialize" do
    subject { IterativeScraper.new("http://whatever.net/search?q=:q") }

    it { subject.should be_a(ScraperBase) }
    it { subject.should respond_to(:log) }
  end

  describe "#set_iteration" do
    before do 
      @scraper = IterativeScraper.new("http://whatever.net/search?q=:q")
    end

    it "should allow passing a range and return itself" do
      @scraper.set_iteration((0..10).step(5)).should be_an_instance_of(IterativeScraper)
    end
    it "should allow passing an array and return itself" do
      @scraper.set_iteration([1, 2, 3, 4]).should be_an_instance_of(IterativeScraper)
    end
    it "should allow passing a string and a proc and return itself" do
      @scraper.set_iteration("#pagination a", proc {}).should be_an_instance_of(IterativeScraper)
    end
  end

  #context "(single url pattern, iteration_set is range , async => false )" do
  #  before(:each) do
  #    @scraper = IterativeScraper.new("http://whatever.net/search?p=:p")
  #    mock(@scraper).run_super(:run).times(10) {}
  #    @scraper.set_iteration(:p, (1..10))
  #  end

  #  describe "#run" do
  #    it "super#run should be called 10 times" do
  #      @scraper.run
  #    end
  #  end
  #end

  context "(single url pattern, iteration_set is extractor, async => false )" do
    before(:each) do

      @iteration_count = 0
      @params_sent = []
      iteration_proc = proc {[2, 3, 4]}

      any_instance_of(ExtractionLoop) do |eloop|
        stub(eloop).run {}
      end

      stub_http do |hydra, request, response|
        hydra.stub(:get, /http:\/\/whatever\.net\/search/).and_return(response)
        @params_sent << request.params[:p]
      end

      @scraper = IterativeScraper.
        new("http://whatever.net/search").
        set_iteration(:p, iteration_proc).
        set_hook(:on_data, proc { @iteration_count += 1 }).
        run()
    end

    describe "#run" do
      it "The :on_data hook should be called 4 times" do
        @iteration_count.should eql(4)
      end

      it "should have sent p=1, p=2, p=3, p=4 as request parameters" do
        @params_sent.should eql(["1", "2", "3", "4"])
      end
    end
  end

  context "" do
    describe "#run" do

    end
  end

end
