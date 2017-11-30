#!/usr/bin/env ruby

require 'yaml'
require 'erb'

tmux_version = `tmux -V`[/(\d+\.\d+)/, 1].to_f
COND         = 2.4

puts "tmux version #{tmux_version}"

d = if tmux_version >= COND then
      YAML.load_file("after2.4.yaml")
    else
      YAML.load_file("prior2.4.yaml")
    end

File.write("tmux.conf", ERB.new(File.read("tmux.conf.tmpl")).result(binding))
