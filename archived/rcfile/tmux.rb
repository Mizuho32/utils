#!/usr/bin/env ruby
# coding: utf-8

require 'open3'

include Open3


exit unless ENV["SHLVL"] == ?1


tmux_ls = capture3("tmux ls")

if tmux_ls.last.exitstatus.zero? then
  
  names = []
  puts "", tmux_ls.first.split("\n").map{|line|
    name = line[/([^:]+):/, 1]
    names << name
    "#{line} Prefix: #{`tmux show-options -t #{name} -g prefix`}"
  }.join("\n")

  print "\nwhich to attach? (e)xit or new tmux session >>"
  session = STDIN.gets.chomp

  exit if session =~ /^e/i

  print "\nSet Prefix key to >>"
  key = STDIN.gets.chomp

  `tmux new -d -s #{session}` unless names.include? session
  `tmux set -t #{session} -g prefix C-#{key}` unless key.empty?
  `tmux a -t #{session}`

end
