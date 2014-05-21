module Susuwatari
  class Client
    extend Forwardable

    attr_accessor :params, :response, :test_id, :instance
    def_delegator :@result, :status

    def initialize(params = {})
      params.fetch(:k)
      params.fetch(:url)
      params[:f] = :json
      params[:runs] ||= 1
      self.instance ||= 'http://www.webpagetest.org'
      params.delete(:instance)      
      params.delete(:r)
      self.params = params
    end

    def review_results
      raise_error("Please pass proper WebPageTest URL to review its results") unless url_review?
      @test_id = params[:url].match(/\/result\/([\w_]*)\//)
      raise_error("Cannot find test id within URL string") if @test_id.nil?
      @test_id = @test_id[1]
      @result = Result.new(@test_id)
      @result.status && @result.test_result
    end

    def run
      return status if @result
      @test_id = make_new_request
      @result = Result.new(@test_id)
      @result.test_id
    end

    def result
      @result && @result.test_result || {}
    end

    def status
      @result && @result.status || :to_be_run
    end

    private

    def url_review?
     return params[:url] =~ /\/result\/.*/ ? true : false
    end

    def make_new_request
      response = RestClient.get "#{instance}/runtest.php", :params => params, :accept => :json
      raise_error 'The requests was not completed, try again.' unless response.code == 200

      body     = Hashie::Mash.new(JSON.parse(response.body))
      raise_error(body.statusText) unless body.statusCode == 200
      body.data.testId
    end

    def raise_error(msg)
      raise Error.new(msg)
    end
  end
end
