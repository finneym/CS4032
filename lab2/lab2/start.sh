#!/bin/bash
port=3000
if [ "$1" ]; then
	port="$1"
fi
kill -9 $(lsof -i tcp:$port -t)
echo "Port is $port"
echo "Please wait while the server starts"
bundle exec puma -C config/puma.rb -p $port --quiet & 
sleep 5
message="temp"
printf "Type in message"
while [ "1" ]; do
	printf "\n"
	read message
	curl -G --data-urlencode "message=$message" http://127.0.0.1:$port/response/simple
	if [ "$message" == "KILL SERVICE" ]; then
		break
	fi
done

