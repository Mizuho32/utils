
def to_path(str)

	if str =~ /^[^\/]/ then
		"#{ENV["HOME"]}/#{str}"
	else
		str.gsub(/\$\{?([A-Z]+)\}?/){ ENV[$1] }
	end

end

