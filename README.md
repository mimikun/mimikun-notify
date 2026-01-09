# WSLからWindowsに通知を送るスクリプト

## 概要

WSLからWindows 10/11のトースト通知を送るスクリプトです。

Claude Code Hooksからの通知を受け取り、`notification_type` に応じて適切なタイトルで通知を表示します。

## 機能

- ✅ stdin経由でJSON入力を受け取り
- ✅ jqで `notification_type` と `message` フィールドを抽出
- ✅ `notification_type` に応じたタイトル表示
    - `permission_prompt`: "Claude Code - 許可の要求"
    - `idle_prompt`: "Claude Code - 入力待ち"
    - その他: "Claude Code - 通知"（デフォルト）
- ✅ エラーハンドリング（JSON解析失敗時はデフォルト値使用）
- ✅ セキュリティ対策（シングルクォートエスケープ）

## 使用方法

### 基本的な使い方

```bash
echo '{"notification_type":"permission_prompt","message":"Claude needs your permission to use Bash"}' | ./mimikun-notify.sh
```

### Claude Code Hooksとの統合

`~/.claude/settings.json`に以下を追加：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/mimikun-notify.sh"
          }
        ]
      },
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/mimikun-notify.sh"
          }
        ]
      }
    ]
  }
}
```

## 要件

- Windows
    - PowerShell 7.x
        - BurntToast Module
- WSL2
    - Bash
    - jq

## テスト結果

すべてのテストが正常に完了しました：

### 正常系テスト

- ✅ `permission_prompt` 通知の表示
- ✅ `idle_prompt` 通知の表示
- ✅ 不明な `notification_type` でのデフォルトタイトル表示

### 異常系テスト

- ✅ `message` フィールドなしでデフォルトメッセージ使用
- ✅ 空のJSONでデフォルト値使用
- ✅ 不正なJSONでデフォルト値使用

### セキュリティテスト

- ✅ シングルクォートを含むメッセージの安全な処理
- ✅ 特殊文字( `$VAR`, `command` など)の安全な処理

### パフォーマンス

- 実行時間: 約2.5秒(JSON処理 + PowerShell起動 + 通知表示)

## 技術仕様

### Notification Input

https://code.claude.com/docs/en/hooks#notification-input

Claude Code Hooksから送信されるJSON形式：

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../00893aaf-19fa-41d2-8238-13269b9b3ca0.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "Notification",
  "message": "Claude needs your permission to use Bash",
  "notification_type": "permission_prompt"
}
```

### `notification_type` の種類

- `permission_prompt`: Permission requests from Claude Code
- `idle_prompt`: When Claude is waiting for user input (after 60+ seconds of idle time)

## トラブルシューティング

### 通知が表示されない

#### 1. PowerShell 7.xがインストールされているか確認：

```bash
"/mnt/c/Program\ Files/PowerShell/7/pwsh.exe" -Version
```

#### 2. BurntToastモジュールがインストールされているか確認：

```bash
"/mnt/c/Program\ Files/PowerShell/7/pwsh.exe" -Command "Get-Module -ListAvailable BurntToast"
```

#### 3. 画像ファイルが存在するか確認：

<!-- TODO: it -->

```bash
ls -l ~/.mimikun/images/ansin.png
ls -l ~/.mimikun/images/fuan.png
```

### 文字化けが発生する

WSLのロケールをUTF-8に設定:

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

