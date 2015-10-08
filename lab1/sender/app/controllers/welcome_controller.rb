class WelcomeController < ApplicationController
  def index
  end

  require 'net/http'
  require 'uri'
  def get
    if params[:url] =~ URI::regexp
      uri = URI.parse(params[:url])
      uri.query = URI.encode_www_form({ :message => params[:message] })
      uri.port = 8000
      if params[:url] =~ /^https:\/\/.*?scss.tcd.ie/
        if params[:username] == '' || params[:password] == ''
          render plain: 'Invalid username/password'
          return
        else
          begin
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            request = Net::HTTP::Get.new(uri.request_uri)
            request.basic_auth(params[:username], params[:password])
            response = http.request(request)
            res = response.body
          rescue Exception => e
            render plain: 'Error occured, possibly wrong '+
                       'username/password. Error: "' +
                       e.message + '"'
            return
          end
        end
      else
        res = Net::HTTP.get(uri)
      end
      render plain: res
    else
      render plain: 'Invalid URL'
    end
  end
end
