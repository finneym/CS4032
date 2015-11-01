class ResponseController < ApplicationController

  def simple
    res = params[:message].upcase + "\\n"
    port = request.port;
    if params[:message] =~ /^HELO /
      ip = ""
      begin
        ip = local_ip
      rescue Exception
        render plain: "Requires Internet Connection: No Internet Connection Found"
        return;
      end
      res += "IP:[" + ip + "]\\nPort:[" + port.to_s + "]\\nStudent Number:[77cd908f7265366ab0487da5105b7218a1e328e666aba72a789fc1b7bf0c58bf]"
    elsif params[:message] =~ /^KILL SERVICE/
      system("kill -9 $(lsof -i tcp:"+port.to_s+" -t)")
    end
    render plain: res
  end

  require 'socket'

  def local_ip
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end