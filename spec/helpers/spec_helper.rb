require 'rr'
require 'pry'
require '../lib/extra_loop.rb'

RSpec.configure do |config|
  config.mock_with :rr
end

