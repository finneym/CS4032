require 'socket'
require 'digest/md5'

class ApiController < ApplicationController
  @@counters = {}

  def initialize(host, port, lockHost, lockPort, name)
    @server = TCPSocket.new(host, port)
    @proxyname = name
    @lockHost = lockHost
    @lockPort = lockPort
    lock = TCPSocket.new(@lockHost, @lockPort)
    loop do
      puts "Attempting to join lock"
      lock.puts "NEW USER=#{@proxyname}"
      lock_header = lock.gets.strip
      puts "Received from lock"
      break if lock_header.split()[0] == "CREATED"
      @proxyname += rand(9).to_s
      puts "New name: #{@proxyname}"
      lock = TCPSocket.new(lockHost, lockPort)
    end
    puts "Joined lock"
  end


  def read(fileName, folder)
    puts "send request"
    lock = TCPSocket.new(@lockHost, @lockPort)
    lock_message = "READ USER=#{@proxyname} FILE=#{fileName}"
    lock.puts lock_message
    lock_header = lock.gets.strip
    @@counters[fileName] = lock_header.split()[2].split('=')[1].to_i
    puts "#{fileName}: Local Counter = #{@@counters[fileName]} Lock Counter #{fileName} = #{lock_header.split()[2].split('=')[1]}"
    message = "REQUEST FILENAME=#{fileName}"
    header = @server.puts(message)
    puts "Sending: #{message} to #{@server}"

    # FILE_LENGTH LEN\n
    # ERROR MESSAGE\n
    if header.split()[0] == 'ERROR'
      raise StandardError, "ERROR: RECEIVED: #{header}"
    end
    filepath = folder + "/" + MD5.hexdigest(filename)
    file = File.open(filepath,'w')
    file.write(@server.read(header.split()[1].split('=')[1].to_i))
    file.close()

    return filepath
  end
  def write(fileName, folder)
    lock_message = "READ USER=#{@proxyname} FILE=#{fileName}"
    lock = TCPSocket.new(@lockHost, @lockPort)
    lock.puts lock_message
    lock_header = lock.gets.strip
    puts "#{fileName}: Local Counter = #{@@counters[fileName]} Lock Counter = #{lock_header.split()[2].split('=')[1]}"
    if(@@counters[fileName] < lock_header.split()[2].split('=')[1].to_i)
      puts "File is out of sync, are you sure you wish to precede? (y/n)"
      a = gets.chomp
      case a
        when "n"
          return
      end
    end

    puts "FileName: #{fileName} folder: #{folder}"
    file_Path = File.join(folder, Digest::MD5.hexdigest(fileName))
    contents = File.read(file_Path)

    lock_message = "AQUIRE USER=#{@proxyname} FILE=#{fileName}"
    loop do
      lock = TCPSocket.new(@lockHost, @lockPort)
      lock.puts lock_message
      lock_header = lock.gets.strip
      break if lock_header.split()[0] == "AQUIRED"
      sleep(3) #3 seconds
    end
    @server.puts "WRITE NAME=#{fileName} CONTENT_LENGTH=#{File.size file_Path}"
    @server.write contents
    lock_message = "RELEASE USER=#{@proxyname} FILE=#{fileName}"
    lock = TCPSocket.new(@lockHost, @lockPort)
    lock.puts lock_message
    lock_header = lock.gets.strip
    if lock_header.split()[0] == "REJECTED"
      puts "WHOOPS! Lock release was rejected"
    end
  end
end
