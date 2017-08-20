#!/usr/bin/env ruby
# coding: utf-8

require_relative '../lib/installer'


install_sym(
  source_name:  "tmux.conf",
  target_name:  ".tmux.conf",
  dest:         "#{ENV['HOME']}/.tmux.conf",
  bk_dir:       "backups",
  bk_lst:       "backups.yaml",
  cur:          Pathname(__FILE__).realpath.dirname
) 
