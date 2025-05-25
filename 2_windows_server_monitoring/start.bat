@echo off

set curr_dir=%~dp0

docker-compose up -d

echo Grafana available on localhost:3000

echo Prometheus available on localhost:9090

@pause