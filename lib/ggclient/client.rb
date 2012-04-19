require 'uri'
require 'httpclient'
require 'net/http/persistent'

module Ggclient
  class Client
    attr_reader :url, :http_client

    def initialize(url = "http://localhost:9292/")

      extract_username_and_password_from_url!(url)
      @http_client = HTTPClient.new
      @http_client.set_auth(url_for(:upload), @username, @password) if @username or @password
      @http_client.www_auth.basic_auth.challenge(url_for(:upload)) # Workaround: https://github.com/nahi/httpclient/issues/63
      @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    def extract_username_and_password_from_url!(url)
      uri = URI.parse(url.to_s)
      @username, @password = uri.user, uri.password
      uri.user = uri.password = nil
      uri.path = uri.path + "/" unless uri.path.end_with?("/")
      @url = uri.to_s
    end

    def url_for(path)
      url + path.to_s
    end

    def clear
      http_client.delete(url_for(:gems))
    end

    def delete(gemname)
      http_client.delete("#{url_for(:gems)}/#{gemname}.gem")
    end

    def find(gemfile)
      puts "querying: #{gemfile}"
      http_client.get(url_for("gems/#{gemfile}.gem")).status == 302
    end

    def push(gemfile)
      puts "uploading: #{File.basename(gemfile)}"
      response = http_client.post(url_for(:upload), {'file' => File.open(gemfile, "rb")}, {'Accept' => 'text/plain'})

      if response.status < 400
        response.body
      else
        puts "Error (#{response.code} received)\n\n#{response.body}"
      end
    end
  end
end
