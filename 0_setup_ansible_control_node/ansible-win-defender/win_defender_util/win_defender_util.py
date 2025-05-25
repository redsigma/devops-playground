#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = '''
---
module: win_defender_util
version_added: "1.0"
short_description: Manage Windows Defender Update and Scan
description: |
     Manage Windows Defender Realtime Scanning and Signature Updating

options:

  action:
    required: true
    description:
      - The action type that will take place
    choices:
     - "update"
     - "quickscan"
     - "fullscan"

'''

EXAMPLES = '''
# Playbook example
  - name: Update Signature
    win_defender_util:
      action: update

  - name: Trigger scan
    win_defender_util:
      action: quickscan
'''
