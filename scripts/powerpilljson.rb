#!/usr/bin/env ruby
require 'json'
require 'yaml'

# input: /etc/pacman.d/mirrorlist
# https://wiki.browniealice.net/technote/arch/yay/

ppjson = YAML.load_file "/etc/powerpill/powerpill.json"
ppjson["rsync"]["servers"] = File.read("/etc/pacman.d/mirrorlist").split("\n").select{|line| line =~ /^Server/}
puts JSON.pretty_generate(ppjson)

