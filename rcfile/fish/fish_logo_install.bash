#!/usr/bin/bash

cd fish/

if ! [ -d "fish_logo" ]; then
  git clone https://github.com/Mizuho32/fish_logo.git
  cd fish_logo
  git checkout -b msg origin/msg
fi
