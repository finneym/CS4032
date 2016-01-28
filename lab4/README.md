## How to Install
* First install Ruby on Rails
* ```./compile.sh```
## How to run
* ```( cd DirectoryServer/ ; ./start port numThreads) ```
* ```( cd DistributedFileServer/ ; ./start port name folder directoryHost:directoryPort numThreads) ```
* ```( cd LockControlServer/ ; ./start port) ```
* ```( cd RemoteProxy/ ; ./start ) ```

Edit ```/RemoteProxy/lib/tasks/start_proxy.rake to run different tasks/tests```

See ```/report/report.pdf``` for more info on implementation