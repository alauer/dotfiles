#!/usr/bin/env bash
set -euo pipefail

asset_dir="${HOME}/.local/share/jeeves/desktop-assets/jeeves-cyber-mesh/v1"
base_url="https://d2qo7z0pyues99.cloudfront.net/desktop_assets/jeeves-cyber-mesh/v1"
mkdir -p "${asset_dir}"

download_verified() {
    local name="$1"
    local expected_sha256="$2"
    local destination="${asset_dir}/${name}"
    local temporary

    if [[ -f "${destination}" ]] && printf '%s  %s\n' "${expected_sha256}" "${destination}" | sha256sum --check --status; then
        return 0
    fi

    temporary="$(mktemp "${asset_dir}/.${name}.XXXXXX")"
    trap 'rm -f "${temporary}"' RETURN
    curl --fail --location --silent --show-error "${base_url}/${name}" --output "${temporary}"
    printf '%s  %s\n' "${expected_sha256}" "${temporary}" | sha256sum --check --status
    chmod 0644 "${temporary}"
    mv -f "${temporary}" "${destination}"
    trap - RETURN
}

download_verified "ambient-loop.mp4" "46013bedc92ad4e872554e53378f59c4b23fbf061cf0db50e68e208b86789917"
download_verified "alternate-loop.mp4" "892cddcf81a90aacc1d4d06a0d16d5e84724852f94f184cfeb360845ddd95b18"
download_verified "control-room.png" "05306383dd0ee4a3eb23ada0554d7c96f4d1a658f8007c0006418e54982e5353"
