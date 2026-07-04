#!/usr/bin/env bash

echo UnInstall $1
kwriteconfig6 --file kwinrc --group Plugins --key $(basename $1)Enabled false
kpackagetool6 --type KWin/Script -r $(basename $1)
qdbus6 org.kde.KWin /KWin reconfigure
