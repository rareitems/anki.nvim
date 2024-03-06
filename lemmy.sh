#!/usr/bin/env bash
set -Eeuo pipefail

lemmy-help -f lua/anki/init.lua >doc/anki.nvim.txt

# printf '*anki.nvim.txt*\n*anki* *anki.nvim*\n' | cat - doc/anki.nvim.txt > temp && mv temp doc/anki.nvim.txt
