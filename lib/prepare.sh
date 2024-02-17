#!/usr/bin/env bash

if [ ! -f ./.config ]; then
    echo "Please create .config file first."
    exit 1
fi
source ./.config

declare -x -r NIX_BUILD_CORES="${NIX_BUILD_CORES}"
declare -x -r TARGET_HOSTNAME="${TARGET_HOSTNAME}"
declare -x -r WIFI_SSID="${WIFI_SSID}"
declare -x -r WIFI_PSK="${WIFI_PSK}"
declare -x -r WIFI_COUNTRY_S="country=${WIFI_COUNTRY}"
