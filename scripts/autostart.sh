#!/usr/bin/env bash

sleep 10

audacity &
sleep 1

pavucontrol &
sleep 1

thunar &
sleep 1

konsole &
sleep 1

# pactl list sources
pacmd load-module module-loopback latency_msec=5 source=alsa_input.pci-0000_00_1b.0.analog-stereo

# pactl list modules
# pactl unload-module モジュール番号


#mount $HOME/media/mizuho
