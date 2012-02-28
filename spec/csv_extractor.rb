require 'helpers/spec_helper'

describe JsonExtractor do
  before(:each) do
    stub(scraper = Object.new).options
    stub(scraper).results
    @env = ExtractionEnvironment.new(scraper)

    File.open('fixtures/doc.csv', 'r') { |file|
      @csv = file.read
      @parsed_csv = CSV.parse(@csv)
      file.close
    }

  end

  describe "#extract_field" do
    context "with only a field name defined" do
      before  do 
        @extractor = CsvExtractor.new(:customer_company_name, @env)
        @extractor.parse(@csv)
      end

      subject { @extractor.extract_field @parsed_csv[2] }
      it { should eql("Utility A") }
    end

    context "with a field name and a selector defined" do
      before  do 
        @extractor = CsvExtractor.new(:name, @env, "customer_company_name")
        @extractor.parse(@csv)
      end
      subject { @extractor.extract_field @parsed_csv[2] }
      it { should eql("Utility A") }
    end

    context "with a field name, using a numerical index as selector", :onlythis => true do
      before  do 
        @extractor = CsvExtractor.new(:company_name, @env, 2)
        @extractor.parse(@csv)
      end
      subject { @extractor.extract_field @parsed_csv[2] }
      it { should eql("Utility A") }
    end

    context "Without any other arguments but a callback" do
      before do 
        @extractor = CsvExtractor.new nil, @env, proc { |row| row[2] }
        @extractor.parse(@csv)
      end
      subject { @extractor.extract_field @parsed_csv[2] }
      it { should eql("Utility A") }
    end
  end

  describe "#extract_list" do
    context "with no arguments" do
      subject { CsvExtractor.new(nil, @env).extract_list(@csv) }
      it { should eql(@parsed_csv) }
    end

    context "with a callback" do
      subject { CsvExtractor.new(nil, @env, proc { |rows| rows[0..10] }).extract_list(@csv) }
      it { should eql(@parsed_csv[0..10]) }
    end
  end
end
