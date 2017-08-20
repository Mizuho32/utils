require 'fileutils'
require 'pathname'
require 'yaml'

def install_sym(source_name:nil, target_name:nil, dest:nil, bk_dir:nil, bk_lst:nil, cur:nil)

	if File.exist? dest then

		FileUtils.mkdir("#{cur}/#{bk_dir}/") unless File.exist? "#{cur}/#{bk_dir}/"
		FileUtils.mv(dest, "#{cur}/#{bk_dir}/")
		File.write("#{cur}/#{bk_lst}", { target_name => dest }.to_yaml)

	end


	print "\nInstall #{dest} ? [y/n] >>"
	yn = STDIN.gets.chomp

	exit unless yn =~ /^y/

	FileUtils.symlink("#{cur}/#{source_name}", dest)

end
