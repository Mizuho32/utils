#!/usr/bin/env ruby

require 'yaml'
require 'erb'

require_relative '../lib/util'
require_relative 'tools'

unless File.exist?(`which vim`.chomp) then
  $stderr.puts <<-"WARN"
Vim not installed!!!!
Please install vim first
WARN
  exit(1)
end

vim = "$HOME"
vimruntime = safe_run_cmd("locate vim") {|ex|
  puts "#{ex.message}",""
  print "Where is vim runtime dir? >>"
  STDIN.gets.chomp
}.split("\n").select{|line| line =~ /^(?!.*snap).*vim\d+$/}.first
rcfile_path = Pathname(__FILE__).expand_path.dirname


if vimruntime.nil? or vimruntime.empty? then
  $stderr.puts "$VIMRUNTIME is empty"
end

{
  zsh:  'zshrc',
  fish: 'config.fish'
}.each{|sh, bname|
  common = common(sh, binding)
  File.write(bname, ERB.new(File.read("#{bname}.tmpl")).result(binding))
}
