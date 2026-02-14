#!/bin/bash
# ═══════════════════════════════════════════════════════
#  exímIA Meter — Uninstaller
#  Usage: curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/uninstall.sh | bash
# ═══════════════════════════════════════════════════════

set -e

# Colors
AMBER='\033[38;2;245;158;11m'
GREEN='\033[38;2;16;185;129m'
RED='\033[38;2;239;68;68m'
WHITE='\033[37m'
GRAY='\033[90m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

APP_NAME="exímIA Meter"
INSTALL_PATH="/Applications/exímIA Meter.app"

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; }
info() { echo -e "  ${GRAY}$1${RESET}"; }
head() { echo -e "\n  ${AMBER}${BOLD}$1${RESET}"; }

echo ""
echo -e "  ${AMBER}${BOLD}┌──────────────────────────────────────┐${RESET}"
echo -e "  ${AMBER}${BOLD}│${RESET}   ${WHITE}${BOLD}exímIA Meter${RESET}  ${DIM}Uninstaller${RESET}         ${AMBER}${BOLD}│${RESET}"
echo -e "  ${AMBER}${BOLD}└──────────────────────────────────────┘${RESET}"

# ─── Stop running instances ──────────────────────────
head "Stopping exímIA Meter..."

if killall EximiaMeter 2>/dev/null; then
    ok "App stopped"
    sleep 1
else
    info "App was not running"
fi

# ─── Remove app bundle ───────────────────────────────
head "Removing app..."

if [[ -d "$INSTALL_PATH" ]]; then
    if rm -rf "$INSTALL_PATH" 2>/dev/null; then
        ok "Removed $INSTALL_PATH"
    else
        info "Need elevated permissions..."
        if sudo rm -rf "$INSTALL_PATH"; then
            ok "Removed with sudo"
        else
            fail "Could not remove app. Try manually:"
            echo -e "    ${WHITE}sudo rm -rf \"$INSTALL_PATH\"${RESET}"
        fi
    fi
else
    info "App not found at $INSTALL_PATH"
fi

# ─── Remove preferences ─────────────────────────────
head "Removing preferences..."

defaults delete com.eximia.meter 2>/dev/null && ok "Removed com.eximia.meter defaults" || true
defaults delete EximiaMeter 2>/dev/null && ok "Removed EximiaMeter defaults" || true

# Remove plist files if they exist
rm -f ~/Library/Preferences/com.eximia.meter.plist 2>/dev/null
rm -f ~/Library/Preferences/EximiaMeter.plist 2>/dev/null

ok "Preferences cleaned"

# ─── Done ────────────────────────────────────────────
echo ""
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo -e "  ${GREEN}${BOLD}  exímIA Meter uninstalled successfully${RESET}"
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${GRAY}To reinstall:${RESET}"
echo -e "  ${WHITE}curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash${RESET}"
echo ""
