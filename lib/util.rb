require 'pathname'
require 'open3'

module Util
  extend self

  # complement ${HOME}/path if path is relative
  def to_path(str)

    # path start without /
    path = if str =~ /^[^\/\$]/ then
      "#{ENV["HOME"]}/#{str}"
    else
      # Replace env var
      str.to_s.gsub(/\$\{?([_A-Z]+)\}?/){ ENV[$1] }
    end
    return Pathname(path)
  end
end

def safe_run_cmd(cmd, &block)
  begin
    r = Open3.capture3(cmd)
    return r[0..1].join("\n")
  rescue Errno::ENOENT => ex
    block.call(ex)
  end
end

def input(prompt, defvalue, &block)
  printf prompt, "(default:#{defvalue})"
  userinput = STDIN.gets.chomp

  userinput = defvalue if userinput.empty?
  userinput = block.call(userinput) if block_given?

  return userinput
end

def exclude_nums
  user = input("Nums >> ", "")
  nums = eval("[#{user}]")
  return exclude_nums unless nums.all? {|n| n.is_a?(Integer) and (n.positive? or n.zero?)}
  return nums
end

def exclude_files(type_files)
  ex = {}
  type_files.each {|type, files|
    puts "select files to NOT INSTALL for #{type}:"
    puts files.each_with_index.map {|name, i|
      "  #{i}: #{name.first} -> #{name.last}"
    }.join("\n")
    ex[type] = exclude_nums().map{|i| files.keys[i]}
  }
  ex.each {|type, exc| exc.each{|ex| type_files[type].delete ex}}
  type_files
end

$rand_chars = [*?0..?9, *?a..?z, *?A..?Z]
def rand_string(len)
  rand_chars_len = $rand_chars.size
  return 0.step(len).map{ $rand_chars[ (rand_chars_len*rand()).floor ] }.join
end
