require 'yaml'
require 'open3'
require 'time'
require 'pathname'

require 'remotestdio'

# ARGV conf.yaml
begin

RemoteSTDIOUtils.init_by_envvar()
home = Pathname("#{ENV['HOME']}")
cache_path = home / '.cache/backupper/last.txt'
config_path = Pathname(ARGV.first)

# cache gen or check
last_time = if not cache_path.exist? then
  cache_path.dirname.mkdir if not cache_path.dirname.exist?
  Time.now
else
  Time.parse(File.read(cache_path))
end

# Check interval
config = YAML.load_file(config_path)
interval = config[:interval] * (3600*24) # sec
starttime = Time.now
timedelta = starttime - last_time

if !(timedelta > interval) then
  exit 0
end


result = config[:paths].map{|path, cmd|
  fullpath = home / path.to_s
  Dir::chdir(fullpath)
  ret = Open3.capture3(cmd)
  [path,  cmd, *ret]
}.map{|path, cmd, out, err, status|
"""#{ if status.exitstatus.zero? then 'OK' else 'Err!' end} #{cmd} at #{path}
---
#{out}#{err}
---"""
}.join("\n")

puts """## Backupper #{Time.now.iso8601}
**Results:**
```
#{result}
```
"""


# last time cache
File.write(cache_path, starttime.iso8601)
rescue StandardError => ex
  puts(ex.message, ex.backtrace.join("\n"))
  exit 1
end
