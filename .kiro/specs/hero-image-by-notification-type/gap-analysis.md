# Implementation Gap Analysis

**Feature**: `hero-image-by-notification-type`
**Analysis Date**: 2026-01-09
**Language**: 日本語

---

## 1. Current State Investigation

### 既存コードベースの構成

**主要ファイル**:
- `mimikun-notify.sh`: 単一のBashスクリプト（115行）
  - セクション構成: Configuration → Logging → Security → Notification Title Logic → Main Logic

**既存の関連コンポーネント**:
- **Configuration Section** (lines 7-20):
  - `HEROIMAGE_BASE="$HOME/.mimikun/images/fuan.png"` (現在固定値)
  - TODO/コメントアウト行でPERMISSION_HEROIMAGEとIDLE_HEROIMAGEが既に定義されている（lines 12-15）
  - AppLogo用の`APPLOGO_BASE`変数が存在（line 19）

- **Notification Title Logic** (lines 42-58):
  - `get_notification_title()` 関数が存在
  - `notification_type`をcase文で分岐（permission_prompt / idle_prompt / default）
  - **パターン**: HeroImage選択ロジックに直接適用可能な既存パターン

- **Main Logic** (lines 64-110):
  - JSON解析で`notification_type`を抽出（line 72）
  - `wslpath -w`でWSL→Windows UNC変換（lines 88-89）
  - HeroImageは現在`$HEROIMAGE_BASE`を固定使用（line 89）

**アーキテクチャパターンと制約**:
- **単一スクリプト哲学**: 機能追加は新しいヘルパー関数として追加
- **命名規則**: `snake_case`関数、`UPPERCASE_SNAKE_CASE`定数
- **エラーハンドリング**: `set -euo pipefail`、関数は0/1で終了コード返却
- **セキュリティ**: `escape_for_powershell()`でPowerShell injection対策

**画像リソースの確認**:
- `$HOME/.mimikun/images/`ディレクトリに以下の画像が存在:
  - `permission_prompt.png` (4.5KB) - permission_prompt用HeroImage
  - `idle_prompt.png` (5.4KB) - idle_prompt用HeroImage
  - `fuan.png` (3.5KB) - デフォルトHeroImageとして使用予定
  - `ansin.png` (6.8KB) - 現在AppLogoとして使用
  - `corona.png`, `sick.png`, `tetoran.png` - 未使用

### 統合ポイント

1. **Configuration Section**: 新しいHeroImage変数定義の追加箇所
2. **新規ヘルパー関数**: `get_notification_title()`と同様の構造で`get_heroimage_path()`を追加
3. **Main Function**: line 89のheroimage変数割り当てロジックを変更

---

## 2. Requirements Feasibility Analysis

### 要件から導出される技術要素

#### 必要な実装要素:

1. **Configuration変数** (Requirement 1, 3):
   - `PERMISSION_HEROIMAGE`: permission_prompt用画像パス
   - `IDLE_HEROIMAGE`: idle_prompt用画像パス
   - `DEFAULT_HEROIMAGE`: フォールバック用画像パス
   - `HEROIMAGE_BASE`の削除

2. **ヘルパー関数** (Requirement 1, 3):
   - `get_heroimage_path(notification_type)`: notification_typeに応じた画像パスを返す
   - 既存の`get_notification_title()`と同じcase文パターンを使用

3. **Main Logic変更** (Requirement 2):
   - line 89: `heroimage=$(wslpath -w "$HEROIMAGE_BASE" ...)`
   - → `heroimage=$(wslpath -w "$(get_heroimage_path "$notification_type")" ...)`

#### ギャップと制約:

| 要件 | 既存の実装 | ギャップ | 制約 |
|------|-----------|---------|------|
| Req 1: 通知タイプ別HeroImage | `HEROIMAGE_BASE`固定 | ✅ **Missing**: 分岐ロジックと変数定義 | なし（既存パターン流用可能） |
| Req 2: 動的パス変換 | `wslpath -w`既に使用 | ✅ **Extend**: 動的パス取得に変更 | なし（既存機構を活用） |
| Req 3: 保守性・拡張性 | `get_notification_title()`パターン存在 | ✅ **Missing**: HeroImage版関数 | なし（パターン適用のみ） |
| Req 4: 互換性維持 | 既存ロジック安定 | なし | ✅ **Constraint**: 既存挙動保持必須 |

#### 複雑性シグナル:

- **単純な拡張**: 既存パターン（`get_notification_title`）の複製
- **外部統合なし**: すべてローカルBash内で完結
- **データモデル変更なし**: JSON入力スキーマ変更不要

---

## 3. Implementation Approach Options

### Option A: Extend Existing Script (推奨)

**対象ファイル**: `mimikun-notify.sh`

**変更箇所**:
1. **Configuration Section** (lines 12-20):
   - TODO/コメントアウト行削除（lines 12-15, 18）
   - 新しいreadonly変数定義を追加:
     ```bash
     readonly PERMISSION_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
     readonly IDLE_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
     readonly DEFAULT_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
     ```
   - `HEROIMAGE_BASE`行削除（line 20）

