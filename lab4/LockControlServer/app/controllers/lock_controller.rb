require 'socket'
require 'thread_handler_controller'
require 'digest/md5'
require 'set'
class LockController < ApplicationController
  def self.run(options)
    pool = ThreadHandlerController.new 4
    server = TCPServer.new("localhost", options[:port])
    @users = {}
    @list = {}
    @counters = {}
    @active_locks = Set.new
    loop do
      client = server.accept
      puts "Talking to client: #{client}"
      pool.push(self.process_request, server, client)
    end
  end

  def self.process_request
    Proc.new do |_, client|
      request = client.gets.strip
      puts "Request: #{request}"
      case request.split()[0]
        #PING
        #PONG
        when "PING"
          client.puts "PONG"
        #NEW USER=<NAME>
        #CREATED USER=<NAME>
        #REJECTED USER=<NAME>
        when "NEW"
          puts "Creating new user"
          unless @users.include? request.split()[1].split('=')[1]
            @users[request.split()[1].split('=')[1]] = client
            client.puts "CREATED USER=#{request.split()[1].split('=')[1]}"
            puts "Created user=#{request.split()[1].split('=')[1]}"
          else
            client.puts "REJECTED USER=#{request.split()[1].split('=')[1]}"
            puts "Rejected user=#{request.split()[1].split('=')[1]}"
          end

        #AQUIRE USER=<NAME> FILE=<FILE_NAME>
        #AQUIRED FILE=<FILE_NAME>
        #REJECTED FILE=<FILE_NAME>
        when "AQUIRE"
          if @users.include? request.split()[1].split('=')[1]
            unless @list[request.split()[2].split('=')[1]]
              @list[request.split()[2].split('=')[1]] = request.split()[1].split('=')[1]
              if @counters[request.split()[2].split('=')[1]]
                @counters[request.split()[2].split('=')[1]] += 1
              else
                @counters[request.split()[2].split('=')[1]] = 1
              end

              puts "Gave lock of #{request.split()[2].split('=')[1]} to #{request.split()[1].split('=')[1]}"
              client.puts "AQUIRED FILE=#{request.split()[2].split('=')[1]}"
            else
              puts "Kept lock of #{request.split()[2].split('=')[1]} from #{request.split()[1].split('=')[1]}"
              client.puts "REJECTED FILE=#{request.split()[2].split('=')[1]}"
            end
          end
        #RELEASE USER=<NAME> FILE=<FILE_NAME>
        #RELEASED FILE=<FILE_NAME>
        #REJECTED FILE=<FILE_NAME>
        when "RELEASE"
          if @list[request.split()[2].split('=')[1]] == request.split()[1].split('=')[1]
            @list[request.split()[2].split('=')[1]] = nil
            client.puts "RELEASED FILE=#{request.split()[2].split('=')[1]}"
          else
            client.puts "REJECTED RELEASE=#{request.split()[2].split('=')[1]}"
          end
        #READ USER=<NAME> FILE=<FILE_NAME>
        #COUNTER FILE=<FILE_NAME> FILE=<COUNT>
        when "READ"
          if @users.include? request.split()[1].split('=')[1]
            if @counters[request.split()[2].split('=')[1]]
              client.puts "COUNTER FILE=#{request.split()[2].split('=')[1]} COUNTER=#{@counters[request.split()[2].split('=')[1]]}"
            else
              client.puts "COUNTER FILE=#{request.split()[2].split('=')[1]} COUNTER=0"
            end
          end
      end
    end
  end
end
