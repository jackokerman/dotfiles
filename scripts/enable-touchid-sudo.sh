#!/usr/bin/env bash

# Enable Touch ID for sudo commands
# This modifies /etc/pam.d/sudo_local to allow Touch ID authentication for sudo
# Requires macOS Sonoma (14.0+) for the sudo_local method that persists across updates

# Source logging utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

title "Enabling Touch ID for sudo"

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [[ $MACOS_VERSION -lt 14 ]]; then
    warning "macOS Sonoma (14.0) or later is required for the persistent Touch ID method"
    info "Your version: $(sw_vers -productVersion)"
    info "Skipping Touch ID configuration"
    exit 0
fi

# Path to the sudo_local file
SUDO_LOCAL="/etc/pam.d/sudo_local"
PAM_TID_LINE="auth       sufficient     pam_tid.so"

# Check if the file already has Touch ID enabled (no sudo needed - file is world-readable)
if [[ -f "$SUDO_LOCAL" ]] && grep -q "^auth.*sufficient.*pam_tid\.so" "$SUDO_LOCAL"; then
    success "Touch ID for sudo is already enabled"
    exit 0
fi

# Only request sudo access if we actually need to make changes
info "This will modify $SUDO_LOCAL to enable Touch ID for sudo commands"
sudo -v

# If sudo_local doesn't exist, create it from the template
if [[ ! -f "$SUDO_LOCAL" ]]; then
    if [[ -f "${SUDO_LOCAL}.template" ]]; then
        info "Creating $SUDO_LOCAL from template"
        sudo cp "${SUDO_LOCAL}.template" "$SUDO_LOCAL"
    else
        info "Creating new $SUDO_LOCAL file"
        echo "# sudo_local: local config file which survives system update and is included for sudo" | sudo tee "$SUDO_LOCAL" > /dev/null
        echo "# Uncomment following line to enable Touch ID for sudo" | sudo tee -a "$SUDO_LOCAL" > /dev/null
        echo "#$PAM_TID_LINE" | sudo tee -a "$SUDO_LOCAL" > /dev/null
    fi
fi

# Uncomment the pam_tid.so line or add it if it doesn't exist
if grep -q "^#.*auth.*sufficient.*pam_tid\.so" "$SUDO_LOCAL"; then
    # Line exists but is commented, uncomment it
    info "Uncommenting Touch ID line in $SUDO_LOCAL"
    sudo sed -i '' 's/^#\(auth.*sufficient.*pam_tid\.so\)/\1/' "$SUDO_LOCAL"
elif ! grep -q "pam_tid\.so" "$SUDO_LOCAL"; then
    # Line doesn't exist at all, add it at the top after any comments
    info "Adding Touch ID line to $SUDO_LOCAL"
    sudo sed -i '' "1a\\
$PAM_TID_LINE
" "$SUDO_LOCAL"
fi

# Verify it worked
if grep -q "^auth.*sufficient.*pam_tid\.so" "$SUDO_LOCAL"; then
    success "Touch ID for sudo has been enabled successfully!"
    info "You can now use Touch ID instead of typing your password for sudo commands"
else
    error "Failed to enable Touch ID for sudo"
fi
