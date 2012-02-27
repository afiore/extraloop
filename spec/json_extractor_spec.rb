require 'helpers/spec_helper'

describe JsonExtractor do
  before(:each) do
    stub(scraper = Object.new).options
    stub(scraper).results
    @env = ExtractionEnvironment.new(scraper)
    @json ||= lambda {
      file = File.open('fixtures/doc.json', 'r')
      content = file.read
      file.close
      content
    }.call()
  end

  describe "#initialize" do
    context("argument is a block") do
      subject { JsonExtractor.new(:thing, @env, proc  {}) }

      it { subject.field_name.should eql(:thing) }
      it { should_not respond_to(:callback) }
    end
  end


  describe "#extract_field" do

    context "field_name and callback" do
      before do
        @extractor = JsonExtractor.new(:from_user, @env)
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("ludovickohn") }
    end

    context "field_name and callback" do
      before do
        scraper_defined = document_defined = false

        @extractor = JsonExtractor.new(:from_user, @env, proc { |node| 
          document_defined = @document && @document.is_a?(Hash)
          scraper_defined = instance_variable_defined? "@scraper"

          node['from_user_name']
        })

        @node = @extractor.parse(@json)['results'].first
        @output = @extractor.extract_field(@node)

        @scraper_defined = scraper_defined
        @document_defined = document_defined
      end

      it { @output.should eql("Ludovic kohn") }
      it "should add the @scraper and @document instance variables to the extraction environment" do
        @scraper_defined.should be_true
        @document_defined.should be_true
      end
    end

    context "field_name and attribute" do
      before do
        @extractor = JsonExtractor.new(:from_user, @env, :from_user_name )
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("Ludovic kohn") }
    end

    context "field name, attribute, and callback " do
      before do
        @extractor = JsonExtractor.new(:from_user, @env, :from_user_name, proc { |username| username.downcase.gsub("\s","-")  } )
        @node = @extractor.parse(@json)['results'].first
      end

      subject { @extractor.extract_field(@node) }
      it { should eql("ludovic-kohn") }
    end

    context("field name and array (see Utils::DeepFetchable)") do
      before do 
        @extractor = JsonExtractor.new(:from_user, @env, ['results', 0, 'from_user'])
      end
      subject {  @extractor.extract_field(@json) }
      it { should eql("ludovickohn") }
    end

    context("field name, array, and callback") do
      before do 
        @extractor = JsonExtractor.new(:from_user, @env, ['results', 0, 'from_user'], proc { |username|  username.gsub("ckohn",'co') })
      end
      subject {  @extractor.extract_field(@json) }
      it { should eql("ludovico") }
    end

  end

  describe "#extract_list" do


    context "using #get_in" do
      before do
        @extractor = JsonExtractor.new(nil, @env, ['results', 0..5])
      end

      subject { @extractor.extract_list(@json) }

      it { subject.size.should eql(6) }
    end

    context "with json string input" do
      before do
        @extractor = JsonExtractor.new(nil, @env, proc { |data| data['results'] })
      end

      subject { @extractor.extract_list(@json) }
      it { subject.size.should eql(15) }
      it { should be_an_instance_of(Array) }
    end

    context "with pre-parsed input" do
      before do
        document_defined = scraper_defined = false

        @extractor = JsonExtractor.new(nil, @env, proc { |data| 
          document_defined = @document && @document.is_a?(Hash)
          scraper_defined = instance_variable_defined? "@scraper"
          data['results'] 
        })


        @output = @extractor.extract_list((Yajl::Parser.new).parse(@json))
        @scraper_defined = scraper_defined
        @document_defined = document_defined
      end

      it { @output.size.should eql(15) }
      it { @output.should be_an_instance_of(Array) }

      it "should add the @scraper and @document instance variables to the extraction environment" do
        @scraper_defined.should be_true
        @document_defined.should be_true
      end
    end

  end

  context "non-string input" do
    describe "#parse" do
      before do 
        @extractor = JsonExtractor.new(nil, @env, proc {})
      end

      it "Should raise an exception" do
        expect { @extractor.parse(Nokogiri::HTML(@html)) }.to raise_exception(ExtractorBase::Exceptions::ExtractorParseError)
      end
    end
  end

  context "#json input" do
    describe "#parse" do
      before do
        @extractor = JsonExtractor.new(nil, @env, proc {})
      end

      subject { @extractor.parse(@json) }

      it { should respond_to(:get_in) }
      it { should be_an_instance_of(Hash) }
      it { should_not be_empty }
    end
  end
end
