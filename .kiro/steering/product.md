# Product Overview

WSL環境からWindows 10/11のトースト通知システムにメッセージを送信するBashスクリプト。Claude Code Hooksとの統合により、AI開発環境でのユーザー通知を実現する。

## Core Capabilities

1. **Cross-Platform Communication**
   - WSL2からWindows PowerShell 7へのシームレスなメッセージ送信
   - JSON入力をWindows BurntToast通知形式に変換

2. **Claude Code Hooks Integration**
   - `permission_prompt`（許可要求）と`idle_prompt`（入力待ち）をサポート
   - 通知タイプに応じた適切なタイトル表示

3. **セキュアな入力処理**
   - JSON解析と検証（jq使用）
   - PowerShell injection対策（シングルクォートエスケープ）
   - デフォルト値によるフォールバック

## Target Use Cases

- **AI開発環境での通知**: Claude Codeがユーザー入力を待っている際にWindows通知で知らせる
- **WSL-Windows統合**: WSLセッションからWindowsデスクトップへの注意喚起
- **開発者フォーカス管理**: 長時間アイドル時やパーミッション要求時の通知

## Value Proposition

- **軽量**: 単一のBashスクリプトで完結、外部依存は最小限
- **安全**: 入力検証とエスケープ処理によりセキュリティを確保
- **拡張可能**: 通知タイプに応じた挙動のカスタマイズが容易

---
_Focus on patterns and purpose, not exhaustive feature lists_

