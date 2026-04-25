#!/usr/bin/env bash

file=themes.gitconfig

if ! [ -f $file ]; then
  wget 'https://raw.githubusercontent.com/dandavison/delta/refs/heads/main/themes.gitconfig' -O $file
fi
