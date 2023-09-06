#!/bin/bash

# get script directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

current_azd_env=$(azd env list | grep true | cut -f 1 -d " ")

if [ -z "$current_azd_env" ]; then
  echo "No active Azure DevOps environment found."
  exit 1
else
  rm -f $DIR/.env && ln -s $DIR/../.azure/$current_azd_env/.env $DIR/.env
  # cat $DIR/../.azure/$current_azd_env/.env > $DIR/.env
fi