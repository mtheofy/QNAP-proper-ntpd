#!/usr/bin/env bash
set -euo pipefail

#----------------------------------------
# Script to disable QNAP time interference and enable proper NTP sync
#----------------------------------------

# Configuration
readonly TMPCRONTAB="/tmp/crontabtemp.$$"
readonly NTP_SERVER="192.168.0.9"
readonly NTP_CONF_SRC="/share/CACHEDEV1_DATA/Tech/QNAP/TS-951N/autostart/ntp.conf"
readonly NTP_CONF_DEST="/etc/config/ntp.conf"

# Trap to ensure cleanup on exit or interrupt
cleanup() {
    rm -f "$TMPCRONTAB"
}
trap cleanup EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_prerequisites() {
    log "Checking for required commands..."
    local cmds=(crontab sed cp killall hwclock ntpdate daemon_mgr)
    for cmd in "${cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            echo "Error: Required command '$cmd' not found." >&2
            exit 1
        fi
    done
}

safely_stop_processes() {
    log "Stopping time-related daemons and killing stray processes..."
    /sbin/daemon_mgr ntpdated stop "/usr/sbin/ntpdated" || true
    /sbin/daemon_mgr ntpd stop "/usr/sbin/ntpd" || true

    killall -q ntpd || true
    killall -q ntpdated || true
    killall -q adjust_time || true
}

disable_cron_time_sync() {
    log "Disabling cron-based time sync jobs..."
    if /usr/bin/crontab -l > "$TMPCRONTAB"; then
        sed -i -E 's/^[^#]*(hwclock|ntpdate|adjust_time)/# &/' "$TMPCRONTAB"
        cp "$TMPCRONTAB" /etc/config/crontab
        /usr/bin/crontab "$TMPCRONTAB"
    else
        log "Warning: Unable to read crontab. Skipping cron update."
    fi
}

sync_system_and_hwclock() {
    log "Setting system time from hardware clock..."
    /sbin/hwclock -s

    log "Syncing system time with NTP server: $NTP_SERVER..."
    if /sbin/ntpdate -b -p 5 -t 2 "$NTP_SERVER"; then
        log "Writing synchronized system time back to hardware clock..."
        /sbin/hwclock -w
    else
        log "Warning: NTP sync failed. Skipping hwclock write."
    fi
}

setup_ntpd() {
    log "Configuring and starting ntpd..."
    cp "$NTP_CONF_SRC" "$NTP_CONF_DEST"
    /sbin/daemon_mgr ntpd start "ntpd -c $NTP_CONF_DEST"
}

restart_crond() {
    log "Restarting cron service..."
    /etc/init.d/crond.sh restart
}

main() {
    log "----- Starting QNAP NTP Setup Script -----"
    check_prerequisites
    safely_stop_processes
    disable_cron_time_sync
    sync_system_and_hwclock
    restart_crond
    setup_ntpd
    log "----- NTP Setup Script Completed Successfully -----"
}

main "$@"
