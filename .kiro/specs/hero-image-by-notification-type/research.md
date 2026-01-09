# Research & Design Decisions

---
**Purpose**: 発見プロセスの調査結果、アーキテクチャ検討、設計判断の根拠を記録する。

**Usage**:
- 発見フェーズの調査活動と成果を記録
- `design.md`に記載するには詳細すぎる設計判断のトレードオフを文書化
- 将来の監査や再利用のための参照と証拠を提供

---

## Summary

- **Feature**: `hero-image-by-notification-type`
- **Discovery Scope**: Extension（既存スクリプトの拡張）
- **Key Findings**:
  - 既存の`get_notification_title()`関数パターンがHeroImage選択ロジックに直接適用可能
  - `permission_prompt.png`と`idle_prompt.png`が専用画像として既に配置済み
  - 変更箇所は3箇所のみ（Configuration変数、新規関数、Main Logic）で最小限の影響

## Research Log

### Extension Point Analysis

- **Context**: 既存の`mimikun-notify.sh`スクリプトに通知タイプ別HeroImage選択機能を追加
- **Sources Consulted**:
  - `mimikun-notify.sh` (lines 1-115)
  - `.kiro/steering/structure.md` (Single-script utility原則)
  - `.kiro/specs/hero-image-by-notification-type/gap-analysis.md`
- **Findings**:
  - 既存の`get_notification_title()`関数（lines 44-58）が理想的なパターンを提供
  - case文による分岐ロジック（permission_prompt / idle_prompt / default）が同じ構造で適用可能
  - Configuration sectionに既にTODOコメントで`PERMISSION_HEROIMAGE`と`IDLE_HEROIMAGE`が記載済み（lines 14-15）
  - Main Logic内でHeroImageパス選択を行う統合ポイントが明確（line 89）
- **Implications**:
  - 新規ヘルパー関数`get_heroimage_path()`を追加し、`get_notification_title()`と対称的な実装を行う
  - 既存パターンの一貫性を保つことで、コードの可読性と保守性が向上
  - TODO行削除とクリーンアップが必要（lines 12-15, 18）

### Dependency & Compatibility Check

- **Context**: `wslpath`コマンドとPowerShell BurntToast通知の互換性確認
- **Sources Consulted**:
  - `.kiro/steering/tech.md` (wslpathの既存利用)
  - `mimikun-notify.sh` (lines 88-89: 既存のwslpath使用箇所)
- **Findings**:
  - `wslpath -w`は既にAppLogoとHeroImageの変換に使用されている
  - フォールバックメカニズム（`|| echo "$PATH"`）が既に実装されている
  - PowerShell BurntToastの`-HeroImage`パラメータは既知の機能で追加調査不要
- **Implications**:
  - 既存のパス変換ロジックをそのまま流用可能
  - エラーハンドリングとフォールバックが既に適切に実装されているため、新規実装不要
  - 動的パス取得関数（`get_heroimage_path()`）の出力を既存の`wslpath`パイプラインに接続するだけで対応可能

### Image Resource Verification

- **Context**: 通知タイプ別の画像ファイルの存在確認
- **Sources Consulted**:
  - `$HOME/.mimikun/images/`ディレクトリ（`ls -la`実行結果）
- **Findings**:
  - `permission_prompt.png` (4.5KB) - 2026-01-09 23:55作成
  - `idle_prompt.png` (5.4KB) - 2026-01-09 23:55作成
  - `fuan.png` (3.5KB) - デフォルト用として使用予定
  - すべての画像ファイルが既に配置済みで、実装時の追加作業不要
- **Implications**:
  - Configuration変数で以下のパスを設定:
    - `PERMISSION_HEROIMAGE="$HOME/.mimikun/images/permission_prompt.png"`
    - `IDLE_HEROIMAGE="$HOME/.mimikun/images/idle_prompt.png"`
    - `DEFAULT_HEROIMAGE="$HOME/.mimikun/images/fuan.png"`
  - 画像ファイル名が通知タイプと一致しており、明示的で保守性が高い

