#!/bin/bash

function main() {
    . "./util.sh"

    if [ ! -d ${path_xkb} ]; then
        echo "There is no directory \"${path_xkb}\". Open util.sh and set XKB path."
        exit 0
    fi

    any_change=0
    bak_subdir="un"

    remove_variant "base" "xml"
    remove_variant "base" "lst"
    remove_variant "evdev" "xml"
    remove_variant "evdev" "lst"

    remove_keymap

    for h in $(find /home -maxdepth 1 -type d)
    do
        if [ ${h} == "/home" ]; then
            h="/root"
        fi

        remove_compose "${h}"
    done

    if [ ${any_change} -ne 0 ]; then
        echo "The \"${variant_desc}\" keyboard layout has been uninstalled successfully."
        echo "Run \"reboot\" to restart the Operating System."
    else
        echo "The \"${variant_desc}\" keyboard layout is not installed. Nothing changed."
    fi
}

function remove_variant() {
    local rule_name=$1
    local format=$2
    local rule_file="${path_rules}/${rule_name}.${format}"
    local variant_file="./variant.${format}"
    local lc_variant=$(cat "${variant_file}" | wc -l)
    local desc_ln_in_variant=$(get_line_containing "@d" "${variant_file}")
    local desc_ln_in_rule_file=$(get_line_containing "${variant_desc}" "${rule_file}")

    if [ -n "${desc_ln_in_rule_file}" ]; then
        printf "Removing \"${variant_desc}\" variant from \"${rule_file}\"..."

        local bak_file=$(get_backup_file "${bak_subdir}" "${rule_file}")
        cp "${rule_file}" "${bak_file}"

        { head -n $((desc_ln_in_rule_file-desc_ln_in_variant)) "${bak_file}"; \
          tail -n +$((desc_ln_in_rule_file+lc_variant-desc_ln_in_variant+1)) "${bak_file}"; } > "${rule_file}"

        if [ $? -eq 0 ]; then
            any_change=1
        fi

        echo "Done"
    else
        echo "There is no \"${variant_desc}\" variant in \"${rule_file}\""
    fi
}

function remove_keymap() {
    local keymap_file="${path_symbols}/${country}"
    local ln_section_start=$(get_line_containing "${section_start}" "${keymap_file}")
    
    if [ -n "${ln_section_start}" ]; then
        printf "Removing \"${variant_desc}\" keymap from \"${keymap_file}\"..."

        local ln_section_end=$(get_line_containing "${section_end}" "${keymap_file}")
        if [ ! -n "${ln_section_end}" ]; then
            echo "Failed. No end identifier."
            exit 2
        fi

        local bak_file=$(get_backup_file "${bak_subdir}" "${keymap_file}")
        cp "${keymap_file}" "${bak_file}"

        { head -n $((ln_section_start-1)) "${bak_file}"; \
          tail -n +$((ln_section_end+1)) "${bak_file}"; } > "${keymap_file}"

        if [ $? -eq 0 ]; then
            any_change=1
        fi

        echo "Done"
    else
        echo "There is no \"${variant_desc}\" keymap in \"${keymap_file}\""
    fi
}

function remove_compose() {
    local compose_file="$1/.XCompose"

    if [ ! -f "${compose_file}" ]; then
        echo "There is no Compose file at \"${compose_file}\""
    else
        local ln_section_start=$(get_line_containing "${section_start}" "${compose_file}")
        if [ -n "${ln_section_start}" ]; then
            printf "Removing \"${variant_desc}\" compose sequences from \"${compose_file}\"..."
            
            local ln_section_end=$(get_line_containing "${section_end}" "${compose_file}")
            if [ ! -n "${ln_section_end}" ]; then
                echo "Failed. No end identifier."
                exit 2
            fi

            local bak_file=$(get_backup_file "${bak_subdir}" "${compose_file}")
            cp "${compose_file}" "${bak_file}"

            { head -n $((ln_section_start-1)) "${bak_file}"; \
              tail -n +$((ln_section_end+1)) "${bak_file}"; } > "${compose_file}"

            if [ $? -eq 0 ]; then
                any_change=1
            fi

            if [ ! -s "${compose_file}" ]; then
                rm "${compose_file}"
            fi

            echo "Done"
        else
            echo "There is no \"${variant_desc}\" compose sequences in \"${compose_file}\""
        fi
    fi
}


main
