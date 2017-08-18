#!/usr/bin/env ruby
# coding: utf-8

require 'fileutils'
require 'pathname'
require 'yaml'

SOURCE_NAME = "zshrc"
TARGET_NAME = ".zshrc"
DEST 				= "#{ENV['HOME']}/#{TARGET_NAME}"
BK_DIR 			= "backups"
BK_LST 			= "backups.yaml"
CUR  				= Pathname(__FILE__).realpath.dirname


print "\nUnInstall #{DEST} ? [y/n] >>"
yn = STDIN.gets.chomp

exit unless yn =~ /^y/

FileUtils.rm(DEST)


YAML.load_file("#{CUR}/#{BK_LST}").each{|filename, to|
	FileUtils.mv("#{CUR}/#{BK_DIR}/#{filename}", to)
}
