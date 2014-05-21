require 'crack'

module Susuwatari
  class Result
    extend Forwardable

    STATUS_URL        = '/testStatus.php'
    RESULT_URL_PREFIX = '/xmlResult/'

    attr_reader :test_id, :current_status, :test_result, :request_raw, :instance

    def_delegators :@test_result, :average, :median

    def initialize(request_response)
      if request_response.is_a?(String)
        if request_response.match(/\/result\/([\w_]*)\/?/)
          @test_id = request_response.match(/\/result\/([\w_]*)\/?/)[1]
          @instance = request_response.match(/(.*)\/result\/[\w_]*\/?/)[1]
          unless @instance.start_with?("http")
            @instance = "http://#{@instance}"
          end
        else
          raise "Please pass the full URL for the test results"
        end
        fetch_status
      else
        @request_raw = request_response
        @test_id     = @request_raw.data.testId
        @instance     = @request_raw.data.summary.match(/(.*)\/result\/[\w_]*\/?/)[1]
      end
    end

    def status
      fetch_status unless current_status == :complete
      current_status
    end

    private

    def fetch_status
      url = "#{@instance}/#{STATUS_URL}"
      status = Hashie::Mash.new(JSON.parse(RestClient.get url,
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
      url = "#{@instance}/#{RESULT_URL_PREFIX}/#{@test_id}/"
      response = RestClient.get url
      # http://stackoverflow.com/questions/1509915/converting-camel-case-to-underscore-case-in-ruby
      response = deep_symbolize(Crack::XML.parse(response.body)) do |key|
        if key == key.upcase
          key.downcase
        else
          key.gsub(/(.)([A-Z])/,'\1_\2').downcase
        end
      end

      @test_result = Hashie::Mash.new(response).response.data
    end

    # Thanks to https://gist.github.com/998709 with a slightly modification.
    def deep_symbolize(hsh, &block)
      hsh.inject({}) do |result, (key, value)|
        # Recursively deep-symbolize subhashes
        value = deep_symbolize(value, &block) if value.is_a? Hash
        # Recursively deep-symbolize subarrays
        value = deep_symbolize_array(value, &block) if value.is_a? Array

        # Pre-process the key with a block if it was given
        key = yield key if block_given?
        # Symbolize the key string if it responds to to_sym
        sym_key = key.to_sym rescue key

        # write it back into the result and return the updated hash
        result[sym_key] = value
        result
      end
    end

    def deep_symbolize_array(arry, &block)
      arry.collect do |item|
        if item.is_a? Hash
          # Recursively deep-symbolize subhashes
          deep_symbolize(item, &block)
        elsif item.is_a? Array
          # Recursively deep-symbolize subarrays
          deep_symbolize_array(item, &block)
        else
          item
        end
      end
    end
  end
end
