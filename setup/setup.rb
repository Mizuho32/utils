#!/usr/bin/env ruby
# coding: utf-8

require 'yaml'
require 'open3'

require_relative "../lib/util"

def check_existance(name)
  existance = Open3.capture3 "which #{name}"

  if existance.last.exitstatus.zero?
    return existance 
  else
    # detect package checker command
    cand = [%w[dpkg -L], %w[yay -Qe]]
    @checker = (cand.select{|cmd| 
      `which #{cmd.first} >> /dev/null 2>&1`
      $?.exitstatus.zero?
    }.first || []).join(" ")

    if @checker.empty?
      print 
"""The existance of #{name} not solved automatically
Enter the cmd name to check installed? >>"""
      @checker = STDIN.gets.chomp
    end

    puts "run #{@checker} #{name}"
    system "#{@checker} #{name}"
    return [nil,nil,$?] if $?.exitstatus.zero?
  end
end

def sys_install(name)
  name = name.strip
  existance = check_existance(name)
  return existance unless existance.nil?

  if File.exist? "./custom/#{name}" then
    cmd = "./custom/#{name}"
  else
    cmd = %Q|#{INSTALL} "#{name}"| 
  end
  puts "in #{ENV["PWD"]}, exec #{cmd}"
  system cmd
  return [nil,nil,$?]
  $?
end

installs = YAML.safe_load_file("installs.yaml", permitted_classes: [Symbol], aliases: true)

cand = [%w[apt install], %w[apt-get install], %w[yum install], %w[yay -S]]

tmp = cand.select{|cmd| 
  `which #{cmd.first} >> /dev/null 2>&1`
  $?.exitstatus.zero?
}.first || %w[none]

INSTALL = input(%Q{"#{cmd=tmp.join(" ")}" is your install cmd? %s or Enter your install cmd (e.g. apt-get install) >> }, "yes") {|user|
  if user =~ /^y(?:es)?/i then
    cmd
  else
    user
  end
}

input("Install common? %s >> ", "yes"){|line|
  if line.chomp =~ /y(?:es)?/i then

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
}

puts <<-"LIST"
#{
  (dists = installs.keys.tap{|ar| ar.delete :common})
    .each_with_index
    .map{|el, i| "  #{i} #{el}" }
    .join("\n")
  }
  #{installs.keys.size} cancel
LIST

print "\nDistribution dependent\nEnter number >> "
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
