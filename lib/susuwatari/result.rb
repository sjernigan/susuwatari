require 'crack'

module Susuwatari
  class Result
    extend Forwardable

    STATUS_URL        = 'http://www.webpagetest.org/testStatus.php'
    RESULT_URL_PREFIX = 'http://www.webpagetest.org/xmlResult/'

    attr_reader :test_id, :current_status, :test_result, :request_raw

    def_delegators :@test_result, :average, :median

    def initialize(request_response)
      if request_response.is_a?(String)
        @test_id = request_response
        fetch_status
      else
        @request_raw = request_response
        @test_id     = @request_raw.data.testId
      end
    end

    def status
      fetch_status unless current_status == :complete
      current_status
    end

    private

    def fetch_status
      status = Hashie::Mash.new(JSON.parse(RestClient.get STATUS_URL,
                                           :params => {:f => :json,
                                                       :test => @test_id }))
      case status.data.statusCode.to_s
      when /1../
        @current_status = :running
      when '200'
        @current_status = :completed
        fetch_result
      when /4../
        @current_status = :error
      end
    end

    def fetch_result
      response = RestClient.get "#{RESULT_URL_PREFIX}/#{@test_id}/"
      # http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      response = deep_symbolize(Crack::XML.parse(response.body)) do |key|
        key.gsub(/(.)([A-Z])/,'\1_\2').downcase
      end

      @test_result = Hashie::Mash.new(response).response.data
    end

    # Thanks to https://gist.github.com/998709 with a slightly modification.
    def deep_symbolize(hsh, &block)
      hsh.inject({}) do |result, (key, value)|
        # Recursively deep-symbolize subhashes
        value = deep_symbolize(value, &block) if value.is_a? Hash

        # Pre-process the key with a block if it was given
        key = yield key if block_given?
        # Symbolize the key string if it responds to to_sym
        sym_key = key.to_sym rescue key

        # write it back into the result and return the updated hash
        result[sym_key] = value
        result
      end
    end
  end
end
