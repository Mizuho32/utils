#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'open3'

installs = YAML.load_file "installs.yaml"

print "Enter your install cmd (e.g. apt-get install >> "
INSTALL = gets.chomp

def sys_install(name)
  existance = Open3.capture3 "which #{name}"
  return existance if existance.last.exitstatus.zero?

  if File.exist? name then
    cmd = "./#{name}"
  else
    cmd = %Q|sudo #{INSTALL} "#{name}"| 
  end
  r = Open3.capture3 cmd
  puts r[0..1].join("\n")
  r
end

print "Install common? >> "
if gets.chomp =~ /y(?:es)?/i then

  common = installs[:common].map{|name|
    puts "install #{name}..."
    r = sys_install(name)
    if r.last.exitstatus.zero? then
      true
    else
      r[0..1].join("\n")
    end
  }
  
  installs[:common].zip(common).each{|name,result|
    puts "#{name}\n  #{result.to_s}"
  }

end

puts <<-"LIST"
#{
  (dists = installs
    .keys[1..-1])
    .each_with_index
    .map{|el, i| "  #{i} #{el}" }
    .join("\n")
  }
LIST
print "Enter number >> "
distri = dists[gets.chomp.to_i]
unless distri.nil?  then
   dists = installs[distri].map{|name|
    puts "install #{name}..."
    r = sys_install(name)
    if r.last.exitstatus.zero? then
      true
    else
      r[0..1].join("\n")
    end
  }
  
  installs[distri].zip(dists).each{|name,result|
    puts "#{name}\n  #{result.to_s}"
  }
end
