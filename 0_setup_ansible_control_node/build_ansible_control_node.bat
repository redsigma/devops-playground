@echo off

set curr_dir=%~dp0
set container_image=ansible_control_node.dockerfile
set container_name=ansible_control_node

docker build -f %curr_dir%%container_image% -t %container_name% .

@pause