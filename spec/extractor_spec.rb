require 'helpers/spec_helper'
require 'pry'

html = <<-EOF
  <div class="entry">
    <p><a href="http://example.com">my dummy link</a></p>
  </div>
  <div class="entry exclude" />
  <div class="entry" />
EOF

json = <<-EOF
{"widget": {
    "debug": "on",
    "window": {
        "title": "Sample Konfabulator Widget",
        "height": 500
    },
    "image": { 
        "src": "Images/Sun.png",
        "name": "sun1",
    },
    "text": {
        "data": "Click Here",
        "name": "text1",
    }
}}
EOF


describe Extractor do

  describe "#new" do
    subject { Extractor.new(:my_field, "p a", :href) }
     it { subject.field_name.should eql(:my_field) }
  end

  context "when no attribute is provided" do
    before do
      input = html
      @extractor = Extractor.new(:anchor, "p a")
      @node = Nokogiri::HTML(input)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("my dummy link") }
    end
  end


  context "when an attribute is provided" do
    before do
      input = html
      @extractor = Extractor.new(:anchor, "p a", :href)
      @node = Nokogiri::HTML(input)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("http://example.com") }
    end
  end

  context "when a selector and a block is provided" do
    before do
      input = html
      @extractor = Extractor.new(:anchor, "p a", proc { |node|
        node.text.gsub("dummy", "fancy")
      })
      @node = Nokogiri::HTML(input)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should match(/my fancy/) }
    end
  end

  context "when only a block is provided" do
    before do
      input = html
      @extractor = Extractor.new(:anchor, proc { |document|
        document.at_css("p a").text.gsub(/dummy/,'fancy')
      })
      @node = Nokogiri::HTML(input)
    end

    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should match(/my fancy/) }
    end
  end

  context "when only an attribute is provided" do
    before do
      input = html
      @extractor = Extractor.new(:url, :href)
      @node = Nokogiri::HTML('<a href="hello-world">Hello</a>').at_css("a")
    end
    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("hello-world") }
    end
  end

  context "when nothing but a field name is provided" do
    before do
      input = html
      @extractor = Extractor.new(:url)
      @node = Nokogiri::HTML('<a href="hello-world">Hello</a>').at_css("a")
    end
    describe "#extract_field" do
      subject { @extractor.extract_field(@node) }
      it { should eql("Hello") }
    end
  end

  describe "extract_list" do
    context "no block provided" do
      before do
        input = html
        @extractor = Extractor.new(nil, "div.entry")
        @node = Nokogiri::HTML(input)
      end

      subject { @extractor.extract_list(@node) }
      it { subject.should have(3).items }
    end

    context "block provided" do
      before do
        input = html
        @extractor = Extractor.new(nil, "div.entry", lambda { |nodeList|
          nodeList.reject {|node| node.attr(:class).split(" ").include?('exclude')  }
        })
        @node = Nokogiri::HTML(input)
      end

      subject { @extractor.extract_list(@node) }
      it { subject.should have(2).items }
    end
  end
end
