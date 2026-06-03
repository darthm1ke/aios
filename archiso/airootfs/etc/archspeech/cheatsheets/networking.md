# Getting Online (AIos — do this FIRST, before installing)

The user usually has NO internet yet. Your job: get them connected. Try the
EASIEST path first, diagnose only if it fails. Run ONE command, read its output,
then decide the next step.

## Step 1 — what network hardware exists?
nmcli device status
ip link show

## Step 2a — WiFi (most common)
rfkill unblock all                      # undo a hardware/soft block first
nmcli radio wifi on
nmcli device wifi list                  # show nearby networks
nmcli device wifi connect "SSID" password "PASSWORD"

## Step 2b — Wired ethernet (most reliable — just plug in a cable)
nmcli device connect <interface>        # e.g. enp3s0; usually auto-connects

## Step 2c — Phone USB tethering (BEST fallback when WiFi driver is broken)
# Plug phone in by USB, enable "USB tethering" on the phone. It appears as a
# wired device and NetworkManager grabs it automatically:
nmcli device status                     # look for a new ethernet/usb device
nmcli device connect <usb-iface>

## Step 3 — confirm it worked
ping -c 2 archlinux.org

## DIAGNOSE — WiFi device missing or won't connect
rfkill list                             # is it "Soft blocked: yes"? -> rfkill unblock all
lspci -k | grep -A3 -i network          # which WiFi chip + is a driver bound?
lsusb                                    # USB WiFi dongles show here
dmesg | grep -iE "firmware|wifi|iwlwifi|ath|rtw" | tail -20   # missing firmware?

## Driver reality check (NO internet = can't download drivers)
# linux-firmware (Intel/Atheros/Realtek/MediaTek) is already on this USB, so most
# laptop WiFi works after `rfkill unblock all`. Broadcom (broadcom-wl) does NOT
# ship firmware and CANNOT be fixed offline — for those, tell the user to use
# ETHERNET or PHONE USB TETHERING (step 2b/2c). That always works.

## Once online, hand back to install.md to install the OS.
