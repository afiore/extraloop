require 'pry'
class JsonExtractor < ExtractorBase

  def initialize(*args)
    @path = args[1] && args[1].is_a?(Array) ? args[1] : nil
    super(*args)
  end

  def extract_field(node, record=nil)
    output = node = node.is_a?(String) ? parse(node) : node
    output = node.get_in(@path) if @path
    output = node[@attribute.to_s] if @attribute
    output = @callback.call(output, record) if @callback


    # when no attribute and no callback is provided, try fetching by field name
    if !@attribute && !@callback  
     output = node[@field_name.to_s] if node[@field_name.to_s]
    end
    output
  end

  def extract_list(input)
    #TODO: implement more clever stuff here after looking 
    # into possible hash traversal techniques

    input = input.is_a?(String) ? parse(input) : input
    input = input.get_in(@path) if @path

    @callback && Array(@callback.call(input)) || input
  end

  def parse(input)
    super(input)
    (Yajl::Parser.new).parse(input).extend(Utils::DeepFetchable)
  end
end
