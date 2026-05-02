#!/usr/bin/env ruby

require 'yaml'
require 'erb'

tmux_version = `tmux -V`[/(\d+\.\d+)/, 1].to_f
COND         = 2.4
default_key = ?g

print "Enter key prefix [a-z] (default: #{default_key}) >>"
key = if (k = gets.chomp).empty? then
        default_key
      else
        k
      end

print "Enter shell (default: bash) >>"
shell = if (s = gets.chomp).empty? then
        "bash"
      else
        s
      end

puts "tmux version #{tmux_version}"

d = if tmux_version >= COND and tmux_version >= 2.0 then
      YAML.load_file("after2.4.yaml")
    elsif tmux_version < COND and tmux_version >= 2.0 then
      YAML.load_file("prior2.4.yaml")
    else
      print "Which version? 1. after 2.4, 2. before 2.4 >>"
      if gets.chomp =~ /1/ then
        YAML.load_file("after2.4.yaml")
      else
        YAML.load_file("prior2.4.yaml")
      end
    end

File.write("tmux.conf", ERB.new(File.read("tmux.conf.tmpl")).result(binding))
