namespace :start_proxy do
  desc "Starts the Proxy server"
  task :start_proxy_server => :environment do |task, args|
    RFileController.config! "localhost", 1234, "localhost", 4567, "ProxyServer0"
    f = RFileController.open('test2.txt', 'w+')
    f.write "test string"
    f.close
  end

end
