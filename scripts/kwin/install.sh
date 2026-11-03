#!/usr/bin/env bash

echo Install $1
kpackagetool6 --type KWin/Script -i $1
kwriteconfig6 --file kwinrc --group Plugins --key $(basename $1)Enabled true
qdbus6 org.kde.KWin /KWin reconfigure
