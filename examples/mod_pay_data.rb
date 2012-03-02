#
# Fetches name, job title, and actual pay ceiling from a CSV dataset listing UK Ministry of Defence's organogram and staff pay data
# source: http://data.gov.uk/dataset/staff-organograms-and-pay-mod
#

require "../lib/extraloop.rb"
require "pry"

class ModPayScraper < ExtraLoop::ScraperBase
  def initialize
    dataset_url = "http://www.mod.uk/NR/rdonlyres/FF9761D8-2AB9-4CD4-88BC-983A46A0CD90/0/20111208CTLBOrganogramFinal7Useniordata.csv"
    super dataset_url, :format => :csv

    # Select only records of officers earning more than 100k per year
    
    loop_on do |rows|
      rows[1..-1].select { |row| row[14].to_i > 100000 }
    end

    extract :name, "Name"
    extract :title, "Job Title"
    extract :pay, 14

    on("data") do |records| 
      records.
        sort { |r1, r2| r2.pay.to_i <=> r1.pay.to_i }.
        each { |record| puts [record.pay, record.name].map { |string| string.ljust 7 }.join }
    end
  end
end

ModPayScraper.new.run
