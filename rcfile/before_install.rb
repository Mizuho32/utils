#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'open-uri'

require_relative '../lib/util'
require_relative 'tools'

unless File.exist?(`which vim`.chomp) then
  $stderr.puts <<-"WARN"
Vim not installed!!!!
Please install vim first
WARN
  exit(1)
end

# vim location
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

# Download fish completions
Dir::mkdir(rcfile_path+"fish/completions/") unless File.exist?(rcfile_path+"fish/completions/")

version = `fish --version`[/(\d\.\d\.\d)/, 1]
base = "https://raw.githubusercontent.com/fish-shell/fish-shell/Integration_#{version}/share/completions/"

loc = YAML.load_file(rcfile_path + "loc.yaml")
loc[:type][:sym]
  .map{|file, sym| file.match /fish\/completions\/(?<filename>[^\.]+\.fish)/}
  .compact
  .map{|match| match[:filename] }
  .each{|filename|  
    url = "#{base}#{filename}"
    File.write(rcfile_path+"fish/completions/#{filename}", open(url).read)
  }

# tmux prefix-key
key = File.read(rcfile_path + "../tmux/tmux.conf")[/prefix\s+C-(\w)/, 1]
puts "tmux key if #{key}"

# rcfile generaion
{
  zsh:  'zshrc',
  fish: 'config.fish'
}.each{|sh, bname|
  @type = sh
  @b    = binding
  File.write(bname, ERB.new(File.read("#{bname}.tmpl")).result(binding))
}
