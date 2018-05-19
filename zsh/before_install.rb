#!/usr/bin/env ruby

require 'yaml'
require 'erb'

require_relative '../lib/util'

unless File.exist?(`which vim`.chomp) then
  $stderr.puts <<-"WARN"
Vim not installed!!!!
Please install vim first
WARN
  exit(1)
end

vim = "$HOME"
#vimruntime = `locate vim`.split("\n").select{|line| line =~ /vim\d+$/}.first
vimruntime = safe_run_cmd("locate vim") {|ex|
  puts "#{ex.message}",""
  print "Where is vim runtime dir? >>"
  STDIN.gets.chomp
}.split("\n").select{|line| line =~ /vim\d+$/}.first

if vimruntime.nil? or vimruntime.empty? then
  $stderr.puts "$VIMRUNTIME is empty"
end

File.write("zshrc", ERB.new(File.read("zshrc.tmpl")).result(binding))
