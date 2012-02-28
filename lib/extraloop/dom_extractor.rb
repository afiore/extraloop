module ExtraLoop
  class DomExtractor < ExtractorBase

    # Public: Runs the extractor against a document fragment (dom node or object).
    #
    # node   - The document fragment
    # record - The extracted record
    #
    # Returns the text content of the element, or the output of the extractor's callback.
    #

    def extract_field(node, record=nil)
      target = node = node.respond_to?(:document) ? node : parse(node)
      target = node.at(@selector)  if @selector
      target = target.attr(@attribute) if target.respond_to?(:attr) && @attribute
      target = @environment.run(target, record, &@callback) if @callback

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
      nodes = (input.respond_to?(:document) ? input : parse(input))
      nodes = nodes.search(@selector) if @selector
      Array(@callback && @environment.run(nodes, &@callback) || nodes)
    end

    def parse(input)
      super(input)
      @environment.document = is_xml(input) ? Nokogiri::XML(input) : Nokogiri::HTML(input)
    end

    def is_xml(input)
      input =~ /^\s*\<\?xml version=\"\d\.\d\"\?\>/
    end
  end
end
