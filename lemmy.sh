#!/usr/bin/env bash
set -Eeuo pipefail

lemmy-help -f lua/anki/init.lua >doc/anki.nvim.txt
