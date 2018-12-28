require 'open3'

# complement ${HOME}/path if path is relative
def to_path(str)

	if str =~ /^[^\/]/ then
		"#{ENV["HOME"]}/#{str}"
	else
		str.gsub(/\$\{?([A-Z]+)\}?/){ ENV[$1] }
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
