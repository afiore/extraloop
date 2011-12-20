class Extractor
  module Exceptions
    class WrongArgumentError < StandardError
    end
  end

  include Utils::Support

  attr_reader :field_name

  #
  # Public: Initializes a Data extractor.
  #
  # Parameters:
  #   field_name  - The machine readable field name
  #   selector:   - The css3/JSON selector to be used to match a specific portion of a document (optional).
  #   callback    - A block of code to which the extracted node/attribute will be passed (optional).
  #   attribute:  - A node attribute. If provided, the attribute value will be returned (optional).
  #
  # Returns itself
  #

  def initialize(field_name, *args)
    @field_name = field_name
    @selector = args.find { |arg| arg.is_a?(String)}
    args.delete(@selector) if @selector
    @attribute = args.find { |arg| arg.is_a?(String) || arg.is_a?(Symbol) }
    @callback = args.find { |arg| arg.respond_to?(:call) }
    self
  end

  # Public: Runs the extractor against a document fragment (dom node or object).
  #
  # node   - The document fragment
  # record - The extracted record
  #
  # Returns the text content of the element, or the output of the extractor's callback.
  #

  def extract_field(node, record=nil)
    target = node
    target = node.at_css(@selector)  if @selector
    target = target.attr(@attribute) if target.respond_to?(:attr) && @attribute
    target = @callback.call(target, record) if @callback
    #if target is still a DOM node, return its text content
    target = target.text if target.respond_to?(:text)
    target
  end

  #
  # Public: Extracts a list of document fragments matching the provided selector/callback
  #
  # input - a document (either as a string or as a parsed Nokogiri document)
  #
  # Returns an array of elements matching the specified selector or function
  #
  #

  def extract_list(input)
    nodes = parse(input)
    nodes = nodes.css(@selector) if @selector
    @callback && @callback.call(nodes) || nodes
  end

  private
  def parse(input)
    if input.is_a?(String) then Nokogiri::HTML(input) else input end
  end
end
