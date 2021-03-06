require 'helpers/spec_helper'

describe DomExtractor do
  before(:each) do
    stub(scraper = Object.new).options
    stub(scraper).results
    @env = ExtractionEnvironment.new(scraper)
    @html ||= <<-EOF
  <div class="entry">
    <p><a href="http://example.com">my dummy link</a></p>
  </div>
  <div class="entry exclude" />
  <div class="entry" />
    EOF

    @xml ||= <<-EOF
    <?xml version="1.0"?>
    <StandardDataObject xmlns="myns">
      <InteractionElements>
        <TargetCenter>92f4-MPA</TargetCenter>
        <Trace>7.19879</Trace>
      </InteractionElements>
    </StandardDataObject>
    EOF
  end

  describe "#new" do
    subject { DomExtractor.new(:my_field, @env,  "p a", :href) }
     it { subject.field_name.should eql(:my_field) }
  end

  context "when no attribute is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, @env, "p a")
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("my dummy link") }
    end
  end


  context "when an attribute is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, @env, "p a", :href)
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("http://example.com") }
    end
  end

  context "when a selector and a block is provided", :bla => true do
    before do
      document_defined = scraper_defined = false

      @extractor = DomExtractor.new(:anchor, @env, "p a", proc { |node|
        document_defined = @document && @document.is_a?(Nokogiri::HTML::Document)
        scraper_defined = instance_variable_defined? "@scraper"
        node.text.gsub("dummy", "fancy")
      })

      @node = @extractor.parse(@html)
      @output = @extractor.extract_field(@node)

      @scraper_defined = scraper_defined
      @document_defined = document_defined
    end

    describe "#extract_field" do
      it "should return the block output" do
        @output.should match(/my\sfancy/)
      end
      it "should add the @scraper and @document instance variables to the extraction environment" do
        @scraper_defined.should be_true
        @document_defined.should be_true
      end
    end
  end

  context "when only a block is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, @env, proc { |document|
        document.at_css("p a").text.gsub(/dummy/,'fancy')
      })
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should match(/my fancy/) }
    end
  end

  context "when only an attribute is provided" do
    before do
      @extractor = DomExtractor.new(:url, @env, :href)
      @node = @extractor.parse('<a href="hello-world">Hello</a>').at_css("a")
    end
    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("hello-world") }
    end
  end


  context "when nothing but a field name is provided" do
    before do
      @extractor = DomExtractor.new(:url, @env)
      @node = @extractor.parse('<a href="hello-world">Hello</a>').at_css("a")
    end
    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("Hello") }
    end
  end

  describe "extract_list" do
    context "no block provided" do
      before do
        @extractor = DomExtractor.new(nil, @env, "div.entry")
        @node = @extractor.parse(@html)
      end

      subject { @extractor.extract_list(@node) }
      it { subject.should have(3).items }
    end

    context "block provided" do
      before do
        document_defined = scraper_defined = false

        @extractor = DomExtractor.new(nil, @env, "div.entry", proc { |nodeList|
          document_defined = @document && @document.is_a?(Nokogiri::HTML::Document)
          scraper_defined = instance_variable_defined? "@scraper"

          nodeList.reject {|node| node.attr(:class).split(" ").include?('exclude')  }
        })

        @output = @extractor.extract_list(@html)
        @scraper_defined = scraper_defined
        @document_defined = document_defined
      end

      it { @output.should have(2).items }
      it "should add @scraper and @document instance variables to the ExtractionEnvironment instance" do
        @scraper_defined.should be_true
        @document_defined.should be_true
      end
    end
  end

  context "xml input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, @env, "entry")
      end

      subject { @extractor.parse(@xml) }
      it { should be_an_instance_of(Nokogiri::XML::Document)}
    end
  end


  context "html input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, @env, "entry")
      end

      subject { @extractor.parse(@html) }
      it { should be_an_instance_of(Nokogiri::HTML::Document)}
    end
  end

  context "non-string input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, @env, "entry")
      end

      it "Should raise an exception" do
        expect { @extractor.parse(Nokogiri::HTML(@html)) }.to raise_exception(ExtractorBase::Exceptions::ExtractorParseError)
      end

    end
  end
end
