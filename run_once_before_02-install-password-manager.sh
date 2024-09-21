#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034,SC1090
set -eu

# {{ if eq .chezmoi.os "linux" -}}
# curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
#  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
#  sudo tee /etc/apt/sources.list.d/1password.list

# sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
# curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
#  sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
# sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
# curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
#  sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# sudo apt update && sudo apt install 1password-cli

# ARCH="amd64" && \
#     wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.7.3/op_linux_${ARCH}_v2.7.3.zip" -O op.zip && \
#     unzip -d op op.zip && \
#     sudo mv op/op /usr/local/bin && \
#     rm -r op.zip op

# # {{ else if eq .chezmoi.os "darwin" -}}
# # brew install --cask 1password/tap/1password-cli
# # {{ end -}}

# op account add --address the-lauer-family.1password.com --email lauer.aaron@gmail.com 
# eval $(op signin --account the-lauer-family.1password.com)