## Architecture Pattern Evaluation

| Option | Description | Strengths | Risks / Limitations | Notes |
|--------|-------------|-----------|---------------------|-------|
| **Option A: Extend Existing Script** | Configuration変数追加 + 新規ヘルパー関数 + Main Logic 1行変更 | 既存パターン踏襲、最小限の変更、単一スクリプト哲学に準拠 | スクリプトが約20行増加 | **選択**: gap-analysis.mdで推奨、steering原則に完全準拠 |
| Option B: Separate Configuration File | 外部設定ファイル（`~/.mimikun/heroimage-config.sh`）に変数を分離 | 設定変更時にスクリプト変更不要 | 単一スクリプト哲学に反する、デプロイ複雑化 | 却下: steering/structure.mdの"Single-script utility"原則違反 |
| Option C: Dynamic Image Resolution | ファイルシステムベースの動的パス解決（実行時にファイル存在確認） | 新通知タイプ追加時のコード変更不要 | Requirement 3で明示的な変数定義を要求、デバッグ困難 | 却下: 要件を超えた過剰設計 |

## Design Decisions

### Decision: `get_heroimage_path()` Function Implementation

- **Context**: 通知タイプに応じたHeroImage画像パスを動的に選択するロジックが必要（Requirements 1, 3）
- **Alternatives Considered**:
  1. **Option A: ヘルパー関数アプローチ** - `get_notification_title()`と同じcase文パターンを使用
  2. **Option B: Main Logic内でインライン実装** - case文をmain()関数内に直接記述
  3. **Option C: 連想配列による実装** - Bash 4.0の連想配列機能を使用してマッピング定義
- **Selected Approach**: **Option A - ヘルパー関数アプローチ**
  ```bash
  get_heroimage_path() {
      local type="$1"
      case "$type" in
      permission_prompt)
          echo "$PERMISSION_HEROIMAGE"
          ;;
      idle_prompt)
          echo "$IDLE_HEROIMAGE"
          ;;
      *)
          echo "$DEFAULT_HEROIMAGE"
          ;;
      esac
  }
  ```
- **Rationale**:
  - 既存の`get_notification_title()`関数（lines 44-58）と構造が一致し、コードの一貫性が保たれる
  - 関数ベース設計により、将来的な通知タイプ追加時の変更箇所が明確化
  - Section-Based Layout（steering/structure.md）に準拠し、"HeroImage Path Logic"セクションとして独立配置
  - テスト時に関数単体でのテストが可能（Main Logicと分離）
- **Trade-offs**:
  - **Benefits**: 可読性向上、保守性向上、既存パターンとの一貫性、テスタビリティ
  - **Compromises**: 約15行のコード追加（関数定義 + セクションヘッダー）
- **Follow-up**: 実装時にshellcheckでリント検証、3つの通知タイプでの動作テスト実施

### Decision: Configuration Variable Naming and Placement

- **Context**: 通知タイプ別の画像パスを定義するreadonly変数が必要（Requirement 3.1, 3.2）
- **Alternatives Considered**:
  1. **Option A: 明示的な変数名** - `PERMISSION_HEROIMAGE`, `IDLE_HEROIMAGE`, `DEFAULT_HEROIMAGE`
  2. **Option B: プレフィックス統一** - `HEROIMAGE_PERMISSION`, `HEROIMAGE_IDLE`, `HEROIMAGE_DEFAULT`
  3. **Option C: 配列ベース** - `HEROIMAGE_PATHS[permission_prompt]="..."`
- **Selected Approach**: **Option A - 明示的な変数名**
  ```bash
  readonly PERMISSION_HEROIMAGE="$HOME/.mimikun/images/permission_prompt.png"
  readonly IDLE_HEROIMAGE="$HOME/.mimikun/images/idle_prompt.png"
  readonly DEFAULT_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
  ```
