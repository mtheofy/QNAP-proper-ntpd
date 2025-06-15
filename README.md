# QNAP NTP Fix Script

## Summary

This script is designed to run on QNAP NAS devices to override their unreliable and inconsistent native time synchronization behavior. It stops all built-in time sync mechanisms, neutralizes crontab hacks, and sets up a clean `ntpd` daemon using your own configuration.

---

## Why?

QNAP's native time synchronization implementation is notoriously problematic:

- It frequently relies on `ntpdate` or custom scripts like `adjust_time` that can conflict with each other.
- Time sync is often configured redundantly in both cron jobs and services.
- Hardware clock sync behavior is chaotic, leading to inconsistent system times, especially after reboots.

This script **disables the mockery** from QNAP’s crontab and re-establishes a clean, reliable time sync routine based on an `ntpd` service using your own `ntp.conf` file.

---

## What it Does

- Disables all QNAP-generated cron jobs related to `hwclock`, `ntpdate`, and `adjust_time`.
- Stops all time-related daemons (`ntpdated`, `ntpd`) and kills any leftover processes.
- Sets the system clock from the hardware clock.
- Syncs the system time with your own NTP server.
- Updates the hardware clock from the system clock.
- Restarts cron and launches a proper `ntpd` daemon using your own configuration file.

---

## Requirements

- A working NTP server (e.g., on your LAN) that needs to be set in the `$NTP_SERVER` variable
- A valid `ntp.conf` file stored under path: such as `/share/YOURCUSTOMPATH/ntp.conf` that is set in the `$NTP_CONF_SRC` variable
- Admin/Root access on your QNAP device
- Familiarity with `autorun.sh` functionality

---

## How to Use

### 1. Install the Script in autorun
This script is intended to run automatically at boot using QNAP’s **autorun.sh** mechanism.

> ℹ️ This script is aimed at advanced users. It assumes you already know how to install and configure `autorun.sh` on your QNAP device.

### 2. Adjust QTS Settings

Inside QTS (the QNAP admin interface):

- Go to **Control Panel > Date and Time**
- Set time sync to **manual**
- Make sure **NTP Server application is disabled**

This ensures QTS won't interfere with the time settings after the script runs.

### 3. Run the script
Before rebooting execute the script and check whether it's working. Some `ntpd.conf` files cause `ntpd` to crash so check the output of `ntpq -pw`. If all goes well and `ntpd` does not die after a few minutes, you might want to try rebooting your QNAP to test whether it is properly executed at boot time. 

---

## Credits

Created by a frustrated QNAP user who needed time to actually make sense.

---

## Disclaimer

Use at your own risk. This script directly modifies cron jobs and system services. Make sure you understand what it does before using it.
