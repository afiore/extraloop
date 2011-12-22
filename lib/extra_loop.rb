# Standard library
autoload :OpenStruct, "ostruct"

# Rubygems

gem "nokogiri"
gem "typhoeus"
gem "logging"


autoload :Nokogiri, "nokogiri"
autoload :Typhoeus, "typhoeus"

# Extraloop components

autoload :Utils,            "extra_loop/utils"
autoload :ExtractorBase,    "extra_loop/extractor_base"
autoload :DomExtractor,     "extra_loop/dom_extractor"
autoload :JsonExtractor,    "extra_loop/json_extractor"
autoload :ExtractionLoop,   "extra_loop/extraction_loop"
autoload :ScraperBase,      "extra_loop/scraper_base"
autoload :Loggable,         "extra_loop/loggable"
autoload :IterativeScraper, "extra_loop/iterative_scraper"


# monkey patch scraperbase with the Loggable module.
#
# This is the equivalent adding extra_loop/ to the path and requiring both ScraperBase and Loggable 
#
ScraperBase
Loggable


class ExtraLoop
  VERSION = '0.0.1'
end
