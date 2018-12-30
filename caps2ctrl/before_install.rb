#!/usr/bin/env ruby

dir = File.expand_path(File.dirname(__FILE__))

File.write(dir + "/caps2ctrl.desktop", <<-"EOF"
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=caps2control
Comment=
Exec=xmodmap #{dir}/map
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
EOF
)
