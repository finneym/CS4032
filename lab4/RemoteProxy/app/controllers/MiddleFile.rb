require 'api_controller'
require 'digest/md5'
require 'socket'

class MiddleFile < ApplicationController

    def initialize(name, path, mode, host, port, lock_host, lock_port, proxyname)
      @filename = name
      @filepath = path
      @internal = File.open path, mode
      @md5_before = Digest::MD5.file(path).hexdigest
      $stdout.puts "MD5 Before: #{@md5_before}"
      @closed = false
      @host = host
      @port = port
      @lock_host = lock_host
      @lock_port = lock_port
      @proxyname = proxyname
    end

    def write(content)
      $stdout.puts "Writing #{content} to #{@internal}"
      @internal.write content
      @internal.flush
    end

    def close
      if @closed
        return
      end

      @internal.close

      @closed = true

      md5_after = Digest::MD5.file(@filepath).hexdigest

      if @md5_before != md5_after
        server = ApiController.new @host, @port, @lock_host, @lock_port, @proxyname
        server.write @filename, Pathname.new(@filepath).dirname
      end
    end

    def puts(content)
      @internal.puts content
      @internal.flush
    end

    def gets
      @internal.gets
    end
end
