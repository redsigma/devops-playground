#!/bin/bash

# allow ansible to load .cfg file correctly
chmod o-w .

ansible-playbook -i inventory/dev/hosts.ini playbooks/dev.yml -e "config=install"