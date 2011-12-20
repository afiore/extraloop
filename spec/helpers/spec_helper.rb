require 'rr'
require 'pry'
require '../lib/extra_loop.rb'

require 'helpers/scraper_helper'

RSpec.configure do |config|
  config.mock_with :rr
end
