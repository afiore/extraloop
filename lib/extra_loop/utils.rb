module Utils
  module ScrapingHelpers
    #
    # Generates a proc that iterates over a list of anchors
    # and collects the value of the specified paramenter
    #
    def values_for_param(param)
      lambda { |nodeList|
        nodeList.collect {|node|
          query = URI::parse(node.attr(:href)).query
          query.split("&").collect { |token| token.split("=") }.
            detect{ |chunks| chunks.first == param.to_s }.last
        }.uniq
      }
    end
  end

  module Support
    #
    # Creates instance variables from a hash.
    #
    # hash     - An hash representing of instance variables to be created.
    # defaults - An hash representing the attributes' default values (optional).
    #
    protected
    def set_attributes(hash, defaults={})
      allowed = defaults.keys
      hash.each { |key, value| self.instance_variable_set("@#{key}", value)}
      defaults.each do |key, value|
        self.instance_variable_set("@#{key}", value) unless self.instance_variable_get("@#{key}") 
      end
    end
  end



end
