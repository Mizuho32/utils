require 'fileutils'
require 'pathname'
require 'yaml'

require_relative 'util'

if not defined? DEBUG and ENV.include?("DEBUG")
  DEBUG = true
  ENV["HOME"] = (Pathname(__FILE__).expand_path.dirname + "../home").to_s
  FileUtils.mkdir(ENV["HOME"]) if not File.exists?(ENV["HOME"])
end

def update_sym(loc:nil, bk_dir:nil, bk_lst:nil, cur:nil)

  loc.each{ |source_name, target_name|
    source_path = "#{cur}/#{source_name}"

    unless File.exist? source_path then
      STDERR.puts "#{source_path} doesn't exist!!"
    end

    target_path = Util.to_path(target_name)
    unless File.symlink? target_path then
      STDERR.puts "#{target_path} doesn't exist!!"
      print "update? >>"
      if STDIN.gets.chomp =~ /^y/ then
        FileUtils.symlink(source_path, target_path)
      else
        next
      end
    end

    link = File.readlink(target_path)
    unless File.exist? link then

      STDERR.puts "link:\n#{target_path} -> #{link}\ndead!"
      print "remove? >>"
      if STDIN.gets.chomp =~ /^y/ then
        FileUtils.rm(target_path)
      end

    end

    unless link == source_path then

      STDERR.puts "link path:\n#{target_path} -> #{link}\nand source in loc.yaml:\n#{source_path} does not match!"
      print "update? >>"
      if STDIN.gets.chomp =~ /^y/ then
        FileUtils.rm(target_path) if symlink?(target_path)
        FileUtils.symlink(source_path, target_path)
      end

    end
  }
end

      

def install_sym(loc:nil, bk_dir:nil, bk_lst:nil, cur:nil)
  cur_dir = Pathname(cur)

  File.write(
    cur_dir / bk_lst,

    loc.inject({}){ |backup, (source_name, target_name)|

      dest = Util.to_path(target_name)
      backup_dir = cur_dir / bk_dir

      # backup
      if dest.exist? then
        FileUtils.mkdir(backup_dir) unless backup_dir.exist?
        backup_name = [dest.basename(dest.extname).to_s, rand_string(4)].join(?_) + dest.extname
        begin
          backup_path = backup_dir / backup_name
          throw RuntimeError.new("#{backup_path} exists!") if backup_path.exist?
          FileUtils.mv(dest, backup_path)
          backup[backup_name] = dest.to_s
        rescue ArgumentError => ex
          STDERR.puts "#{__FILE__}:#{__LINE__}:#{ex.message}"
          next backup
        end
      end

      print "\nInstall #{dest}"

      dest_parent = Pathname(dest).expand_path.parent
      FileUtils.mkdir_p(dest_parent) unless dest_parent.exist?
      FileUtils.symlink(cur_dir / source_name.to_s, dest)
    
      backup
    }.to_yaml)

end


def uninstall_sym(loc:knil, bk_dir:nil, bk_lst:nil, cur:nil)

  dests = loc.values.map{|t| Util.to_path(t) }
  puts "\n#{dests.join("\n")}\n"

  print "\033[33mUnInstall\033[0m them? [y/n] >>"
  yn = STDIN.gets.chomp

  exit unless yn =~ /^y/


  dests.each{ |dest|
    throw RuntimeError.new("#{dest} is not symlink") if !dest.symlink?
    FileUtils.rm(dest) if dest.exist?
  }

  YAML.load_file("#{cur}/#{bk_lst}").each{ |filename, to|
    FileUtils.mv("#{cur}/#{bk_dir}/#{filename}", to)
  }

  FileUtils.rm(bk_lst)

end
