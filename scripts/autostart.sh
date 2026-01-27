#!/usr/bin/env bash

#konsole &
kitty &

sleep 10

audacity &
sleep 1

# pavucontrol &
# sleep 1

dolphin &
sleep 1

discord --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime &
GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus viber &
sleep 1

# pactl list sources
# pacmd load-module module-loopback latency_msec=5 source=alsa_input.pci-0000_00_1b.0.analog-stereo

# pactl list modules
# pactl unload-module モジュール番号


#mount $HOME/media/mizuho
$HOME/prjs/bin/mount-unionfs.sh
