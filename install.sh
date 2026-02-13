#!/bin/bash
# ═══════════════════════════════════════════════════════
#  exímIA Meter — Installer
#  Usage: curl -fsSL https://raw.githubusercontent.com/hugocapitelli/eximia-meter/main/install.sh | bash
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
REPO_URL="https://github.com/hugocapitelli/eximia-meter.git"
INSTALL_PATH="/Applications/exímIA Meter.app"

ok()   { echo -e "  ${GREEN}✓${RESET} $1"; }
fail() { echo -e "  ${RED}✗${RESET} $1"; }
info() { echo -e "  ${GRAY}$1${RESET}"; }
head() { echo -e "\n  ${AMBER}${BOLD}$1${RESET}"; }

# ─── Banner ───────────────────────────────────────────
echo ""
echo -e "  ${AMBER}${BOLD}┌──────────────────────────────────────┐${RESET}"
echo -e "  ${AMBER}${BOLD}│${RESET}   ${WHITE}${BOLD}exímIA Meter${RESET}  ${DIM}Installer${RESET}           ${AMBER}${BOLD}│${RESET}"
echo -e "  ${AMBER}${BOLD}│${RESET}   ${GRAY}Claude Code Usage Monitor${RESET}          ${AMBER}${BOLD}│${RESET}"
echo -e "  ${AMBER}${BOLD}└──────────────────────────────────────┘${RESET}"

# ─── Pre-flight ───────────────────────────────────────
head "Pre-flight checks"

# macOS check
if [[ "$(uname)" != "Darwin" ]]; then
    fail "exímIA Meter is only available for macOS."
    exit 1
fi

MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [[ "$MACOS_MAJOR" -lt 14 ]]; then
    fail "macOS 14 (Sonoma) or later required. You have macOS $MACOS_VERSION."
    exit 1
fi
ok "macOS $MACOS_VERSION"

# Swift check
if ! command -v swift &>/dev/null; then
    fail "Swift not found. Install Xcode Command Line Tools:"
    echo -e "    ${WHITE}xcode-select --install${RESET}"
    exit 1
fi
SWIFT_VERSION=$(swift --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
ok "Swift $SWIFT_VERSION found"

# Git check
if ! command -v git &>/dev/null; then
    fail "Git not found. Install Xcode Command Line Tools:"
    echo -e "    ${WHITE}xcode-select --install${RESET}"
    exit 1
fi
ok "Git found"

# Existing install
if [[ -d "$INSTALL_PATH" ]]; then
    info "Existing installation found. Will be replaced."
fi

# ─── Clone ────────────────────────────────────────────
head "Downloading source..."

TMPDIR_PATH=$(mktemp -d)
SRC_DIR="$TMPDIR_PATH/eximia-meter"

cleanup() {
    rm -rf "$TMPDIR_PATH"
}
trap cleanup EXIT

if ! git clone --depth 1 "$REPO_URL" "$SRC_DIR" &>/dev/null; then
    fail "Failed to clone repository."
    info "Check your internet connection and try again."
    exit 1
fi
ok "Source downloaded"

# ─── Build ────────────────────────────────────────────
head "Building (this may take a minute)..."

BUILD_LOG="$TMPDIR_PATH/build.log"
if ! (cd "$SRC_DIR" && swift build -c release > "$BUILD_LOG" 2>&1); then
    fail "Build failed:"
    tail -5 "$BUILD_LOG"
    info "Make sure Xcode Command Line Tools are properly installed:"
    echo -e "    ${WHITE}xcode-select --install${RESET}"
    exit 1
fi
ok "Build complete"

# ─── Create .app bundle ──────────────────────────────
head "Creating app bundle..."

BINARY="$SRC_DIR/.build/release/EximiaMeter"
APP_BUNDLE="$TMPDIR_PATH/$APP_NAME.app"

if [[ ! -f "$BINARY" ]]; then
    fail "Binary not found after build."
    exit 1
fi

mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/EximiaMeter"
chmod +x "$APP_BUNDLE/Contents/MacOS/EximiaMeter"
cp "$SRC_DIR/Info.plist" "$APP_BUNDLE/Contents/"
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
ok "App bundle created"

# ─── Install ─────────────────────────────────────────
head "Installing..."

if [[ -d "$INSTALL_PATH" ]]; then
    rm -rf "$INSTALL_PATH"
fi

if cp -R "$APP_BUNDLE" "/Applications/" 2>/dev/null; then
    ok "Installed to $INSTALL_PATH"
else
    info "Need elevated permissions..."
    if sudo cp -R "$APP_BUNDLE" "/Applications/"; then
        ok "Installed with sudo"
    else
        fail "Installation failed. Try manually:"
        echo -e "    ${WHITE}cp -R \"$APP_BUNDLE\" /Applications/${RESET}"
        exit 1
    fi
fi

# ─── Launch ──────────────────────────────────────────
head "Launching exímIA Meter..."

if open "$INSTALL_PATH" 2>/dev/null; then
    ok "App launched!"
else
    info "Could not auto-launch. Open from Applications."
fi

# ─── Done ────────────────────────────────────────────
echo ""
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo -e "  ${GREEN}${BOLD}  exímIA Meter installed successfully!${RESET}"
echo -e "  ${AMBER}${BOLD}════════════════════════════════════════${RESET}"
echo ""
echo -e "  ${GRAY}The app appears in your menu bar (top right).${RESET}"
echo -e "  ${GRAY}Look for the exímIA logo icon.${RESET}"
echo ""
echo -e "  ${DIM}To uninstall:${RESET}"
echo -e "  ${WHITE}rm -rf \"$INSTALL_PATH\"${RESET}"
echo ""
