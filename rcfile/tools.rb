require 'yaml'
require 'erb'
require 'pathname'


def export(s)
  return "" if s =~ /^\s+$/ or s.empty?

  case @type
  when :fish then
    "set -U fish_user_paths #{s.strip.gsub("\n", " ")} $fish_user_paths"
  when :zsh then
    "export PATH=#{s.strip.gsub("\n", ":")}:$PATH"
  else
    ""
  end
end

def tmux_select(file)
  case @type
  when :fish then
    "set -U fish_user_paths #{s.strip.gsub("\n", " ")} $fish_user_paths"
  when :zsh then
    "export PATH=#{s.strip.gsub("\n", ":")}:$PATH"
  else
    ""
  end
end

def to_fish(rc)
  rc
    .gsub(/^(\s+)*export\s+([^=]+)=(.+)$/, '\1set -x \2 \3') # convert export
    .gsub(/\$\{([^\{\}]+)\}/, '$\1')                         # ${var} -> $var
    .gsub(/\$\?/, '$status')                                 # $? -> $status
    .gsub(/\$(\(.+\))$/, '\1')                               # $(cmd) -> (cmd)
    .gsub(/;(?:\s)*(?:then|do)$/,"")                         # then, do -> ""
    .gsub(/((?:\s|\n)+)(?:fi|done)$/, '\1end')               # fi,done -> end
    .gsub(/^(\s+)*([^=\s]+)\+=\(\s+([^=\s]+)\s+\)$/, 
          '\1set \2 (string join " " \2 \3)')                # append to array
    .each_line.map{|line|
      if line =~ /(?:\s|\n)*if/ then
        line.gsub(/(\s+)!(\s+)/, '\1not\2')                                # ! -> not
      elsif line =~ /^(\s+)*read\s+(\w+)\\\?(.+)$/ then
        "#{$1}read -P #{$3} #{$2}\n"                           # read -P
      elsif line !~ /if/ then
        line.gsub(/^(\s+)*([^=]+)=(.+)$/, '\1set \2 \3')     # assign
      else
        line
      end
    }.join
end 

def to_zsh(rc)
  rc
end

def custom(cstm)
  @b.local_variable_set(:cstm, cstm.strip)
  common  = ERB.new(File.read("common.tmpl")).result(@b)
  final   = send(%{to_#{@type}}, *[common])
end
