workers 4
#each worker uses 1 - 2 thread(s)
threads 1, 2
preload_app!

rackup DefaultRackup
  port ENV['PORT'] || 3000
environment ENV['RAILS_ENV'] || 'development'

on_worker_boot do
  ActiveRecord::Base.establish_connection
end