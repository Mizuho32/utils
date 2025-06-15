#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source env.sh
RUBYLIB=$RUBYLIB TZ=$TZ HOST=$HOST CID=$CID ruby backupper.rb $PWD/backupper_conf.yaml
