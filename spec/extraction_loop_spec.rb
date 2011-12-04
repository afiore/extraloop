require 'helpers/spec_helper'
require 'pry'

describe ExtractionLoop do
  describe "#new" do
    subject { ExtractionLoop.new(Object.new) }
    it "should allow read/write access to public attributes" do
      {:extractors => [:fake, :fake],
       :document => nil,
       :hooks => {:whaterver => true}

      }.each do |k, v|
        subject.send("#{k}=", v)
        subject.send(k).should eql(v)
      end
    end
  end

  describe "run" do

    before(:each) do
      @extractors = [:a, :b].map do |field_name|
        object = Object.new
        stub(object).extract_field { |node, record| node[field_name] }
        stub(object).field_name { field_name }
        object
      end

      stub(@loop_extractor = Object.new).extract_list { |document|
        #list of fake dom elements
        (0..9).to_a.map { |n| {:a => n, :b => n*n } }
      }


      before, before_extract, after_extract, after = *(1..4).to_a.map { Object.new }

      mock(before).call(is_a(Nokogiri::HTML::Document)) { }
      mock(after).call(is_a(Array)) {}
      mock(before_extract).call(is_a(Object)).times(10) {}
      mock(after_extract).call(is_a(Object), is_a(OpenStruct)).times(10) {}

      @hooks = {
        :before => before,
        :before_extract => before_extract,
        :after_extract => after_extract,
        :after => after
      }

      @extraction_loop = ExtractionLoop.new(@loop_extractor, @extractors, "fake document", @hooks).run
    end

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
