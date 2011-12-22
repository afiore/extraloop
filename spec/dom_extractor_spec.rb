require 'helpers/spec_helper'

describe DomExtractor do
  before(:each) do
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
    subject { DomExtractor.new(:my_field, "p a", :href) }
     it { subject.field_name.should eql(:my_field) }
  end

  context "when no attribute is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, "p a")
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("my dummy link") }
    end
  end


  context "when an attribute is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, "p a", :href)
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("http://example.com") }
    end
  end

  context "when a selector and a block is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, "p a", proc { |node|
        node.text.gsub("dummy", "fancy")
      })
      @node = @extractor.parse(@html)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should match(/my fancy/) }
    end
  end

  context "when only a block is provided" do
    before do
      @extractor = DomExtractor.new(:anchor, proc { |document|
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
      @extractor = DomExtractor.new(:url, :href)
      @node = @extractor.parse('<a href="hello-world">Hello</a>').at_css("a")
    end
    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("hello-world") }
    end
  end

  context "when nothing but a field name is provided" do
    before do
      @extractor = DomExtractor.new(:url)
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
        @extractor = DomExtractor.new(nil, "div.entry")
        @node = @extractor.parse(@html)
      end

      subject { @extractor.extract_list(@node) }
      it { subject.should have(3).items }
    end

    context "block provided" do
      before do
        @extractor = DomExtractor.new(nil, "div.entry", lambda { |nodeList|
          nodeList.reject {|node| node.attr(:class).split(" ").include?('exclude')  }
        })
      end

      subject { @extractor.extract_list(@html) }
      it { subject.should have(2).items }
    end
  end

  context "xml input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, "entry")
      end

      subject { @extractor.parse(@xml) }
      it { should be_an_instance_of(Nokogiri::XML::Document)}
    end
  end


  context "html input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, "entry")
      end

      subject { @extractor.parse(@html) }
      it { should be_an_instance_of(Nokogiri::HTML::Document)}
    end
  end

  context "non-tring input" do
    describe "#parse" do
      before do 
        @extractor = DomExtractor.new(nil, "entry")
      end

      it "Should raise an exception" do
        expect { @extractor.parse(Nokogiri::HTML(@html)) }.to raise_exception(ExtractorBase::Exceptions::ExtractorParseError)
      end

    end
  end
end
