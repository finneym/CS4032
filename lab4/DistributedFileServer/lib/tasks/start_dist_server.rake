namespace :start_dist_server do
  desc "Starts the distributed file server"
  task :run_dist_server, [:port, :name, :folder, :directory, :threads] => :environment do |_, args|
    puts "--args #{args}"
    puts "Starting Dist Server"
    DistFileServerController.run(args)
    puts "Distributed Server Shut Down."
  end
end
