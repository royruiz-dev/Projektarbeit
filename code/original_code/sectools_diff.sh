#!/bin/bash

# source necessary code from other scripts
PROGDIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
INV_FILE="$PROGDIR/../../docs/ansible/inventory.json"

jq --exit-status --sort-keys '
    ._meta.hostvars // {} | to_entries | map(
    .diff = {} |
        ((.value.x_installed_sectools // []) - (.value.x_cms_sectools // [])) as $not_req |
        ((.value.x_cms_sectools // []) - (.value.x_installed_sectools // [])) as $not_inst |
        if (($not_req | length) > 0 and .value.ansible_host) then .diff.not_required = $not_req else . end |
        if (($not_inst | length) > 0 and .value.ansible_host) then .diff.not_installed = $not_inst else . end |
        if .diff == {} then empty else (.diff + {hostname: .key}) end ) |
    if length == 0 then empty else . end
' "$INV_FILE" && exit 133 || exit 0