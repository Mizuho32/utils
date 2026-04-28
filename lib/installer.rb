require 'fileutils'
require 'pathname'
require 'yaml'

require_relative 'util'

if not defined? DEBUG and ENV.include?("DEBUG")
  DEBUG = true
  ENV["HOME"] = (Pathname(__FILE__).expand_path.dirname + "../home").to_s
  FileUtils.mkdir(ENV["HOME"]) if not File.exists?(ENV["HOME"])
end

def to_source_path(cur, source_name)
  source_name = source_name.to_s.strip

  source_name = source_name.gsub(/\$[_a-z0-9]+/i){ ENV[_1.sub(?$, '')].strip } if source_name.include?(?$)
  if source_name[0] == ?/ then
    return Pathname(source_name)
  else
    return Pathname(cur) / source_name
  end
end

def check_link(cur, source_name, target_name)
  source_path = to_source_path(cur, source_name)
  target_path = Util.to_path(target_name)

  return target_path if source_path.exist? && target_path.symlink? && target_path.readlink.exist?


  unless source_path.exist? then
    STDERR.puts "#{source_path} doesn't exist!!"
  else
    return target_path unless target_path.symlink? # source OK, no target
  end

  return false unless target_path.symlink?

  link = target_path.readlink
  unless link.exist? then
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
      FileUtils.rm(target_path) if target_path.symlink?
      FileUtils.symlink(source_path, target_path)
    end
  end

  return false
end

      

def install_sym(loc:nil, bk_dir:nil, bk_lst:nil, cur:nil)
  cur_dir = Pathname(cur)
  backup_yaml_path = cur_dir / bk_lst
  backup_init = if backup_yaml_path.exist? then YAML.load_file(backup_yaml_path) else {} end

  File.write(
    backup_yaml_path,

    loc.inject(backup_init){ |backup, (source_name, target_name)|
      dest = check_link(cur, source_name, target_name)
      next backup unless dest
      if dest.symlink? && (red_link = dest.readlink).exist? then
        puts("#{dest} -> #{red_link} already exists and alive. Skip")
        next backup 
      end

      #dest = Util.to_path(target_name)
      backup_dir = cur_dir / bk_dir

      # backup
      print "\nInstall #{dest}"

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

      dest_parent = Pathname(dest).expand_path.parent
      FileUtils.mkdir_p(dest_parent) unless dest_parent.exist?
      FileUtils.symlink(to_source_path(cur, source_name), dest)
    
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
    if dest.exist? then
      if dest.symlink? then
        FileUtils.rm(dest)
      else
        warn("WARNING: #{dest} is not symlink! Skip.") if !dest.symlink?
      end
    end
  }

  YAML.load_file("#{cur}/#{bk_lst}").each{ |filename, to|
    src_path = Pathname("#{cur}/#{bk_dir}/#{filename}")

    next(warn("#{to} already exists! Skip")) if File.exist?(to)
    next(warn("#{src_path} not exists! Skip")) if !src_path.exist?
    FileUtils.mv(src_path, to)
  }

  FileUtils.rm(bk_lst)

end


def hire_select_dir(utils_dir, files)
  n_files = files.size
  subdirs = utils_dir.children.select{ _1.directory? && !(_1.basename.to_s.start_with?(".")) && (_1/ 'loc.yaml').exist? }.sort_by(&:to_s)

  loop {
    puts "\nSelect dirs for files"
    puts "Files:\n#{files.map{ " #{_1}"}.join("\n")}"
    puts "Dirs:\n#{subdirs.each_with_index.map{|el, idx| " #{'%2d' % idx}: #{el}"}.join("\n")}"

    dests = gets.chomp.split(/[^0-9]+/).map(&:to_i).map{|i| subdirs[i]}.compact
    n_dests = dests.size
    if n_dests.zero? then
      puts("select at least one dir")
      next
    elsif n_dests > n_files then
      puts("too many dirs selected")
      next
    elsif 1 < n_dests && n_dests < n_files then
      puts("too few dirs selected")
      next
    end

    dests = dests * n_files if n_dests == 1
    pairs = files.zip(dests)

    puts "Selected dirs:\n#{pairs.map{ " #{_1} -> #{_2}"}.join("\n")}"
    print "OK? [y/n] >>"
    yn = STDIN.gets.chomp

    return pairs.map{[_1.expand_path, _2]} if yn =~ /^y/i
  }
end
