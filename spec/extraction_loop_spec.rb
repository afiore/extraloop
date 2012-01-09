require 'helpers/spec_helper'

describe ExtractionLoop do

  before(:each) do
    @fake_scraper = stub!.options
    stub(@fake_scraper).results
  end

  describe "#new" do
    before do
      @mock_loop = Object.new
      stub(@mock_loop).parse {}

    end

    subject { ExtractionLoop.new(@mock_loop ) }

    it "should allow read/write access to public attributes" do

      {:extractors => [:fake, :fake],
       :document => nil,
       :hooks => { }
      }.each do |k, v|
        subject.send("#{k}=", v)
        subject.send(k).should eql(v)
      end
    end
  end

  describe "run" do
    before(:each) do

      @fake_scraper = Object.new
      stub(@fake_scraper).options {{}}
      stub(@fake_scraper).results { }

      @extractors = [:a, :b].map do |field_name|
        object = Object.new
        stub(object).extract_field { |node, record| node[field_name] }
        stub(object).field_name { field_name }
        object
      end
     
      @loop_extractor = Object.new

      stub(@loop_extractor).parse { |input| Nokogiri::HTML("<html><body>Hello test!</body></html>") }

      stub(@loop_extractor).extract_list { |document|
        #list of fake dom elements
        (0..9).to_a.map { |n| {:a => n, :b => n*n } }
      }


      before, before_extract, after_extract, after = *(1..4).to_a.map { proc {} }
      hooks = {before: [before], before_extract: [before_extract], after_extract: [after_extract], after: [after]}

      any_instance_of(ExtractionEnvironment) do |env|
        mock(env).run.with_any_args.times(20 + 2)
      end


      @extraction_loop = ExtractionLoop.new(@loop_extractor, @extractors, "fake document", hooks, @fake_scraper).run
    end

    subject { @extraction_loop.run }

    it "should produce 10 records" do
      @extraction_loop.records.size.should eql(10)
    end

    it "should run extractors" do
      @extraction_loop.records.all? { |record| record.a && record.b && record.b == record.a ** 2 }
    end

    it "should convert extracted records into OpenStruct instances" do
      @extraction_loop.records.all? { |record| record.is_a?(OpenStruct) }
    end

  end
end
