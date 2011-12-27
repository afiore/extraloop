base_path = File.expand_path(File.dirname(__FILE__) + "/extra_loop"  )

# Standard library
autoload :OpenStruct, "ostruct"

# Rubygems

gem "yajl-ruby"
gem "nokogiri"
gem "typhoeus"
gem "logging"


autoload :Nokogiri, "nokogiri"
autoload :Yajl,     "yajl"
autoload :Typhoeus, "typhoeus"


# Extraloop components

autoload :Utils                 , "#{base_path}/utils"
autoload :ExtractionEnvironment , "#{base_path}/extraction_environment"
autoload :ExtractorBase         , "#{base_path}/extractor_base"
autoload :DomExtractor          , "#{base_path}/dom_extractor"
autoload :JsonExtractor         , "#{base_path}/json_extractor"
autoload :ExtractionLoop        , "#{base_path}/extraction_loop"
autoload :ScraperBase           , "#{base_path}/scraper_base"
autoload :Loggable              , "#{base_path}/loggable"
autoload :Hookable             , "#{base_path}/hookable"
autoload :IterativeScraper      , "#{base_path}/iterative_scraper"


# monkey patch scraperbase with the Loggable module.
#
# This is the equivalent adding extra_loop/ to the path and requiring both ScraperBase and Loggable 
#
ScraperBase
Loggable


class ExtraLoop
  VERSION = '0.0.1'
end
