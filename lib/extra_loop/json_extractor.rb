class JsonExtractor < ExtractorBase

  def extract_field(node, record=nil)
    output = node = node.is_a?(String) ? parse(node) : node
    output = node[@attribute.to_s] if @attribute
    output = @callback.call(output, record) if @callback

    if !@attribute && !@callback  
     output = node[@field_name.to_s] if node[@field_name.to_s]
    end
    output
  end

  def extract_list(input)
    #TODO: implement more clever stuff here after looking 
    # into possible hash traversal techniques

    input = input.is_a?(String) ? parse(input) : input
    @callback && Array(@callback.call(input)) || input
  end

  def parse(input)
    super(input)
    (Yajl::Parser.new).parse(input)
  end
end
