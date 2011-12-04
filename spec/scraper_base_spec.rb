require 'helpers/spec_helper'

describe ScraperBase do

  before(:each) do
    @scraper = ScraperBase.new("http://example.com")
  end

  describe "#loop_on" do
    subject { @scraper.loop_on("bla.bla") }
    it { should eql(@scraper) }
  end

  describe "#extract" do
    subject { @scraper.extract("fieldname", "bla.bla") }
    it { should eql(@scraper) }
  end

end
