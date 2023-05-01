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
sink_main="alsa_output.usb-SHEM-BOY_SHEM-BOY_20190805V001-00.analog-stereo.echo-cancel"

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
