#!/usr/bin/env bash
# quickshell subcommand - Copy quickshell config files

printf "${STY_CYAN}Installing quickshell configuration...${STY_RST}\n"

# Source the functions if needed
source "${REPO_ROOT}/sdata/lib/functions.sh"
source "${REPO_ROOT}/sdata/lib/environment-variables.sh"

# Define source and destination
QUICKSHELL_SOURCE="${REPO_ROOT}/dots/.config/quickshell/ii"
QUICKSHELL_DEST="${HOME}/.config/quickshell/ii"

# Check if source exists
if [ ! -d "${QUICKSHELL_SOURCE}" ]; then
    printf "${STY_RED}Error: quickshell source directory not found at ${QUICKSHELL_SOURCE}${STY_RST}\n"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "${QUICKSHELL_DEST}"

# Copy files with backup of existing files
printf "Copying quickshell config files from ${QUICKSHELL_SOURCE} to ${QUICKSHELL_DEST}...\n"

if [ -d "${QUICKSHELL_DEST}" ] && [ "$(ls -A ${QUICKSHELL_DEST})" ]; then
    # Backup existing config if it's not empty
    BACKUP_DIR="${HOME}/.config/quickshell/ii.backup.$(date +%Y%m%d-%H%M%S)"
    printf "Existing quickshell config found. Creating backup at ${BACKUP_DIR}\n"
    cp -r "${QUICKSHELL_DEST}" "${BACKUP_DIR}"
fi

# Copy the new config files
cp -rf "${QUICKSHELL_SOURCE}"/* "${QUICKSHELL_DEST}/" 2>/dev/null || true

printf "${STY_GREEN}✓ quickshell configuration installed successfully${STY_RST}\n"
printf "Location: ${QUICKSHELL_DEST}\n"
