#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'open-uri'

print "Enter location >>"
s = STDIN.gets.chomp

YAML.load_file('loc.yaml')[:type][:sym].keys.each{|font|

  next if File.exist? f = font.to_s
  
  begin
    puts url = "http://#{s}/#{font}"
    File.binwrite(f, open(url).read)
  rescue Exception => ex
    puts ex.message
    puts url = "https://#{s}/#{font}"
    File.binwrite(f, open(url).read)
  end
}
