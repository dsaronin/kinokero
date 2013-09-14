require 'faraday'

module FaradayMiddleware
  # Request middleware that supports XSRF protection
  #
  # Adds XSRF token to all requests; checks for same token in responses
  #
  class Xsrf < Faraday::Middleware
    CONTENT_TYPE = 'Content-Type'.freeze
    MIME_TYPE    = 'application/json'.freeze

    #  dependency <some gem>

    def call(env)
      # do something with the request
#       match_content_type(env) do |data|
#         env[:body] = encode data
#       end

      @app.call(env).on_complete do |env|
        # do something with the response
        # env[:response] is now filled in
      end
      
    end

    def encode(data)
      ::JSON.dump data
    end

    def match_content_type(env)
      if process_request?(env)
        env[:request_headers][CONTENT_TYPE] ||= MIME_TYPE
        yield env[:body] unless env[:body].respond_to?(:to_str)
      end
    end

    def process_request?(env)
      type = request_type(env)
      has_body?(env) and (type.empty? or type == MIME_TYPE)
    end

    def has_body?(env)
      body = env[:body] and !(body.respond_to?(:to_str) and body.empty?)
    end

    def request_type(env)
      type = env[:request_headers][CONTENT_TYPE].to_s
      type = type.split(';', 2).first if type.index(';')
      type
    end
  end
end
