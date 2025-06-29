#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR

#pwd
source env.sh
#echo $PATH
#echo $MISE_DATA_DIR
#echo $RUBYLIB
#mise --version
#ruby --version
RUBYLIB=$RUBYLIB TZ=$TZ HOST=$HOST CID=$CID ruby backupper.rb $PWD/backupper_conf.yaml