2. **新規セクション追加** (after line 58):
   ```bash
   #-----------------------------------------------------------
   # HeroImage Path Logic
   #-----------------------------------------------------------

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

3. **Main Logic修正** (line 89):
   - Before: `heroimage=$(wslpath -w "$HEROIMAGE_BASE" 2>/dev/null || echo "$HEROIMAGE_BASE")`
   - After:
     ```bash
     local heroimage_path
     heroimage_path=$(get_heroimage_path "$notification_type")
     heroimage=$(wslpath -w "$heroimage_path" 2>/dev/null || echo "$heroimage_path")
     ```

**互換性評価**:
- ✅ 既存の`get_notification_title`パターンを踏襲
- ✅ 既存のエラーハンドリング（wslpathフォールバック）維持
- ✅ AppLogo、PowerShellパラメータに影響なし
- ✅ 既存のテストケース（notification_type分岐）が同じロジックで動作

**保守性**:
- ✅ セクション分離により可読性維持
- ✅ 関数ベース設計で将来の通知タイプ追加が容易
- ✅ 変数名が明示的（PERMISSION_HEROIMAGE等）

**Trade-offs**:
- ✅ **Pros**:
  - 最小限の変更で要件を満たす
  - 既存パターンとの一貫性が高い
  - 単一スクリプト哲学に沿う
  - テスト・デバッグが容易
- ⚠️ **Cons**:
  - スクリプトが約20行増加（115行→135行程度）
  - Configuration sectionに3つの新しい変数追加

---

### Option B: Create Separate Configuration File

**概要**: HeroImage設定を外部設定ファイル（例: `~/.mimikun/heroimage-config.sh`）に分離

**実装方針**:
- Configuration fileを`source`コマンドでロード
- 変数定義を外部化

**Trade-offs**:
- ✅ **Pros**:
  - 設定変更時にスクリプト本体を変更不要
  - 複数の設定プロファイル切り替えが可能
- ❌ **Cons**:
  - **単一スクリプト哲学に反する** （steering/structure.mdの"Single-script utility"原則）
  - ファイル存在確認とエラーハンドリングが必要
  - デプロイ・配布が複雑化
  - 現在の要件（2つの通知タイプ）では過剰設計

**結論**: 現在のプロジェクトスコープには不適切 ❌

---

### Option C: Hybrid Approach - Dynamic Image Resolution

**概要**: 通知タイプと画像ファイル名の命名規則を統一し、動的にパス解決

**実装例**:
```bash
get_heroimage_path() {
    local type="$1"
    local image_dir="$HOME/.mimikun/images"

    # Try type-specific image first
    local type_image="${image_dir}/${type}.png"
    if [[ -f "$type_image" ]]; then
        echo "$type_image"
    else
        echo "${image_dir}/default.png"
    fi
}
```

**Trade-offs**:
- ✅ **Pros**:
  - 新しい通知タイプ追加時にコード変更不要
  - ファイルシステムベースの拡張性
- ❌ **Cons**:
  - **要件に明記されていない** （Requirement 3は明示的な変数定義を要求）
  - 実行時のファイル存在確認オーバーヘッド
  - デバッグが困難（画像が見つからない場合の原因特定）
  - 現在の画像ファイル名（`fuan.png`等）が通知タイプと一致しない

**結論**: 要件を超えた過剰設計、現在のスコープには不適切 ❌

---

## 4. Implementation Complexity & Risk

### Effort: **S (Small - 1-3 days)**

**理由**:
- 既存パターン（`get_notification_title`）の複製のみ
- 変更箇所が明確（Configuration + 新規関数 + Main Logic 1行変更）
- 外部依存やAPI統合なし
- テストケースも既存の通知タイプ分岐テストを流用可能

**見積もり内訳**:
- 実装: 1-2時間
- テスト（permission_prompt, idle_prompt, unknown type）: 1時間
- ドキュメント更新: 30分

### Risk: **Low（低リスク）**

**理由**:
- ✅ 確立されたパターンの適用（`get_notification_title`と同一構造）
- ✅ すべての技術スタック（Bash, wslpath, PowerShell）が既知
- ✅ 明確なスコープ（画像パス選択ロジックのみ）
- ✅ 最小限の統合箇所（Main functionの1箇所のみ変更）
- ✅ 既存機能への影響なし（互換性維持が要件）

**軽微なリスク**:
- ⚠️ TODO行削除時のタイポ（行番号ミス）→ Linter/shellcheckで検出可能
- ⚠️ 画像パスの誤り → 実行時エラー（wslpathでフォールバック済み）

---

## 5. Requirement-to-Asset Map

| 要件ID | 要件内容 | 既存アセット | 必要な変更 | ステータス |
|--------|---------|-------------|-----------|----------|
| Req 1.1 | permission_prompt用画像設定 | なし | `PERMISSION_HEROIMAGE`変数定義 | ✅ Missing |
| Req 1.2 | idle_prompt用画像設定 | なし | `IDLE_HEROIMAGE`変数定義 | ✅ Missing |
| Req 1.3 | 未知タイプのフォールバック | なし | `DEFAULT_HEROIMAGE`変数 + case文default | ✅ Missing |
| Req 1.4 | `HEROIMAGE_BASE`削除 | `HEROIMAGE_BASE` (line 20) | 行削除 | ✅ Missing |
| Req 2.1 | WSL→Windows UNC変換 | `wslpath -w` (line 89) | 既存機構活用 | ✅ Extend |
| Req 2.2 | wslpathフォールバック | `|| echo "$HEROIMAGE_BASE"` (line 89) | 既存ロジック維持 | ✅ Extend |
| Req 2.3 | PowerShell -HeroImageパラメータ | line 97 | 変更不要（変数のみ動的化） | ✅ OK |
| Req 3.1 | readonly変数定義 | Configuration section | 3つの新しいreadonly変数追加 | ✅ Missing |
| Req 3.2 | `DEFAULT_HEROIMAGE`変数 | なし | 変数定義 | ✅ Missing |
| Req 3.3 | `get_heroimage_path`関数 | なし | 新規関数実装 | ✅ Missing |
| Req 3.4 | TODO行削除 | lines 12-15, 18 | 行削除とコメント整理 | ✅ Missing |
| Req 4.1 | `get_notification_title`維持 | `get_notification_title` (lines 44-58) | 変更不要 | ✅ OK |
| Req 4.2 | `APPLOGO_BASE`維持 | `APPLOGO_BASE` (line 19) | 変更不要 | ✅ OK |
| Req 4.3 | PowerShellパラメータ維持 | lines 92-100 | 変更不要 | ✅ OK |
| Req 4.4 | エラーハンドリング維持 | `log_error`, exit codes | 変更不要 | ✅ OK |

---

## 6. Recommendations for Design Phase

### 推奨アプローチ: **Option A (Extend Existing Script)**

**理由**:
1. プロジェクトのsteering原則（Single-script utility）に完全準拠
2. 既存パターン（`get_notification_title`）の直接適用で一貫性確保
3. 最小限の変更で要件を完全に満たす
4. 低リスク・低コストで実装可能

### 設計フェーズでの主要決定事項

1. **画像パスの選択** (✅ Confirmed):
   - `permission_prompt`: `$HOME/.mimikun/images/permission_prompt.png`
   - `idle_prompt`: `$HOME/.mimikun/images/idle_prompt.png`
   - デフォルト（未知の通知タイプ）: `$HOME/.mimikun/images/fuan.png`

2. **関数命名** (Minor):
   - `get_heroimage_path()` vs `get_notification_heroimage()` vs `resolve_heroimage_path()`
   - **推奨**: `get_heroimage_path()` （`get_notification_title()`との一貫性）

3. **テスト戦略**:
   - 既存のテストコマンド（`echo '{"notification_type":"permission_prompt","message":"Test"}' | ./mimikun-notify.sh`）を使用
   - 3つのテストケース:
     1. `notification_type: permission_prompt`
     2. `notification_type: idle_prompt`
     3. `notification_type: unknown` (or JSON without field)

### 研究項目（設計フェーズ持ち越し）

- **なし**: すべての技術要素が既知、外部調査不要

### 次のステップ

画像マッピングが確定しました。以下コマンドで設計フェーズに進んでください:
```bash
/kiro:spec-design hero-image-by-notification-type
```

---

## Appendix: Code Change Preview

### Configuration Section (Before)
```bash
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
```

### Configuration Section (After - Option A)
```bash
#-----------------------------------------------------------
# Configuration
#-----------------------------------------------------------

readonly PWSH_EXE="/mnt/c/Program Files/PowerShell/7/pwsh.exe"
readonly APPLOGO_BASE="$HOME/.mimikun/images/ansin.png"
readonly PERMISSION_HEROIMAGE="$HOME/.mimikun/images/permission_prompt.png"
readonly IDLE_HEROIMAGE="$HOME/.mimikun/images/idle_prompt.png"
readonly DEFAULT_HEROIMAGE="$HOME/.mimikun/images/fuan.png"
readonly DEFAULT_TITLE="Claude Code - 通知"
readonly DEFAULT_MESSAGE="通知メッセージがありません"
```

### New Function (After line 58)
```bash
#-----------------------------------------------------------
# HeroImage Path Logic
#-----------------------------------------------------------

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

### Main Logic (Before - line 89)
```bash
heroimage=$(wslpath -w "$HEROIMAGE_BASE" 2>/dev/null || echo "$HEROIMAGE_BASE")
```

### Main Logic (After - lines 89-91)
```bash
local heroimage_path
heroimage_path=$(get_heroimage_path "$notification_type")
heroimage=$(wslpath -w "$heroimage_path" 2>/dev/null || echo "$heroimage_path")
```
