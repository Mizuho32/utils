#!/usr/bin/env bash

konsole &

sleep 10

audacity &
sleep 1

# pavucontrol &
# sleep 1

thunar &
sleep 1

discord &
viber &
sleep 1

# pactl list sources
# pacmd load-module module-loopback latency_msec=5 source=alsa_input.pci-0000_00_1b.0.analog-stereo

# pactl list modules
# pactl unload-module モジュール番号


#mount $HOME/media/mizuho
$HOME/prjs/bin/mount-unionfs.sh

cd $HOME/prjs/RubyTools/share_tmux_copy
bash launch.sh
