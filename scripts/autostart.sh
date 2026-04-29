#!/usr/bin/env bash

#konsole &
#kitty &
# like: bash -c 'startprefix -c 'cmds';startprefix'
# for s in  system apps remotes; tmuxinator start $s --no-attach; end # launch sessions
kitty bash -c '$HOME/bin/startprefix -c '"'"'for s in system apps remotes;tmuxinator start $s --no-attach; end'"'"';$HOME/bin/startprefix'&

sleep 10

flatpak run md.obsidian.Obsidian&
sleep 1

#audacity &
flatpak run org.audacityteam.Audacity&
sleep 1

# pavucontrol &
flatpak run org.pulseaudio.pavucontrol&
sleep 1

dolphin &
sleep 1

#discord --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime &
#GTK_IM_MODULE=ibus QT_IM_MODULE=ibus XMODIFIERS=@im=ibus viber &
flatpak run com.discordapp.Discord&
flatpak run com.viber.Viber&
sleep 1

# pactl list sources
# pacmd load-module module-loopback latency_msec=5 source=alsa_input.pci-0000_00_1b.0.analog-stereo
if ! [[ "$(pactl list short sinks)" = *"bt_record"* ]]; then
  pactl load-module module-null-sink \
    sink_name=bt_record \
    sink_properties=device.description=Bluetooth_Record
fi

# pactl list modules
# pactl unload-module モジュール番号


#mount $HOME/media/mizuho
$HOME/prjs/bin/mount-unionfs.sh
