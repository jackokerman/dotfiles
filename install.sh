#!/bin/bash

# Check if bashdot is not already available, if not install it
if ! command -v bashdot &>/dev/null; then
  echo "bashdot not found, installing..."
  curl -s https://raw.githubusercontent.com/bashdot/bashdot/master/bashdot >bashdot
  sudo mv bashdot /usr/local/bin
  sudo chmod a+x /usr/local/bin/bashdot
  echo "bashdot installed successfully."
else
  echo "bashdot is already installed, skipping."
fi

# Install bashdot default profile
echo "Installing bashdot default profile..."
pushd ~/dotfiles
bashdot install default
popd
echo "bashdot default profile installed successfully."
