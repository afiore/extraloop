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
    subject { IterativeScraper.new("http://whatever.net/search") }

    it { subject.should be_a(ScraperBase) }
    it { subject.should respond_to(:log) }
  end

  describe "#set_iteration" do
    before do 
      @scraper = IterativeScraper.new("http://whatever.net/search")
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

  describe "#continue_with" do
    before do 
      @scraper = IterativeScraper.new("http://whatever.net/search")
    end

    subject { @scraper.continue_with( proc { |result| result['continue'] }) }
    it { should be_an_instance_of(IterativeScraper) }
  end


  context "(single url pattern, iteration_set is range , async => false )" do
    before(:each) do
      @scraper = IterativeScraper.new("http://whatever.net/search")
      mock(@scraper).run_super(:run).times(10) {}
      @scraper.set_iteration(:p, (1..10))
    end

    describe "#run" do
      it "super#run should be called 10 times" do
        @scraper.run
      end
    end
  end

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
        new("http://whatever.net/search-stuff").
        set_iteration(:p, iteration_proc).
        loop_on(".whatever").
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

  context "(single url pattern, iteration_set is range, async => true )" do

    before do
      @params_sent = []
      any_instance_of(ExtractionLoop) do |eloop|
        stub(eloop).run {}
      end

      stub_http do |hydra, request, response|
        hydra.stub(:get, /http:\/\/whatever\.net\/search/).and_return(response)
        @params_sent << request.params[:p]
      end

      @scraper = IterativeScraper.
        new("http://whatever.net/search", :async => true).
        set_iteration(:p, (0..20).step(5)).
        loop_on(".whatever").
        run()
    end


    describe "#run" do
      it "params sent should be p=1, p=5, p=10, p=15, p=20" do
        @params_sent.should eql([0, 5, 10, 15, 20].map &:to_s)
      end
    end
  end

  context "using #continue_with" do
    
    describe "#run" do
      before do
        @continue_values = (5..10).to_a
        shift_values = proc { |data| @continue_values.shift }

        #TODO: fix this! times should be 5, not 6
        mock.proxy(shift_values).call(is_a(Hash), anything).times(@continue_values.size + 1)

        stub_http({}, {headers: "Content-Type: application/json", :body => '{"hello":"test"}' }) do |hydra, request, response|
          hydra.stub(:get, request.url).and_return(response)
        end

        @scraper = IterativeScraper.
          new("http://twizzer.net/timeline", :log => {
            :log_level => :debug,
            :appenders => [Logging.appenders.stderr]
          }).
          loop_on(proc {}).
          continue_with({:continue => ''}, shift_values)
      end

      #TODO: 
      #
      # When #continue_with is used, it would be better avoid sending
      # an empty iteration_parameter
      #
      it "Should run 5 times" do
        @scraper.run
      end

    end
  end

end
