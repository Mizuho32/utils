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


if File.exist? DEST then

	FileUtils.mkdir("#{CUR}/#{BK_DIR}/") unless File.exist? "#{CUR}/#{BK_DIR}/"
	FileUtils.mv(DEST, "#{CUR}/#{BK_DIR}/")
	File.write("#{CUR}/#{BK_LST}", { TARGET_NAME => DEST }.to_yaml)

end


print "\nInstall #{DEST} ? [y/n] >>"
yn = STDIN.gets.chomp

exit unless yn =~ /^y/

FileUtils.symlink("#{CUR}/#{SOURCE_NAME}", DEST)
