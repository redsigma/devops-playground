@echo off

set curr_dir=%~dp0
set container_name=ansible_control_node
set image_name=ansible_control_node

:: Check if container is running
for /f "tokens=*" %%i in ('docker ps --filter "name=%container_name%" --filter "status=running" --format "{{.Names}}"') do (
    if "%%i"=="%container_name%" (
        docker exec -it %container_name% bash
        goto :eof
    )
)

:: If not running, run it
docker run -v %curr_dir%:/repo --rm -it --name %container_name% %image_name% bash

@pause