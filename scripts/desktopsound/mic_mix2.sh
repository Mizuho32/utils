#!/bin/bash

microphone="alsa_input.usb-SHEM-BOY_SHEM-BOY_20190805V001-00.iec958-stereoalsa_input.pci-0000_00_1b.0.analog-stereo"
speakers="alsa_output.usb-SHEM-BOY_SHEM-BOY_20190805V001-00.analog-stereo"
#speakers="bluez_sink.F8_54_B8_4D_E0_4D.a2dp_sink"

#echo "Setting up echo cancellation"
#pactl load-module module-echo-cancel use_master_format=1 aec_method=webrtc \
#      aec_args="analog_gain_control=0\\ digital_gain_control=1\\ experimental_agc=1\\ noise_suppression=1\\ voice_detection=1\\ extended_filter=1" \
#      source_master="$microphone" source_name=src_ec  source_properties=device.description=src_ec \
#      sink_master="$speakers"     sink_name=sink_main sink_properties=device.description=sink_main

src_ec="alsa_input.usb-SHEM-BOY_SHEM-BOY_20190805V001-00.iec958-stereo.echo-cancel"
sink_main="bluez_sink.F8_54_B8_4D_E0_4D.a2dp_sink"

echo "Creating virtual output devices"
pactl load-module module-null-sink sink_name=sink_fx  sink_properties=device.description=sink_fx
pactl load-module module-null-sink sink_name=sink_mix sink_properties=device.description=sink_mix

echo "Creating remaps"
pactl load-module module-remap-source master=sink_mix.monitor \
      source_name=src_main source_properties="device.description=src_main"

echo "Setting default devices"
pactl set-default-source src_main
pactl set-default-sink   "$sink_main"

echo "Creating loopbacks"
pactl load-module module-loopback latency_msec=60 adjust_time=6 source="$src_ec"       sink=sink_mix
pactl load-module module-loopback latency_msec=60 adjust_time=6 source=sink_fx.monitor sink=sink_mix
pactl load-module module-loopback latency_msec=60 adjust_time=6 source=sink_fx.monitor sink="$sink_main"

#systemctl --user restart pulseaudio.service 
# pactl list  sinks | grep "echo-cancel"
# pactl list sources | grep "echo-cancel" -A 2 
# https://matoken.org/blog/2020/05/01/pulseaudios-echo-cancellation-module-for-linux-looks-good/
# https://wiki.archlinux.jp/index.php/PulseAudio/%E3%82%B5%E3%83%B3%E3%83%97%E3%83%AB#.E8.BF.BD.E5.8A.A0.E3.81.AE.E3.82.AA.E3.83.BC.E3.83.87.E3.82.A3.E3.82.AA.E3.82.92.E3.83.9E.E3.82.A4.E3.82.AF.E3.81.AE.E3.82.AA.E3.83.BC.E3.83.87.E3.82.A3.E3.82.AA.E3.81.AB.E3.83.9F.E3.82.AD.E3.82.B7.E3.83.B3.E3.82.B0.E3.81.99.E3.82.8B
