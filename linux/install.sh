#!/bin/bash

function main() {
    . "./util.sh"

    if [ ! -d ${path_xkb} ]; then
        echo "There is no directory \"${path_xkb}\". Open util.sh and set XKB path."
        exit 0
    fi

    any_change=0
    bak_subdir="in"

    ensure_input_method_xim

    add_variant "base" "xml"
    add_variant "base" "lst"
    add_variant "evdev" "xml"
    add_variant "evdev" "lst"

    add_keymap

    for h in $(find /home -maxdepth 1 -type d)
    do
        if [ ${h} == "/home" ]; then
            h="/root"
        fi

        add_compose "${h}"
    done

    if [ ${any_change} -ne 0 ]; then
        echo "The \"${variant_desc}\" keyboard layout has been installed successfully."
        echo "Run \"reboot\" to restart the Operating System."
    else
        echo "The \"${variant_desc}\" keyboard layout is already installed. Nothing changed."
    fi
}

function ensure_input_method_xim() {
    printf "Checking if input method is XIM..."
    if [ "${QT_IM_MODULE}" != "xim" -o "${GTK_IM_MODULE}" != "xim" ]; then
        cat "./xim" >> "/etc/environment"
        echo "Set"
    else
        echo "OK"
    fi
}

function add_variant() {
    local rule_name=$1
    local format=$2
    local rule_file="${path_rules}/${rule_name}.${format}"
    local variant_file="./variant.${format}"
    local desc_ln_in_variant=$(get_line_containing "@d" "${variant_file}")
    local desc_ln_in_rule_file=$(get_line_containing "${variant_desc}" "${rule_file}")

    if [ -n "${desc_ln_in_rule_file}" ]; then
        echo "There is already \"${variant_desc}\" variant in \"${rule_file}\""
    else
        printf "Adding \"${variant_desc}\" variant to \"${rule_file}\"..."
        local exist_ln=$(get_line_containing "${exist_variant_desc}" "${rule_file}")
        
        if [ -n ${exist_ln} ]; then
            local bak_file=$(get_backup_file "${bak_subdir}" "${rule_file}")
            cp "${rule_file}" "${bak_file}"

            { head -n $((exist_ln-desc_ln_in_variant)) "${bak_file}"; \
              sed "s/@n/${variant_name}/g" "${variant_file}" | sed "s/@d/${variant_desc}/g" | sed "s/@c/${country}/g"; \
              tail -n +$((exist_ln-desc_ln_in_variant+1)) "${bak_file}"; } > "${rule_file}"

            if [ $? -eq 0 ]; then
                any_change=1
            fi

            echo "Done"
        else
            echo "Failed. No \"${exist_variant_desc}\"?"
            exit 1
        fi
    fi
}

function add_keymap() {
    local keymap_file="${path_symbols}/${country}"
    local ln_variant_desc=$(get_line_containing "${variant_desc}" "${keymap_file}")
    
    if [ -n "${ln_variant_desc}" ]; then
        echo "There is already \"${variant_desc}\" keymap in \"${keymap_file}\""
    else
        printf "Adding \"${variant_desc}\" keymap to \"${keymap_file}\"..."

        local bak_file=$(get_backup_file "${bak_subdir}" "${keymap_file}")
        cp "${keymap_file}" "${bak_file}"

        { echo "// ${section_start}"; cat "./keymap"; printf "// ${section_end}\n\n"; } >> "${keymap_file}"

        if [ $? -eq 0 ]; then
            any_change=1
        fi
        echo "Done"
    fi
}

# In the future Compose file can be placed at ${path_locale}
function add_compose() {
    local compose_file="$1/.XCompose"

    if [ ! -f "${compose_file}" ]; then
        printf "Adding Compose file to \"${compose_file}\"..."
        { echo "# ${section_start}"; cat "./Compose"; echo "# ${section_end}"; } > "${compose_file}"
        if [ $? -eq 0 ]; then
            any_change=1
        fi
        echo "Done"
    else
        local ln_section=$(get_line_containing "${section_id}" "${compose_file}")
        if [ -n "${ln_section}" ]; then
            echo "There are already compose sequences of \"${variant_desc}\" in \"${compose_file}\""
        else
            printf "Adding compose sequences of \"${variant_desc}\" to \"${compose_file}\"..."

            local bak_file=$(get_backup_file "${bak_subdir}" "${compose_file}")
            cp "${compose_file}" "${bak_file}"

            { echo "# ${section_start}"; cat "./Compose"; printf "# ${section_end}\n\n"; } >> "${compose_file}"

            if [ $? -eq 0 ]; then
                any_change=1
            fi
            echo "Done"
        fi
    fi
}


main
