#!/usr/bin/env ruby

# Generate user override of flatpak's exported .desktop with extra args
dir  = File.expand_path(File.dirname(__FILE__))
apps = ["/var/lib/flatpak", "#{ENV["HOME"]}/.local/share/flatpak"].map{|d| "#{d}/exports/share/applications" }

{
  "com.vivaldi.Vivaldi" => "--password-store=kwallet6",
}.each{|app, args|
  src = apps.map{|d| "#{d}/#{app}.desktop" }.find{|f| File.exist?(f) }
  next warn("WARNING: #{app}.desktop not found. Skip.") if src.nil?

  Dir::mkdir(dir + "/applications") unless File.exist?(dir + "/applications")
  File.write(dir + "/applications/#{app}.desktop",
    File.read(src).gsub(/^(Exec=.*? #{Regexp.escape(app)})(?= |$)/, "\\1 #{args}"))
}
