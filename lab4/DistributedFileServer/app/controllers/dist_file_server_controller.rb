require 'socket'
require 'thread_handler_controller'
require 'digest/md5'


require 'ruby-debug'
class DistFileServerController < ApplicationController

  @folder = File.expand_path("~/.dfs")

  def self.run(options)
    pool = ThreadHandlerController.new options[:threads].to_i
    server = TCPServer.new("localhost", options[:port])
    @host = "localhost"
    @port = options[:port].to_i
    @name = options[:name]
    @directory = options[:directory]
    @dirHost = @directory.split(":")[0]
    @dirPort = @directory.split(":")[1].to_i
    @folder = options[:folder]
    @cache = {}

    # check if folder exists
    unless File.directory? @folder
      Dir.mkdir @folder
    end

    sock = TCPSocket.new @dirHost, @dirPort
    sock.puts "HI NAME=#{@name} HOST=#{@host} PORT=#{@port}"
    header = sock.gets
    puts "Header: #{header}"
    unless header.split()[0] == 'HELLO'
      @directory = nil
    end

    loop do
      puts "Starting to listen"
      client = server.accept
      puts "Talking to client: #{client}"
      pool.push(self.process_request, self, client)
    end
  end


  def self.get_file_from_peer(peer, file_name)
    sock = TCPSocket.new peer.split(":")[0], peer.split(":")[1].to_i
    sock.puts "REQUEST FILE=#{file_name}"

    header = sock.gets
    if header.split()[0] == 'ERROR'
      return ""
    end
    content_length = header.split()[1].split('=')[1]
    sock.read(content_length.to_i)
  end

  def self.cacheUpdate(local_file_name, file_contents)
    @cache.delete(local_file_name)
    @cache[local_file_name] = file_contents
  end

  def self.search_peers(file_name)
    unless @directory
      return nil
    end

    puts "Searching #{@directory} for peers with file #{file_name}"

    sock = TCPSocket.new @dirHost, @dirPort
    sock.puts "SEARCH ME=#{@name} FILE=#{file_name}"

    header = sock.gets
    if header.split()[0] == 'ERROR'
      return nil
    end
    sock.close
    header.split()[1].split('=')
  end

  def self.invalidate_peers!(file_name)
    unless @directory
      return
    end

    puts "Invalidating peers copy of #{file_name} via #{@directory}"
    sock = TCPSocket.new @dirHost, @dirPort
    sock.puts "INVALIDATE NAME=#{@name} FILE=#{file_name}"
    sock.close
  end

  def self.replicate_to_peers!(file_name)
    unless @directory
      return
    end

    puts "Replicating copy of #{file_name} to peers via #{@directory}"

    sock = TCPSocket.new @dirHost, @dirPort

    local_file_name = File.join(@folder, Digest::MD5.hexdigest(file_name))
    filesize = File.size local_file_name
    file_contents = File.read local_file_name

    sock.puts "REPLICATE ME=#{@name} FILE=#{file_name}"
    reply = sock.gets
    sock.close

    unless reply.split()[1].split('=')[1] == "EMPTY"
      peers = reply.split()[1].split('=')[1].split(',')
      peers.each do |peer|
        puts "Replicating #{file_name} to #{peer}"
        ph = peer.split(':')[0]
        pp = peer.split(':')[1].to_i
        TCPSocket.open ph, pp do |peer_sock|
          peer_sock.puts "REPLICATE FILE=#{file_name} CONTENT_LENGTH=#{filesize}"
          peer_sock.write file_contents
        end
      end
    else
      puts "No peers to replicate to"
    end
  end

  def self.process_request()
    Proc.new do |server, client|
      puts "Processing request for: #{client}"

      request = client.gets.strip
      puts "Request: #{request}"
      command_word = request.split()[0]
      file_name = request.split()[1].split('=')[1]
      local_file_name = File.join(@folder, Digest::MD5.hexdigest(file_name))

      case command_word

        when "HI"
          client.write "HELLO"
        when "REQUEST"
          if @cache.include? local_file_name
            puts "File #{file_name} held in cache"
            file_contents = @cache[local_file_name]
            file_length = file_contents.bytesize
            return_header = "FILE CONTENT_LENGTH=#{file_length}"

            puts "Sending: #{return_header} and file"

            client.puts return_header
            client.write file_contents
          elsif File.exists? local_file_name
            puts "File #{file_name} held locally"
            file_contents = File.read local_file_name
            file_length = File.size local_file_name
            return_header = "FILE CONTENT_LENGTH=#{file_length}"

            puts "Sending: #{return_header} and file"

            client.puts return_header
            client.write file_contents
          else
            puts "File #{file_name} doesn't exist locally, searching peers"
            peer = server.search_peers file_name
            if peer
              puts "Found peer: #{peer}"
              file_contents = server.get_file_from_peer peer, file_name
              File.open(local_file_name, "w") { |f| f.write file_contents }
            else
              puts "#{file_name} not found"
              client.puts "ERROR MESSAGE=FileNotFound"
            end
          end

        when "WRITE"
          size = request.split()[2].split('=')[1].to_i
          puts "Writing a file: #{file_name}, size: #{size}"

          file_contents = client.read size
          puts "File contents: #{file_contents}"
          File.open(local_file_name, "w+") { |f| f.write file_contents }


          client.puts "WRITE STATUS=Okay"
          cacheUpdate(local_file_name, file_contents)

          server.invalidate_peers! file_name
          server.replicate_to_peers! file_name

        when "EXISTS?"
          if File.exists? local_file_name or @cache.include? local_file_name
            client.puts "STATUS=Exists"
          else
            peer = server.search_peers file_name
            if peer
              client.puts "STATUS=Exists"
            else
              client.puts "STATUS=DoesNotExist"
            end
          end
        when "INVALIDATE"
          @cache.delete local_file_name

          if File.exists? local_file_name
            File.delete local_file_name
          end
          puts "Invalidated #{file_name} as per request"
          client.puts "INVALIDATED"

        when "REPLICATE"
          content_length = request.split()[2].split('=')[1]
          contents = client.read(content_length.to_i)
          File.open(local_file_name, "w") { |f| f.write contents }
          cacheUpdate(local_file_name, contents)
          # Register ownership
          sock = TCPSocket.new @dirHost, @dirPort
          sock.puts "REGISTER ME=#{@name} FILE=#{file_name}"
          sock.close

          client.close
      end
    end
  end
end
