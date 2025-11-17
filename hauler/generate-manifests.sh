#!/bin/bash

# set variables
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Rancher
for f in ${SCRIPT_DIR}/scripts/rancher/*.sh; do
  bash -e "$f"
done
