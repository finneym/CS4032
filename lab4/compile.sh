#!/bin/bash
( cd DirectoryServer/ ; bundle install )
( cd DistributedFileServer/ ; bundle install )
( cd LockControlServer/ ; bundle install )
( cd RemoteProxy/ ; bundle install )