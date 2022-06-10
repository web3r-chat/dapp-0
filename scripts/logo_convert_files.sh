#!/usr/bin/env bash

cd src/frontend/assets/logo 

echo "Converting logo files in:"
pwd
echo " "

for COLOR in black cyan green orange pink purple red white yellow
do
  echo '-------------------------------------'
  ls web3r.chat-logo.dracula-$COLOR.svg
  convert -background transparent -define icon:auto-resize=192 web3r.chat-logo.dracula-$COLOR.svg favicon.dracula-$COLOR.ico
  mv favicon.dracula-$COLOR.ico ../favicon/

  echo '-------------------------------------'
  ls web3r.chat-logo.dracula-$COLOR.png
  convert -background transparent -resize 16x16 web3r.chat-logo.dracula-$COLOR.png web3r.chat-logo.dracula-$COLOR.16x16.png
  convert -background transparent -resize 32x32 web3r.chat-logo.dracula-$COLOR.png web3r.chat-logo.dracula-$COLOR.32x32.png
  
done
