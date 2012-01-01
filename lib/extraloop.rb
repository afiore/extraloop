base_path = File.expand_path(File.dirname(__FILE__) + "/extraloop"  )

module ExtraLoop
  VERSION = '0.0.3'
end


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

ExtraLoop.autoload :Utils                 , "#{base_path}/utils"
ExtraLoop.autoload :ExtractionEnvironment , "#{base_path}/extraction_environment"
ExtraLoop.autoload :ExtractorBase         , "#{base_path}/extractor_base"
ExtraLoop.autoload :DomExtractor          , "#{base_path}/dom_extractor"
ExtraLoop.autoload :JsonExtractor         , "#{base_path}/json_extractor"
ExtraLoop.autoload :ExtractionLoop        , "#{base_path}/extraction_loop"
ExtraLoop.autoload :ScraperBase           , "#{base_path}/scraper_base"
ExtraLoop.autoload :Loggable              , "#{base_path}/loggable"
ExtraLoop.autoload :Hookable              , "#{base_path}/hookable"
ExtraLoop.autoload :IterativeScraper      , "#{base_path}/iterative_scraper"


# monkey patch scraperbase with the Loggable module.
#
# This is the equivalent adding extra_loop/ to the path and requiring both ScraperBase and Loggable 
#
ExtraLoop::ScraperBase
ExtraLoop::Loggable

