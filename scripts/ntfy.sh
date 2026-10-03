#!/usr/bin/env bash

if command -V curl > /dev/null; then
  curl \
    -H "Authorization: Bearer ${Token}" \
    -H "X-Title: ${Title}" \
    -d "${Body}" \
    "${Topic}"
fi
