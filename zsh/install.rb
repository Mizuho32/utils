#!/usr/bin/env ruby
# coding: utf-8

require_relative '../lib/installer'


install_sym(
  source_name:  "zshrc",
  target_name:  ".zshrc",
  dest:         "#{ENV['HOME']}/.zshrc",
  bk_dir:       "backups",
  bk_lst:       "backups.yaml",
  cur:          Pathname(__FILE__).realpath.dirname
) 
