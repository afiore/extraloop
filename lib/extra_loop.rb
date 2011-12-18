# Standard library
autoload :OpenStruct, "ostruct"

# Rubygems

gem "nokogiri"
gem "typhoeus"
gem "logging"


autoload :Nokogiri, "nokogiri"
autoload :Typhoeus, "typhoeus"

# Extraloop components

autoload :Utils,          "extra_loop/utils"
autoload :Extractor,      "extra_loop/extractor"
autoload :ExtractionLoop, "extra_loop/extraction_loop"
autoload :ScraperBase,    "extra_loop/scraper_base"
autoload :Loggable,       "extra_loop/loggable"

#monkey patch scraperbase with the Loggable module
ScraperBase
Loggable



class ExtraLoop
  VERSION = '0.0.1'
end
