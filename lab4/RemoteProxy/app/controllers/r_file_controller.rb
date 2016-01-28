require 'api_controller'
require 'MiddleFile'
require 'digest/md5'
require 'socket'

class RFileController < ApplicationController
  @@temp_folder = File.expand_path(".remoteFiles/")



  def self.config!(host, port, lock_host, lock_port, proxyname)
    @@host = host
    @@port = port
    @@lock_host = lock_host
    @@lock_port = lock_port
    @@proxy_name = proxyname
    @server = ApiController.new(@@host, @@port, @@lock_host, @@lock_port, @@proxy_name)
  end

  def self.method_missing(method_sym, *args, &block)
    puts "Method: #{method_sym} Args: #{args}"
    raise NoMethodError unless File.public_methods.include? method_sym
    unless(method_sym == :open || method_sym == :write)
      raise NoMethodError
    end

    unless File.directory? @@temp_folder
      Dir.mkdir @@temp_folder
    end


    filename = args[0]

    begin
      filepath = @server.read filename, @@temp_folder
    rescue StandardError
      if method_sym == :open
        filepath = File.join @@temp_folder, Digest::MD5.hexdigest(filename)
        f = File.open filepath, args[1]
        f.close
      else
        raise IOError, "File not found"
      end
    end

    md5_before = Digest::MD5.file(filepath).hexdigest
    args[0] = filepath

    if method_sym == :open
      puts "Getting Name: #{filename} at #{filepath}"
      return_val = MiddleFile.new filename, filepath, args[1], @@host, @@port, @@lock_host, @@lock_port, @@proxy_name
    end

    md5_after = Digest::MD5.file(filepath).hexdigest
    puts "Before: #{md5_before} After: #{md5_after}"
    if md5_before != md5_after
      @server.write filename, @@temp_folder
    end

    return return_val
  end
end
