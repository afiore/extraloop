module Helpers
  module Scrapers

    # Public:
    #
    # Stubs a HTTP request/response pair
    #
    # request_args  - Hash of options to be passed to Typhoeus::Request
    # response_args - Hash of options to be passed to Typhoeus::Response (and to Hydra#stub).
    #
    # Returns nothing.
    #

    def stub_http(request_args={}, response_args={})

      response_args = {
        :code => 200,
        :headers => "",
        :body => "response stub"
      }.merge(response_args)

      request_args = {
        :method => :get,
        :url => anything,
        :options => anything
      }.merge(request_args)

      @hydra ||= Typhoeus::Hydra.new
      stub(Typhoeus::Hydra).new { @hydra }
      response = Typhoeus::Response.new(response_args)

      stub.proxy(Typhoeus::Request).new(request_args[:url], request_args[:options]) do |request|
        #
        # this allows to stub several requests by handing control to a block
        #

        if block_given?
          yield(@hydra, request, response)
        else
          @hydra.stub(request_args[:method], request_args[:url]).and_return(response)
        end
        request
      end
    end
  end
end
