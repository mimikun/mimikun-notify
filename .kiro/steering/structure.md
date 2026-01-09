# Project Structure

## Organization Philosophy

**Single-script utility**: Monolithic Bash script with clear functional separation via functions and comments.

- **Configuration section**: Constants and paths
- **Helper functions**: Escaping, logging, title mapping
- **Main logic**: Entry point with error handling

## File Patterns

### Root-Level Script

**Location**: `/mimikun-notify.sh`
**Purpose**: Executable entry point for WSL → Windows notifications
**Example**: Invoked via stdin pipe from Claude Code Hooks

### Documentation

**Location**: `/README.md`
**Purpose**: User guide, integration examples, troubleshooting
**Language**: Japanese (matches target user base)

### Specification Directory

**Location**: `/.kiro/`
**Purpose**: Kiro Spec-Driven Development metadata
**Note**: Not part of runtime logic, AI-assisted development context

## Naming Conventions

- **Script**: `mimikun-notify.sh` (kebab-case, descriptive)
- **Functions**: `snake_case` (e.g., `get_notification_title`, `escape_for_powershell`)
- **Variables**: `snake_case` with `readonly` for constants
- **Constants**: `UPPERCASE_SNAKE_CASE` (e.g., `DEFAULT_TITLE`, `PWSH_EXE`)

## Code Organization Principles

### Section-Based Layout

```bash
#-----------------------------------------------------------
# Configuration
#-----------------------------------------------------------
readonly PWSH_EXE="/mnt/c/Program Files/PowerShell/7/pwsh.exe"

#-----------------------------------------------------------
# Security: PowerShell String Escaping
#-----------------------------------------------------------
escape_for_powershell() { ... }

#-----------------------------------------------------------
# Main Logic
#-----------------------------------------------------------
main() { ... }
```

### Dependency Isolation

- External tools (jq, wslpath, pwsh) called explicitly
- No implicit PATH assumptions
- Windows path hardcoded for PowerShell 7

### Error Handling Flow

1. `set -euo pipefail` at script level
2. Functions return 0/1 exit codes
3. `log_error` for stderr output
4. Main function captures and checks exit codes

## Path Management

### WSL ↔ Windows Conversion

```bash
# WSL path → Windows UNC path
applogo=$(wslpath -w "$APPLOGO_BASE")
# Example: /home/user/.mimikun/images/icon.png → C:\Users\user\.mimikun\images\icon.png
```

### Hardcoded Windows Paths

- PowerShell 7: `/mnt/c/Program Files/PowerShell/7/pwsh.exe`
- Assumes default installation location

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_

