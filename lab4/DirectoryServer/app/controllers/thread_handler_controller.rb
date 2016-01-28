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
          puts "Waiting to pop"
          proc, args = @queue.pop
          puts "Popped Thread"
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
      raise StandardError, 'I\'m dead!'
    end
    @queue.push([f,parameters])
  end
end
