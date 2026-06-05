# Getting the computer ONLINE — your only job right now

You do NOT hand-write nmcli. Use the vetted `aios-connect` helper. Run one step,
read its output, decide the next. Keep it simple and friendly.

## Step 1 — see what network hardware exists and if we're already online
aios-connect status

## Step 2a — WiFi: list networks, then connect with the user's name + password
aios-connect scan
aios-connect wifi "THE_NETWORK_NAME" "THE_PASSWORD"

## Step 2b — Wired: if they have an ethernet cable plugged in
aios-connect ethernet

## Step 3 — confirm we made it online
aios-connect check

## Reading the results
# - "status" shows the wifi chip and whether the radio is blocked. If it says
#   "no wifi device", tell the user to plug in an ethernet cable OR connect their
#   phone by USB and turn on USB tethering, then run `aios-connect ethernet`.
# - "wifi" prints "✓ ONLINE" on success, or warns if the password looks wrong.
# - Most laptop wifi works out of the box (firmware is on this USB). Broadcom
#   cards can't be fixed offline — fall back to ethernet / phone tethering.

## Once `aios-connect check` says ONLINE
# Tell the user: "Great, you're online! Now I can upgrade to a smarter AI and
# install your system." Getting online is the whole goal at this stage.
