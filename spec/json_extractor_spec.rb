require 'helpers/spec_helper'

describe JsonExtractor do
  before(:each) do
    @json ||= lambda {
      file = File.open('fixtures/doc.json', 'r')
      content = file.read
      file.close
      content
    }.call()
  end

  describe "#initialize" do
    subject { JsonExtractor.new(:thing, proc  {}) }

    it { subject.field_name.should eql(:thing) }
    it { should_not respond_to(:callback) }
  end


  describe "#extract_field" do

    context "field_name and callback" do
      before do
        @extractor = JsonExtractor.new(:from_user)
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("ludovickohn") }
    end

    context "field_name and callback" do
      before do
        @extractor = JsonExtractor.new(:from_user, proc { |node| node['from_user_name'] } )
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("Ludovic kohn") }
    end

    context "field_name and attribute" do
      before do
        @extractor = JsonExtractor.new(:from_user, :from_user_name )
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("Ludovic kohn") }
    end

    context "field name, attribute, and callback " do
      before do
        @extractor = JsonExtractor.new(:from_user, :from_user_name, proc { |username| username.downcase.gsub("\s","-")  } )
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("ludovic-kohn") }
    end
  end

  describe "#extract_list" do
    context "with json string input" do
      before do
        @extractor = JsonExtractor.new(nil, proc { |data| data['results'] })
      end

      subject { @extractor.extract_list(@json) }
      it { subject.size.should eql(15) }
      it { should be_an_instance_of(Array) }
    end

    context "with pre-parsed input" do
      before do
        @extractor = JsonExtractor.new(nil, proc { |data| data['results'] })
      end

      subject { @extractor.extract_list((Yajl::Parser.new).parse(@json)) }
      it { subject.size.should eql(15) }
      it { should be_an_instance_of(Array) }
    end


  end

  context "non-string input" do
    describe "#parse" do
      before do 
        @extractor = JsonExtractor.new(nil, proc {})
      end

      it "Should raise an exception" do
        expect { @extractor.parse(Nokogiri::HTML(@html)) }.to raise_exception(ExtractorBase::Exceptions::ExtractorParseError)
      end
    end
  end

  context "#json input" do
    describe "#parse" do
      before do
        @extractor = JsonExtractor.new(nil, proc {})
      end

      subject { @extractor.parse(@json) }

      it { should be_an_instance_of(Hash) }
      it { should_not be_empty }
    end
  end
end