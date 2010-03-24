require 'cgi'
require 'openssl'

module Rack
  class RsaSigValidator
    def initialize(app)
      @app = app
      @key = OpenSSL::PKey::RSA.new(IO.read("example_key.pub"))
    end

    def call(env)
      if signature_is_valid?(env)
        @app.call(env)
      else
        [401, {"Content-Type" => "text/html"}, "Bad Signature"]
      end
    end

    def signature_is_valid?(env)
      verb = env["REQUEST_METHOD"]
      host = env["REMOTE_HOST"]
      path = env["REQUEST_PATH"]
      query_string = env["QUERY_STRING"]
      query_params = Hash[*query_string.split("&").map { |p| p.split("=") }.flatten.map { |p| CGI.unescape(p) }]
      sig = query_params.delete("sig")
      return false unless sig # Short circuit

      sorted_query_params = query_params.sort.map{|param| param.join("=")}
      # => ["user=mat", "tag=ruby"]
      canonicalized_params = sorted_query_params.join("&") # => "user=mat&tag=ruby"
      expected_string = verb + host + path + canonicalized_params
      expected_string == @key.public_decrypt(sig)
    end
  end
end