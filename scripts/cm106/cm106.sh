#!/bin/sh
target='USB_Sound'

cd /sys/class/hidraw || exit
for dev in *; do
   set "$dev"/device/input/*/name
   read name <"$1"
   if [ "$name" = "USB Sound Device" ]; then
      echo "enabling SPDIFMIX on $dev of $name"
      #printf "\000\040\001\260\001" >/dev/"$dev"

      # Change output card
      index=$(pacmd list-sinks | tr -d '*' | grep -e 'name:' -e 'index:' | grep ${target} -B1 | grep -e 'index:' | awk '{print $2}')

      pacmd set-default-sink $index
      for stream_id in $(pactl list short sink-inputs | awk '{print $1}')
      do
        #echo $stream_id
        pactl move-sink-input $stream_id $index
      done

      # Optical ON
      # ReqID 00, Write 20, Default Value b000, Address 01
      perl -e 'print pack "H*", "002000b001"' | sudo tee /dev/"$dev"

      # Read e.g.
      # sudo dd if=/dev/hidraw0 bs=32 count=1 | hexdump -C
      # perl -e 'print pack "H*", "0030000001"' | sudo tee /dev/hidraw0
   fi
done

