namespace :start_lock do
  desc "Starts the lock server"
  task :run_lock_server, [:port] => :environment do |_, args|
    puts "--args #{args}"
    puts "Starting Lock Server"
    LockController.run(args)
    puts "Lock Server Shut Down."
  end
end
