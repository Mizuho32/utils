require 'yaml'
require 'erb'
require 'pathname'


def export(s)
  return "" if s =~ /\s+/ or s.empty?

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
    .gsub(/^(\s+)*export\s+([^=]+)=(.+)$/, '\1set -x \2 \3')
    .gsub(/\$\{([^\{\}]+)\}/, '$\1')
    .gsub(/;(?:\s)*then$/,"")
    .gsub(/((?:\s|\n)+)fi$/, '\1end')
end 
def to_zsh(rc)
  rc
end

def common(type, b)
  @type   = type
  common  = ERB.new(File.read("common.tmpl")).result(b)
  final   = send(%{to_#{type}}, *[common])
end
