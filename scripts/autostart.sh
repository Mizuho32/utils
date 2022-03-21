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

pacmd load-module module-loopback latency_msec=5
