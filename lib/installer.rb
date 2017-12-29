require 'fileutils'
require 'pathname'
require 'yaml'

def install_sym(loc:nil, bk_dir:nil, bk_lst:nil, cur:nil)

  File.write(

    "#{cur}/#{bk_lst}",

    loc.inject({}){ |backup, (source_name, target_name)|

      dest = to_path(target_name)

      if File.exist? dest then

        FileUtils.mkdir("#{cur}/#{bk_dir}/") unless File.exist? "#{cur}/#{bk_dir}/"
        FileUtils.mv(dest, "#{cur}/#{bk_dir}/")
        backup[File.basename(target_name.to_s)] = dest

      end


      print "\nInstall #{dest} ? [y/n] >>"
      yn = STDIN.gets.chomp

      exit unless yn =~ /^y/

      FileUtils.symlink("#{cur}/#{source_name}", dest)
    
      backup
    }.to_yaml)

end


def uninstall_sym(loc:knil, bk_dir:nil, bk_lst:nil, cur:nil)

  #loc.inject({}){ |backup, (source_name, target_name)|
  dests = loc.values.map{|t| to_path(t) }
  puts "\n#{dests.join("\n")}\n"

    #dest = to_path(target_name)

  print "\033[33mUnInstall\033[0m them? [y/n] >>"
  yn = STDIN.gets.chomp

  exit unless yn =~ /^y/


  dests.each{ |dest| FileUtils.rm(dest) }

  YAML.load_file("#{cur}/#{bk_lst}").each{ |filename, to|
    FileUtils.mv("#{cur}/#{bk_dir}/#{filename}", to)
  }

  FileUtils.rm(bk_lst)

end
