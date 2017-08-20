#!/usr/bin/env ruby
# coding: utf-8

require_relative '../lib/installer'

uninstall_sym(
  dest:         "#{ENV['HOME']}/.tmux.conf",
  bk_dir:       "backups",
  bk_lst:       "backups.yaml",
  cur:          Pathname(__FILE__).realpath.dirname
)
