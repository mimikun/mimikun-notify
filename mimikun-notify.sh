#!/bin/bash
# WSL to Windows Toast Notification Script
# Receives JSON input from Claude Code Hooks via stdin

set -euo pipefail

#-----------------------------------------------------------
# Configuration
#-----------------------------------------------------------

readonly PWSH_EXE="/mnt/c/Program Files/PowerShell/7/pwsh.exe"
# TODO: it
#readonly APPLOGO_BASE="$HOME/.mimikun/images/sea_urchin.png"
#readonly PERMISSION_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
#readonly IDLE_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
readonly DEFAULT_TITLE="Claude Code - 通知"
readonly DEFAULT_MESSAGE="通知メッセージがありません"
# TODO: remove
readonly APPLOGO_BASE="$HOME/.mimikun/images/ansin.png"
readonly HEROIMAGE_BASE="$HOME/.mimikun/images/fuan.png"

#-----------------------------------------------------------
# Logging
#-----------------------------------------------------------

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

#-----------------------------------------------------------
# Security: PowerShell String Escaping
#-----------------------------------------------------------

escape_for_powershell() {
    local input="$1"
    # Single quote escape: ' → ''
    echo "${input//\'/\'\'}"
}

#-----------------------------------------------------------
# Notification Title Logic
#-----------------------------------------------------------

get_notification_title() {
    local type="$1"

    case "$type" in
    permission_prompt)
        echo "Claude Code - 許可の要求"
        ;;
    idle_prompt)
        echo "Claude Code - 入力待ち"
        ;;
    *)
        echo "$DEFAULT_TITLE"
        ;;
    esac
}

#-----------------------------------------------------------
# Main Logic
#-----------------------------------------------------------

main() {
    # Read JSON from stdin
    local json_input
    json_input=$(cat)

    # Extract fields with jq (with defaults)
    local notification_type
    local message
    notification_type=$(echo "$json_input" | jq -r '.notification_type // "unknown"' 2>/dev/null || echo "unknown")
    message=$(echo "$json_input" | jq -r ".message // \"$DEFAULT_MESSAGE\"" 2>/dev/null || echo "$DEFAULT_MESSAGE")

    # Determine title based on notification_type
    local title
    title=$(get_notification_title "$notification_type")

    # Escape for PowerShell
    local title_escaped
    local message_escaped
    title_escaped=$(escape_for_powershell "$title")
    message_escaped=$(escape_for_powershell "$message")

    # Convert paths to Windows UNC format
    local applogo
    local heroimage
    applogo=$(wslpath -w "$APPLOGO_BASE" 2>/dev/null || echo "$APPLOGO_BASE")
    heroimage=$(wslpath -w "$HEROIMAGE_BASE" 2>/dev/null || echo "$HEROIMAGE_BASE")

    # Execute PowerShell command
    "$PWSH_EXE" -Command "
        New-BurntToastNotification \`
            -Text '$title_escaped', '$message_escaped' \`
            -Sound Default \`
            -AppLogo '$applogo' \`
            -HeroImage '$heroimage' \`
            -Attribution 'Powered by Claude Code from WSL' \`
            -Urgent
    "

    local exit_code=$?

    if [[ $exit_code -ne 0 ]]; then
        log_error "PowerShell notification failed with exit code $exit_code"
        return 1
    fi

    return 0
}

# Execute main function
main

