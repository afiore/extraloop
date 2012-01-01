require 'rr'
require 'pry'

base_path = File.expand_path(File.dirname(File.dirname(File.dirname(__FILE__))))

load base_path + "/lib/extraloop.rb"

require 'helpers/scraper_helper'

RSpec.configure do |config|
  config.mock_with :rr
end
