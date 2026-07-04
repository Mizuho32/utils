#!/usr/bin/env bash

echo Update $1
kpackagetool6 --type KWin/Script --upgrade $1
qdbus6 org.kde.KWin /KWin reconfigure
