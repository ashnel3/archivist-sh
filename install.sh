#!/usr/bin/env bash

{
    archivist_echo() {
        command printf %s\\n "$*" 2>/dev/null
    }

    archivist_error() {
        >&2 archivist_echo "$@"
    }

    archivist_has() {
        type "$1" > /dev/null 2>&1
    }

    # TODO: Updating
    # TODO: Swap script-install to git-install if git become available
    archivist_update() {
        return 0
    }

    archivist_schedule_task() {
        if ! archivist_has "crontab"; then
            archivist_error "Error: Failed to find cron!"
            exit 1
        fi
        (crontab -l 2>/dev/null; archivist_echo "0 * * * * archivist run") | crontab -
    }

    archivist_write_entrypoint() {
        rm -f "$1"
        archivist_echo '#!/usr/bin/env bash'                 >> "$1"
        archivist_echo ''                                    >> "$1"
        archivist_echo "(cd $PWD && ./archivist.sh \"\$@\")" >> "$1"
        chmod +x "$1"
    }

    # TODO: Install w/o git
    archivist_install_as_script() {
        archivist_error "Error: installation without git isn't implemented"
        exit 1
    }

    archivist_install_as_repo() {
        if [[ ! -d "$1/.git" ]]; then
            git clone https://github.com/ashnel3/archivist-sh.git "$1" \
                && archivist_echo "  + Writting script to: $2/archivist" \
                && archivist_write_entrypoint "$2/archivist" \
                && archivist_echo "  + Scheduling hourly task" \
                && archivist_schedule_task
        else
            archivist_echo "  + Found archivist git instance"
        fi
    }

    archivist_install() {
        local archivist_dir=~/.archivist
        if archivist_has "git"; then
            archivist_install_as_repo "$archivist_dir" "$1"
        else
            mkdir -p "$archivist_dir" \
                && archivist_install_as_script "$archivist_dir" "$1"
        fi
    }

    archivist_install_parse_args() {
        local proceed="false"
        local mode="install"
        local install_path=$HOME/bin

        if ! archivist_has "wget"; then
            archivist_error "Error: failed to find wget!"
            exit 1
        fi

        # Parse args
        while [ "$#" -ne 0 ]; do
            case "$1" in
                -y ) proceed="true" ;;
                -u | --uninstall ) mode="uninstall" ;;
                --path=* ) install_path="${1#*=}" ;;
            esac
            shift
        done

        # Start
        case "$mode" in
            install )
                if [[ "$proceed" == "false" ]]; then
                    read -p "  + This script will install archivist globally & create a scheduled task. Continue? (y/n): " -n 1 -r ans
                    archivist_echo ""
                    [[ ! "$ans" =~ [Yy] ]] && exit 0
                fi
                archivist_install "$install_path"
            ;;

            uninstall )
                if [[ "$proceed" == "false" ]]; then
                    read -p "Uninstall archivist? (y/n): " -n 1 -r ans
                    archivist_echo ""
                fi
            ;;
        esac
    }

    archivist_install_parse_args "$@"
}
