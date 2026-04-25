require 'yaml'
require 'open3'
require 'time'
require 'pathname'

begin
  require 'load_remotestdio'; rescue LoadError
  $stderr.puts "WARN: No remotestdio"
end


# ARGV conf.yaml
begin

home = Pathname("#{ENV['HOME']}")
cache_path = home / '.cache/backupper/last.yaml'
config_path = Pathname(ARGV.delete_at(0))
debug_mode = ENV['DEBUG']

# cache dir gen or check
last_times = if not cache_path.exist? then
  cache_path.dirname.mkdir if not cache_path.dirname.exist?
  {}
else
  YAML.load_file(cache_path, permitted_classes: [Time, Symbol], aliases: true)
end

# Check interval
config = YAML
  .load_file(config_path)
  .then{|conf|
    # Envs
    conf[:envs]&.each{|env_name, env_val| ENV[env_name.to_s] = env_val }
    conf
  }
  .then{|conf|
    global_interval = conf[:interval]
    conf[:paths] = conf[:paths].map{|path, cmd|
      next [path, {interval: global_interval, cmd: cmd}] if cmd.is_a? String
      [path, cmd]
    }.to_h
    conf
  }

current_time = Time.now
result = config[:paths]
  .map{|path, cmd_info|
    interval = cmd_info[:interval] * (3600*24) # sec
    first_time = last_times[path].nil?
    last_time = !first_time && last_times[path]

    next nil if !first_time && (current_time - last_time) <= interval

    fullpath = home / path.to_s
    Dir::chdir(fullpath)
    cmd = cmd_info[:cmd]
    cmd = "echo #{cmd}" if debug_mode
    ret = Open3.capture3(cmd)
    [path,  cmd, *ret]
  }
  .compact

result_text = result
  .map{|path, cmd, out, err, status|
    fullpath = home / path.to_s
"""#{ if status.exitstatus.zero? then 'OK' else 'Err!' end} '#{cmd}' at '#{fullpath}'
---
#{ "#{out}#{err}".strip }
---"""
  }.join("\n\n")

unless result.empty?
  puts """## Backupper #{Time.now.iso8601}
**Results:**
````
#{result_text}
````
"""

  # last time cache
  result
    .select{|path, cmd, out, err, status| status.exitstatus.zero? }
    .each{|path, _|
      last_times[path] = current_time
    }
  File.write(cache_path, last_times.to_yaml)
end
rescue StandardError => ex
  puts(ex.message, ex.backtrace.join("\n"))
  exit 1
end
