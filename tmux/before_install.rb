#!/usr/bin/env ruby

require 'yaml'
require 'erb'
require 'fileutils'

require_relative '../lib/host'

tmux_version = `tmux -V`[/(\d+\.\d+)/, 1].to_f
COND         = 2.4

host_dir = Host.dir(__dir__)
vars     = Host.vars(__dir__)

# first install on this host: ask and save to hosts/<hostname>/tmux/vars.yaml
if vars.nil? then
  print "Enter key prefix [a-z] (default: f) >>"
  key = if (k = gets.chomp).empty? then
          ?f
        else
          k
        end

  print "Enter shell (default: bash) >>"
  shell = if (s = gets.chomp).empty? then
          "bash"
        else
          s
        end

  vars = {"prefix" => key, "shell" => shell}
  FileUtils.mkdir_p(host_dir)
  File.write(host_dir / "vars.yaml", vars.to_yaml)
  puts "saved #{host_dir / "vars.yaml"}"
end

key   = vars["prefix"]
shell = vars["shell"]

puts "tmux version #{tmux_version}"

# plugins: tmux-resurrect + tmux-continuum (session save/restore)
tmux_dir = File.expand_path(__dir__)
%w[tmux-resurrect tmux-continuum].each{|name|
  dst = "#{tmux_dir}/plugins/#{name}"
  system("git", "clone", "https://github.com/tmux-plugins/#{name}", dst) unless File.exist?(dst)
} if vars["resurrect"]

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
