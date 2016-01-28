require 'rake'
require 'optparse'

namespace :start_dir_server do
  desc "Starts the directory server"
  task :run_dir_server, [:port, :threads] => :environment do |task, args|
    puts "--args #{args[:port]}"
    puts "Directory Server Started."
    DirectoryServer::DirServerController.run(args)
  end
end
