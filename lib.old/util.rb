require 'open3'

# complement ${HOME}/path if path is relative
def to_path(str)

	if str =~ /^[^\/]/ then
		"#{ENV["HOME"]}/#{str}"
	else
    str.to_s.gsub(/\$\{?([A-Z]+)\}?/){ ENV[$1] }
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
