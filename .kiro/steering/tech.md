# Technology Stack

## Architecture

**Cross-platform integration script**: WSL2 Bash → Windows PowerShell 7 → Windows Notification System

- stdin経由でJSON受信
- jqでJSON解析
- PowerShellでBurntToast通知送信

## Core Technologies

- **Language**: Bash (POSIX-compliant with bash extensions)
- **Runtime**: WSL2 (Linux on Windows)
- **Notification Backend**: Windows PowerShell 7.x + BurntToast Module

## Key External Dependencies

- **jq**: JSON parsing and field extraction
- **wslpath**: WSL ↔ Windows path conversion utility
- **PowerShell 7**: Cross-platform PowerShell runtime
- **BurntToast Module**: Windows Toast notification library

## Development Standards

### Code Quality

- `set -euo pipefail`: Strict error handling
- Readonly configuration variables
- Explicit function-based structure

### Security Patterns

```bash
# PowerShell injection prevention
escape_for_powershell() {
    local input="$1"
    echo "${input//\'/\'\'}"  # Single quote → double single quote
}
```

### Input Validation

- JSON parsing with default values
- Error logging to stderr
- Graceful degradation on parsing failures

## Development Environment

### Required Tools

- **WSL2**: Windows Subsystem for Linux 2
- **Bash**: 4.0+ (set -u support)
- **jq**: 1.6+
- **PowerShell**: 7.x installed in `/mnt/c/Program Files/PowerShell/7/pwsh.exe`
- **BurntToast Module**: PowerShell module for Windows notifications

### Common Commands

```bash
# Test notification
echo '{"notification_type":"permission_prompt","message":"Test"}' | ./mimikun-notify.sh

# Validate JSON parsing
echo '{}' | ./mimikun-notify.sh  # Should use defaults

# Check PowerShell availability
"/mnt/c/Program Files/PowerShell/7/pwsh.exe" -Version
```

## Key Technical Decisions

### Why Bash + PowerShell?

- **Bash**: Native WSL environment, familiar for Unix users
- **PowerShell 7**: Modern cross-platform runtime with module ecosystem
- **BurntToast**: Mature, feature-rich Windows notification library

### Why stdin for JSON input?

- **Pipe-friendly**: Integrates with Claude Code Hooks naturally
- **Security**: No command-line argument parsing vulnerabilities
- **Flexibility**: Easy to test with `echo` or `curl`

### Error Handling Strategy

- **Fail-fast**: `set -euo pipefail` for script integrity
- **Graceful defaults**: jq failures return safe default values
- **Logging**: Errors to stderr with timestamps

---
_Document standards and patterns, not every dependency_