- **Rationale**:
  - 既存の命名規則（`DEFAULT_TITLE`, `DEFAULT_MESSAGE`, `APPLOGO_BASE`）と一貫性を保つ
  - 通知タイプが変数名の先頭にあることで、通知タイプ別のグルーピングが明確
  - コメントアウトされたTODO行（lines 14-15）で既に`PERMISSION_HEROIMAGE`と`IDLE_HEROIMAGE`の命名が使用されていた
  - Configuration sectionでの配置順序: PWSH_EXE → APPLOGO_BASE → PERMISSION_HEROIMAGE → IDLE_HEROIMAGE → DEFAULT_HEROIMAGE → DEFAULT_TITLE → DEFAULT_MESSAGE（論理的なグルーピング）
- **Trade-offs**:
  - **Benefits**: 既存コードとの一貫性、可読性、明示的な意図表現
  - **Compromises**: 変数数が3つ増加（Configuration sectionの肥大化）
- **Follow-up**: TODO行（lines 12-15, 18）の削除とクリーンアップ、`HEROIMAGE_BASE`の完全削除

### Decision: Main Logic Integration Point

- **Context**: HeroImage画像パスの動的取得をMain Logicに統合する方法（Requirement 2）
- **Alternatives Considered**:
  1. **Option A: 2ステップアプローチ** - `heroimage_path=$(get_heroimage_path ...)` → `heroimage=$(wslpath -w ...)`
  2. **Option B: 1ステップアプローチ** - `heroimage=$(wslpath -w "$(get_heroimage_path ...)" ...)`
  3. **Option C: パイプライン** - `get_heroimage_path ... | wslpath -w`
- **Selected Approach**: **Option A - 2ステップアプローチ**
  ```bash
  local heroimage_path
  heroimage_path=$(get_heroimage_path "$notification_type")
  heroimage=$(wslpath -w "$heroimage_path" 2>/dev/null || echo "$heroimage_path")
  ```
- **Rationale**:
  - `set -euo pipefail`の厳密なエラーハンドリングと相性が良い（中間変数でエラー検出可能）
  - デバッグ時に`heroimage_path`の値を確認可能（トラブルシューティングが容易）
  - 既存のAppLogo変換ロジック（line 88）と構造が類似し、コードの一貫性を保つ
  - Option Bは読みにくく、Option Cはパイプラインでのエラーハンドリングが複雑化
- **Trade-offs**:
  - **Benefits**: デバッグ性、エラーハンドリングの明確性、既存パターンとの一貫性
  - **Compromises**: 1行追加（中間変数定義）
- **Follow-up**: wslpathフォールバックの動作確認、エラーログ出力の検証

## Risks & Mitigations

- **Risk 1: TODO行削除時のタイポ** — 行番号ミスでコードを誤削除する可能性
  - **Mitigation**: shellcheckでリント検証、git diffでの変更内容確認、テスト実行前にコードレビュー
- **Risk 2: 画像ファイルパスの誤り** — タイポや不正なパスで実行時エラー
  - **Mitigation**: wslpathのフォールバックメカニズムが既に実装済み（元のパスを使用）、テスト時に3つの通知タイプで実画像表示確認
- **Risk 3: 既存機能への影響** — AppLogoや他のBurntToastパラメータへの意図しない影響
  - **Mitigation**: Requirement 4で互換性維持を明確化、変更箇所がHeroImage関連のみに限定されている、既存のテストケースを再実行

## References

- [Bash Case Statement Documentation](https://www.gnu.org/software/bash/manual/html_node/Conditional-Constructs.html#index-case) — case文の構文と使用方法
- [wslpath Command Reference](https://learn.microsoft.com/en-us/windows/wsl/filesystems#wslpath) — WSL↔Windowsパス変換の公式ドキュメント
- [BurntToast PowerShell Module](https://github.com/Windos/BurntToast) — Windows Toast通知ライブラリの公式リポジトリ
- `.kiro/specs/hero-image-by-notification-type/gap-analysis.md` — 実装ギャップ分析レポート（詳細な変更箇所とコードプレビュー）
