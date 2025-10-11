#!/usr/bin/env ruby

require 'pathname'

pkg_dir = Pathname('/var/cache/pacman/pkg')
move_to = ARGV[0]

version_regex = /(?<version>.+)/
files = pkg_dir.glob("*.zst")

moves = files.group_by{|file|
  m = file.basename.to_s.match(%r/(?<name>[^.]+)-#{version_regex}-/)
  m[:name]
}.tap{|grouped| puts "# #{grouped.size} pkgs" }.map{|name, pkgs|
  pkgs.map(&:to_s).sort.reverse[1..].each_with_index.map{|pkg, idx|
    {type: (idx.zero? && :mv || :del), pkg: pkg}
  }
}.flatten

# puts pkg_grouped.keys[..20]
stat = moves.group_by{ _1[:type] }.map{|type, pkgs| "#{type}: #{pkgs.size}"}.join(", ")
exit if moves.empty?

puts "# Stat:  #{stat}"

chown = "#{%x(id -u).strip}:#{%x(id -g).strip}"

puts moves.map{|pkg_with_cmd|
  pkg = pkg_with_cmd[:pkg]
  cmd = pkg_with_cmd[:type]
  if cmd == :mv
    "sudo chown #{chown} #{pkg}*
sudo mv #{pkg}* /tmp/
mv -n /tmp/#{Pathname(pkg).basename}* #{move_to} || rm /tmp/#{Pathname(pkg).basename}*"
  else
    "sudo rm #{pkg}*"
  end
}.join("\n")
