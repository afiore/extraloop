# Abstract class.
# This should not be called directly
#
#
class ExtractorBase
  module Exceptions
    class WrongArgumentError < StandardError; end
    class ExtractorParseError < StandardError; end
  end

  attr_reader :field_name
  #
  # Public: Initializes a Data extractor.
  #
  # Parameters:
  #   field_name  - The machine readable field name
  #   environment - The object within which the extractor callback will be run (using run).
  #   selector:   - The css3 selector to be used to match a specific portion of a document (optional).
  #   callback    - A block of code to which the extracted node/attribute will be passed (optional).
  #   attribute:  - A node attribute. If provided, the attribute value will be returned (optional).
  #
  # Returns itself
  #

  def initialize(field_name, environment, *args)
    @field_name = field_name
    @environment = environment

    @selector = args.find { |arg| arg.is_a?(String)}
    args.delete(@selector) if @selector
    @attribute = args.find { |arg| arg.is_a?(String) || arg.is_a?(Symbol) }
    @callback = args.find { |arg| arg.respond_to?(:call) }
    self
  end


  def parse(input)
    raise Exceptions::ExtractorParseError.new "input parameter must be a string" unless input.is_a?(String)
  end
end
