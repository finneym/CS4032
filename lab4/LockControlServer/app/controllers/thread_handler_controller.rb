class ThreadHandlerController < ApplicationController
  @dead = true
  @queue
  @threads
  def initialize(workers)
    @dead = false
    @queue = Queue.new()
    @threads = (0..workers).map do
      Thread.new do
        loop do
          proc, args = @queue.pop(false)
          proc.call(args)
        end
      end
    end
  end

  def kill
    if @dead
      raise StandardError, 'Stop trying to kill me!'
    end
    @threads.each do |thread|
      thread.join()
    end
    @dead = true
  end

  def push(f, *parameters)
    if @dead
      raise StandardError, 'Stop trying to kill me!'
    end
    @queue.push([f,parameters])
  end
end
