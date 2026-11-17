#!/usr/bin/env bash

set -u
set -o pipefail

errors=0

report_error() {
    printf 'ERROR: %s\n' "$*" >&2
    errors=$((errors + 1))
}

check_disk() {
    printf '\n== Disk usage (root filesystem) ==\n'
    if ! command -v df >/dev/null 2>&1; then
        report_error "Required command 'df' was not found."
        return
    fi

    if ! df -hP /; then
        report_error "Could not read disk usage for /."
    fi
}

check_memory() {
    printf '\n== Memory usage ==\n'
    if command -v free >/dev/null 2>&1; then
        if ! free -h; then
            report_error "Could not read memory usage."
        fi
        return
    fi

    if [[ -r /proc/meminfo ]]; then
        printf 'Memory info (from /proc/meminfo):\n'
        if ! head -n 15 /proc/meminfo; then
            report_error "Could not read memory information from /proc/meminfo."
        fi
        return
    fi

    report_error "Required command 'free' was not found and /proc/meminfo is unavailable."
}

check_cpu_load() {
    printf '\n== CPU load average ==\n'
    if [[ -r /proc/loadavg ]]; then
        local load_1 load_5 load_15
        if ! IFS=' ' read -r load_1 load_5 load_15 _ < /proc/loadavg; then
            report_error "Could not parse /proc/loadavg."
            return
        fi

        printf 'Load average (1, 5, 15 minutes): %s %s %s\n' \
            "$load_1" "$load_5" "$load_15"
        printf 'Note: load average is not a direct CPU utilization percentage.\n'
        return
    fi

    if command -v uptime >/dev/null 2>&1; then
        if ! uptime; then
            report_error "Could not read system uptime."
        fi
        return
    fi

    report_error "Neither /proc/loadavg nor 'uptime' is available; CPU load is unavailable."
}

check_system_info() {
    printf '\n== System information ==\n'

    if grep -qi microsoft /proc/version 2>/dev/null; then
        printf 'WSL environment detected.\n'
    fi

    if [[ -r /etc/os-release ]]; then
        if ! sed -n '1,5p' /etc/os-release; then
            report_error "Could not read operating-system information from /etc/os-release."
        fi
    else
        report_error "Missing /etc/os-release; OS details are unavailable."
    fi

    if command -v hostname >/dev/null 2>&1; then
        if ! hostname; then
            report_error "Could not read the hostname."
        fi
    else
        report_error "Required command 'hostname' was not found."
    fi

    if command -v uname >/dev/null 2>&1; then
        if ! uname -srmo; then
            report_error "Could not read operating-system and architecture information."
        fi
    else
        report_error "Required command 'uname' was not found."
    fi

    if command -v date >/dev/null 2>&1; then
        if ! date '+Report time: %Y-%m-%d %H:%M:%S %Z'; then
            report_error "Could not read the current time."
        fi
    else
        report_error "Required command 'date' was not found."
    fi
}

printf 'Ubuntu WSL health check (read-only)\n'
check_disk
check_memory
check_cpu_load
check_system_info

if (( errors > 0 )); then
    printf '\nHealth check finished with %d error(s).\n' "$errors" >&2
    exit 1
fi

printf '\nHealth check completed successfully.\n'
