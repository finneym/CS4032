require 'thread_handler_controller'
require 'set'
class DirServerController < ApplicationController
  def self.run(options)
    pool = ThreadHandlerController.new options[:threads].to_i
    server = TCPServer.new("localhost", options[:port])
    puts "Directory server listening on port #{options[:port]}"
    @@fileservers = {}
    @@files = {}

    puts "Waiting for clients"
    loop do
      client = server.accept
      puts "Talking to client: #{client}"
      pool.push(self.process_request, self, client, options[:peers])
    end
  end

  def self.process_request()
    Proc.new do |server, client|

      puts "Processing request for: #{client}"

      request = client.gets.strip
      puts "Request: #{request}"
      command_word = request.split()[0]
      case command_word

        when "HI"
          name = request.split()[1].split('=')[1]
          host = request.split()[2].split('=')[1]
          port = request.split()[3].split('=')[1]
          @@fileservers[name] = { :host => host, :port => port }
          client.puts "HELLO"

        when "SEARCH"
          server_name = request.split()[1].split('=')[1]
          if @@fileservers.include? server_name
            file_name = request.split()[2].split('=')[1]
            file_hash = Digest::MD5.hexdigest(file_name)
            if @@files.include? file_hash
              peers = @@files[file_hash].deep_dup
              peers.delete(server_name)
              peer = @@fileservers[peers[0]][:host] + ":" + @@fileservers[peers[0]][:port]
              puts "Found file on peer: #{peer}"
              client.puts "LOCATION PEER=#{peer}"
            else
              puts "File #{file_name} not found"
              client.puts "ERROR MESSAGE=404"
            end
          else
            puts "Did not recognise client #{server_name}"
            client.puts "ERROR MESSAGE=UnregistedClient?"
          end
        when "INVALIDATE"
          server_name = request.split()[1].split('=')[1]
          if @@fileservers.include? server_name
            file_name = request.split()[2].split('=')[1]
            file_hash = Digest::MD5.hexdigest(file_name)

            if @@files.include? file_hash
              @@files[file_hash].each do |srv|
                unless srv == server_name
                  TCPSocket.open @@fileservers[srv][:host], @@fileservers[srv][:port] do |sock|
                    puts "Invalidating file #{file_name} on #{srv}"
                    sock.puts "INVALIDATE FILE=#{file_name}"
                  end
                end
              end
              puts "Invalidating directory position for #{file_name}"
              @@files.remove(file_hash)
            end
          else
            puts "Did not recognise client #{server_name}"
            client.puts "ERROR MESSAGE=UnregistedClient?"
          end
        when "REPLICATE"
          server_name = request.split()[1].split('=')[1]
          if @@fileservers.include? server_name
            file_name = request.split()[2].split('=')[1]
            file_hash = Digest::MD5.hexdigest(file_name)
            if @@files.include? file_hash
              ar = [server_name]
              servers = Set.new(@@fileservers.keys) - Set.new(@@files[file_hash]) - Set.new(ar)
              servers = servers.to_a
            else
              @@files[file_hash] = [server_name]
              puts "File #{file_name} now known, thanks to #{server_name}"
              ar = [server_name]
              servers = Set.new(@@fileservers.keys) - Set.new(ar)
              servers = servers.to_a
            end
            servers = servers.sample(((servers.size-1)/2)+1)
            ss = servers.map do |m|
              @@fileservers[m][:host] + ":" + @@fileservers[m][:port]
            end
            unless ss.empty?
              puts "Replicating to: #{ss.join(",")}"
              client.puts "PEERS LIST=#{ss.join(",")}"
            else
              puts "No remaining peers to replicate to"
              client.puts "PEERS LIST=EMPTY"
            end
          else
            puts "Did not recognise client #{server_name}"
            client.puts "ERROR MESSAGE=UnregistedClient?"
          end

        when "REGISTER"
          server_name = request.split()[1].split('=')[1]
          if @@fileservers.include? server_name
            file_name = request.split()[2].split('=')[1]
            file_hash = Digest::MD5.hexdigest(file_name)
            @@files[file_hash] << server_name
            puts "Registered #{file_name} as being on #{server_name}"
            client.puts "STATUS=OKAY"
          else
            puts "Did not recognise client #{server_name}"
            client.puts "ERROR MESSAGE=UnregistedClient?"
          end
      end
      client.close
    end
  end
end
