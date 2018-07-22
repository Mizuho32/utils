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
vimruntime = `locate vim`.split("\n").select{|line| line =~ /vim\d+$/}.first
rcfile_path = Pathname(__FILE__).expand_path.dirname

if vimruntime.nil? or vimruntime.empty? then
  $stderr.puts "$VIMRUNTIME is empty"
end

{
  zsh:  :zshrc
  fish: :'config.fish'
}.each{|sh, bname|
  common = common(sh, binding)
  File.write(bname, ERB.new(File.read("#{sh}.tmpl")).result(binding))
}
