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

  module URIAddition
    # 
    # Public
    #
    # Generates a hash representation of a uri's query string.
    # 
    # Returns a hash mapping the URL query parameters to their respective values
    #
    # NOTE: this is intended as a decorator method for instances of URI::HTTP.
    #
    # examples:
    #
    # URI::parse(url).extend(URIAddition).query_hash
    #

    def query_hash
      return unless self.query
      self.query.split("&").reduce({}) do |memo, item|
        param, value = *item.split("=")
        memo.merge(param.to_sym => value)
      end
    end
  end

  module DeepFetchable
    def get_in(path)
      keys, node = Array(path), self

      keys.each_with_index do |key, index|
        node = node[key]
        next_key = keys[index + 1]
        break unless node
      end

      node
    end
  end

  module Support
    def symbolize_keys(hash)
      hash.reduce({}) { |memo, (k,v)| memo.merge(k => v) }
    end
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
