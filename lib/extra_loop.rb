autoload :OpenStruct, "ostruct"

# Rubygem autoloads

gem "nokogiri"
gem "typhoeus"

autoload :Nokogiri, "nokogiri"
autoload :Typhoeus, "typhoeus"

# Extraloop components

autoload :Utils,          "extra_loop/utils"
autoload :Extractor,      "extra_loop/extractor"
autoload :ExtractionLoop, "extra_loop/extraction_loop"
autoload :ScraperBase,    "extra_loop/scraper_base"

class ExtraLoop
  VERSION = '0.0.1'
end
