module ExtraLoop
  class JsonExtractor < ExtractorBase

    def initialize(*args)
      @path = args[2] && args[2].is_a?(Array) ? args[2] : nil
      super(*args)
    end

    def extract_field(node, record=nil)
      output = node = node.is_a?(String) ? parse(node) : node
      output = node.get_in(@path) if @path
      output = node[@attribute.to_s] if @attribute
      output = @environment.run(output, record, &@callback) if @callback

      # when no attribute and no callback is provided, try fetching by field name
      if !@attribute && !@callback  
       output = node[@field_name.to_s] if node[@field_name.to_s]
      end
      output
    end

    def extract_list(input)
      @environment.document = input = (input.is_a?(String) ? parse(input) : input)
      input = input.get_in(@path) if @path
      @callback && @environment.run(input, &@callback) || input
    end

    def parse(input)
      super(input)
      @environment.document = (Yajl::Parser.new).parse(input).extend(Utils::DeepFetchable)
    end
  end
end
