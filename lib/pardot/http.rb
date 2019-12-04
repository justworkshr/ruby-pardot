module Pardot
  module Http

    def get(object, path, params = {}, num_retries = 0)
      request(:get, object, path, params = params, max_retries = num_retries)
    end

    def post(object, path, params = {}, num_retries = 0, bodyParams = {})
      request(:post, object, path, params = params, bodyParams = bodyParams, max_retries = num_retries)
    end

    protected

    def request(method, object, path, params = {}, bodyParams = {}, max_retries = 0)
      tries_remaining ||= max_retries
      smooth_params(object, params)
      full_path = fullpath(object, path)
      headers = create_auth_header object
      # puts method, full_path, params, bodyParams, headers #remove
      if method == :get
        check_response(self.class.send(method, full_path, :query => params, :headers => headers))
      else
        check_response(self.class.send(method, full_path, :query => params, :body => bodyParams, :headers => headers))
      end

    # handle errors that should be retried:
    # exponential backoff/retry for timeout errors
    # reauthenticate/retry for expired API key
    rescue Net::HTTPBadResponse, Pardot::ExpiredApiKeyError, Net::ReadTimeout => e
      if (tries_remaining -= 1) > 0
        reauthenticate
        sleep(2 ** (max_retries - tries_remaining))
        retry
      else
        raise Pardot::NetError.new(e)
      end

    rescue SocketError, Interrupt, EOFError, SystemCallError, Timeout::Error, MultiXml::ParseError => e
      raise Pardot::NetError.new(e)
    end

    def smooth_params(object, params)
      return if object == "login"

      authenticate unless authenticated?
      params.merge! :format => @format
    end

    def create_auth_header object
      return if object == "login"
      { :Authorization => "Pardot api_key=#{@api_key}, user_key=#{@user_key}" }
    end

    def check_response(http_response)
      rsp = http_response["rsp"]
      # puts 'this is the response ', rsp #remove
      error = rsp["err"] if rsp
      error ||= "Unknown Failure: #{rsp.inspect}" if rsp && rsp["stat"] == "fail"
      content = error['__content__'] if error.is_a?(Hash)

      if [error, content].include?("Invalid API key or user key") && @api_key
        raise ExpiredApiKeyError.new @api_key
      end

      raise ResponseError.new error if error

      rsp
    end

    def fullpath(object, path)
      full = File.join("/api", object, "version", @version.to_s)
      unless path.nil?
        full = File.join(full, path)
      end
      full
    end

  end
end
