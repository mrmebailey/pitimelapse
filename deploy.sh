#!/bin/bash
# PiTimelapse Deploy Script — run without arguments to see usage.

set -e

PI_HOST="pi@192.168.1.195"
PI_HOME="/home/pi"
WEB_ROOT="/var/www/html"
VERSION="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log()  { echo "[$(date +%T)] $*"; }
info() { echo; echo "  $*"; }
die()  { echo "ERROR: $*" >&2; exit 1; }

usage() {
    echo "PiTimelapse Deploy Script"
    echo "Pushes v2 (bash/raspistill) or v3 (Python/picamera2) to the Pi."
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "  bootstrap-pi   Install all system dependencies on the Pi (run once on a new Pi)"
    echo "  v2             Deploy timeLapse.sh + add_stamps.sh (bash / raspistill)"
    echo "  v3             Deploy timeLapse_v3.py (Python / picamera2 / Camera Module 3)"
    echo "  all            Deploy both v2 and v3"
    echo ""
    echo "Getting started:"
    echo "  1. ssh-copy-id ${PI_HOST}   # set up passwordless SSH (once on your laptop)"
    echo "  2. $0 bootstrap-pi          # install dependencies on the Pi (once)"
    echo "  3. $0 v3                    # deploy the script (repeat when updating)"
}

# ── SSH check ────────────────────────────────────────────────────────────────

check_ssh() {
    log "Checking SSH connectivity to ${PI_HOST}..."
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${PI_HOST}" true 2>/dev/null; then
        echo
        echo "Cannot connect to ${PI_HOST} without a password prompt."
        echo "Set up passwordless SSH with:"
        echo "  ssh-copy-id ${PI_HOST}"
        die "SSH key auth required."
    fi
    log "SSH OK."
}

# ── Bootstrap (run once on a new Pi) ─────────────────────────────────────────

bootstrap_pi() {
    log "Bootstrapping Pi — installing all system dependencies..."
    ssh "${PI_HOST}" bash << 'REMOTE'
        set -e
        sudo apt-get update -qq
        sudo apt-get install -y apache2 ffmpeg imagemagick python3-picamera2 python3-pil

        # Allow pi user to write to the web root without sudo
        sudo usermod -a -G www-data pi
        sudo chown -R www-data:www-data /var/www/html
        sudo chmod g+w /var/www/html
        sudo rm -f /var/www/html/index.html

        # Ensure /var/lock is writable by pi (for the lock dir)
        sudo chmod 1777 /var/lock
REMOTE
    log "Bootstrap complete."
}

# ── v2 deploy (bash + raspistill) ────────────────────────────────────────────

deploy_v2() {
    log "Deploying v2 scripts (timeLapse.sh, add_stamps.sh)..."
    scp "${SCRIPT_DIR}/timeLapse.sh" "${SCRIPT_DIR}/add_stamps.sh" "${PI_HOST}:${PI_HOME}/"
    ssh "${PI_HOST}" chmod 755 "${PI_HOME}/timeLapse.sh" "${PI_HOME}/add_stamps.sh"
    log "v2 deployed."

    info "VNC focus (v2 camera):"
    info "  raspistill -t 0     ← live preview; Ctrl+C to exit"
    info ""
    info "Add to crontab (example — every 10 min, 1024x768 q30):"
    info "  (crontab -l ; echo \"*/10 * * * * ${PI_HOME}/timeLapse.sh my_lapse 1024 768 30\") | crontab"
    info ""
    info "Remove from crontab:"
    info "  ( crontab -l | grep -vF \"${PI_HOME}/timeLapse.sh\" ) | crontab -"
}

# ── v3 deploy (Python + picamera2) ───────────────────────────────────────────

deploy_v3() {
    log "Copying v3 script..."
    scp "${SCRIPT_DIR}/v3/timeLapse_v3.py" "${PI_HOST}:${PI_HOME}/"
    ssh "${PI_HOST}" chmod 755 "${PI_HOME}/timeLapse_v3.py"
    log "v3 deployed."

    info "VNC focus (v3 / Camera Module 3 — autofocus):"
    info "  libcamera-hello -t 0    ← live preview with AF; Ctrl+C to exit"
    info "  (Camera Module 3 focuses automatically before each shot)"
    info ""
    info "First manual test (run once to create seed photo):"
    info "  python3 ${PI_HOME}/timeLapse_v3.py my_lapse"
    info ""
    info "Add to crontab (example — every 10 min, full 12MP):"
    info "  (crontab -l ; echo \"*/10 * * * * python3 ${PI_HOME}/timeLapse_v3.py my_lapse\") | crontab"
    info ""
    info "Custom resolution (e.g. 1080p):"
    info "  (crontab -l ; echo \"*/10 * * * * python3 ${PI_HOME}/timeLapse_v3.py my_lapse 1920 1080 90\") | crontab"
    info ""
    info "Remove from crontab:"
    info "  ( crontab -l | grep -vF \"timeLapse_v3.py\" ) | crontab -"
}

# ── VNC reminder (both versions) ─────────────────────────────────────────────

vnc_reminder() {
    cat << 'NOTICE'

── VNC Setup (headless Pi) ─────────────────────────────────────────────────────
  sudo apt install realvnc-vnc-server realvnc-vnc-viewer
  sudo raspi-config  →  Interfacing Options  →  VNC  →  Yes

  Edit /boot/config.txt (or /boot/firmware/config.txt on Bookworm):
    Uncomment:  hdmi_force_hotplug=1

  In VNC Viewer:  enable  Options → Expert → DirectCapture = ON
    (required for live camera preview over VNC)

── Web viewer ───────────────────────────────────────────────────────────────────
  http://192.168.1.195/<project-name>/timelapse_banner_static.mp4

────────────────────────────────────────────────────────────────────────────────
NOTICE
}

# ── Main ─────────────────────────────────────────────────────────────────────

case "${VERSION}" in
    bootstrap-pi|v2|v3|all) ;;
    -h|--help)
        usage
        exit 0
        ;;
    "")
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: ${VERSION}"
        echo ""
        usage
        exit 1
        ;;
esac

check_ssh

case "${VERSION}" in
    bootstrap-pi)
        bootstrap_pi
        ;;
    v2)
        deploy_v2
        ;;
    v3)
        deploy_v3
        ;;
    all)
        deploy_v2
        deploy_v3
        ;;
esac

vnc_reminder
log "Deploy complete."
