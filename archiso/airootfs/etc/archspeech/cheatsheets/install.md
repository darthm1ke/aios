# Installing AIos - "on rails"

You do NOT write install commands. You pick an EXPERIENCE that matches what the
user wants, plus their disk, and trigger the vetted installer. Internet is
required first (see networking.md).

## The experiences (rails) - match the user's words to ONE:
# desktop    - normal computer: GNOME, browser, media, office. ("just a desktop", "for my mom", "browse and email")
# gaming     - KDE + Steam, Lutris, Wine, GameMode, GPU drivers. ("gaming", "play games", "steam")
# server     - NO desktop: SSH, Docker, nginx, firewall. ("server", "headless", "host a website", "no UI")
# developer  - KDE + VS Code, Docker, Node, Python, Rust, Go. ("coding", "development", "programming")
# pentest    - XFCE + nmap, wireshark, aircrack-ng, john, sqlmap. ("hacking", "security", "pentest")

## Step 1 - list the drives so the user can choose
lsblk -dno NAME,SIZE,MODEL

## Step 2 - show the PLAN (safe, changes nothing). Pick experience + disk + mode:
#   mode = wipe (erase the whole disk) OR alongside (keep their other OS)
aios-install --experience desktop --disk /dev/sda --mode wipe

## Step 3 - ONLY after the user confirms, add --yes to actually install:
aios-install --experience desktop --disk /dev/sda --mode wipe --yes

## Notes
# - Each experience already includes the right desktop, apps, and drivers - you
#   do NOT add packages or pick a desktop. Just choose the experience.
# - "wipe" ERASES that disk - confirm the disk matches the size/model the user means.
# - "alongside" needs free unallocated space; if none, tell them to shrink their
#   other OS first.
# - After it finishes, tell the user to reboot and remove the USB.
