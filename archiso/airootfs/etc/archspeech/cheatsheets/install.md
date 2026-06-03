# Installing AIos to the user's drive

DO NOT hand-write partition/pacstrap commands — they are dangerous and easy to
get wrong. Use the vetted installer `aios-install`. Your job is to gather 3
choices from the user, show them the PLAN, then run it. Internet is required
(see networking.md — get online first).

## Step 1 — list the drives so the user can choose
lsblk -dno NAME,SIZE,MODEL

## Step 2 — gather 3 choices from the user
# 1. target disk     e.g. /dev/sda  or  /dev/nvme0n1
# 2. mode            wipe       = erase the whole disk (simplest)
#                    alongside  = keep the existing OS, install in free space (dual-boot)
# 3. desktop         gnome (Wayland) | kde (Wayland) | xfce (X11, light) | minimal (no desktop)

## Step 3 — ALWAYS show the plan first (safe, changes nothing):
aios-install --disk /dev/sda --mode wipe --desktop gnome

## Step 4 — only after the user confirms, add --yes to actually do it:
aios-install --disk /dev/sda --mode wipe --desktop gnome --yes

## Notes
# - "wipe" ERASES everything on that disk. Make the user confirm the disk first
#   (match the size/model from lsblk to the drive they mean).
# - "alongside" needs unallocated free space on the disk. If there is none,
#   tell the user to shrink their existing OS partition first, then retry.
# - The installer copies the AIos AI core (model included) onto the new system,
#   so the AI still works there with no internet.
# - After it finishes, tell the user to reboot and remove the USB.
