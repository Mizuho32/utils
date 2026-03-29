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

def loc_dearray(loc)
loc.map{|src, trg|
  trg = [trg] if trg.is_a?(String)
  trg = trg.map{|elm|
    if elm.is_a?(Hash) then
      elm.map{|kv| kv.map(&:to_s).join(?/) }
    else
      elm
    end

  }.flatten.map{ _1.to_s.to_sym }
  [src, trg]
}.inject([]){|acm, (src, targs)| targs.each{ acm << [src, _1] }.then{ acm } }
end

def exclude_files(type_files)
  ex = {}
  type_files = type_files.map {|type, files|
    files = loc_dearray(files)
    puts "select files to NOT INSTALL for #{type}:"
    puts files.each_with_index.map {|(src, trg), i|
      "  #{i}: #{src} -> #{trg}"
    }.join("\n")
    ex[type] = exclude_nums().map{|i| files.keys[i]}
    [type, files]
  }.to_h
  ex.each {|type, exc| exc.each{|ex| type_files[type].delete ex}}
  type_files
end

$rand_chars = [*?0..?9, *?a..?z, *?A..?Z]
def rand_string(len)
  rand_chars_len = $rand_chars.size
  return 0.step(len).map{ $rand_chars[ (rand_chars_len*rand()).floor ] }.join
end
