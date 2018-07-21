#!/usr/bin/env ruby

require 'yaml'
require 'erb'

unless File.exist?(`which vim`.chomp) then
  $stderr.puts <<-"WARN"
Vim not installed!!!!
Please install vim first
WARN
  exit(1)
end

vim = "$HOME"
vimruntime = `locate vim`.split("\n").select{|line| line =~ /^(?!.*snap).*vim\d+$/}.first

if vimruntime.nil? or vimruntime.empty? then
  $stderr.puts "$VIMRUNTIME is empty"
end

File.write("zshrc", ERB.new(File.read("zshrc.tmpl")).result(binding))
