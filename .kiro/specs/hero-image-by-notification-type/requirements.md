# Requirements Document

## Project Description (Input)

notification_typeに応じた画像をHeroImageに設定する

## Introduction

現在のmimikun-notifyスクリプトは、すべての通知で同一のHeroImage画像（`fuan.png`）を使用しています。通知タイプ（`notification_type`）に応じて適切な画像を表示することで、ユーザーに視覚的な文脈を提供し、通知の種類を直感的に識別できるようにします。

現状の問題点:
- すべての通知で`HEROIMAGE_BASE="$HOME/.mimikun/images/fuan.png"`が固定使用されている
- `notification_type`が`permission_prompt`か`idle_prompt`かに関わらず同じ画像が表示される
- 通知タイプに応じた視覚的な差別化ができていない

## Requirements

### Requirement 1: 通知タイプ別のHeroImage設定

**Objective:** As a ユーザー, I want 通知タイプに応じた適切なHeroImage画像を表示してほしい, so that 通知の種類を視覚的に識別できる

#### Acceptance Criteria

1. When `notification_type`が`permission_prompt`の場合, the mimikun-notifyスクリプト shall `PERMISSION_HEROIMAGE`変数で定義されたパスの画像をHeroImageとして設定する
2. When `notification_type`が`idle_prompt`の場合, the mimikun-notifyスクリプト shall `IDLE_HEROIMAGE`変数で定義されたパスの画像をHeroImageとして設定する
3. When `notification_type`が未知の値またはJSONに存在しない場合, the mimikun-notifyスクリプト shall デフォルトのHeroImage画像をフォールバックとして使用する
4. The mimikun-notifyスクリプト shall `HEROIMAGE_BASE`変数を削除し、通知タイプごとの専用変数を使用する

### Requirement 2: 画像パスの動的変換

**Objective:** As a システム, I want 通知タイプに応じた画像パスをWindows UNC形式に変換したい, so that PowerShell BurntToast通知が正しく画像を読み込める

#### Acceptance Criteria

1. When HeroImage画像パスが決定された後, the mimikun-notifyスクリプト shall `wslpath -w`を使用してWSLパスをWindows UNC形式に変換する
2. If `wslpath`変換が失敗した場合, then the mimikun-notifyスクリプト shall 元のパスをフォールバック値として使用する
3. The mimikun-notifyスクリプト shall 変換されたWindows UNCパスをPowerShellの`-HeroImage`パラメータに渡す

### Requirement 3: 設定の保守性と拡張性

**Objective:** As a 開発者, I want 通知タイプ別の画像設定を明確に定義したい, so that 将来的な通知タイプの追加が容易になる

#### Acceptance Criteria

1. The mimikun-notifyスクリプト shall Configuration セクションで`PERMISSION_HEROIMAGE`と`IDLE_HEROIMAGE`をreadonly変数として定義する
2. The mimikun-notifyスクリプト shall デフォルトHeroImage用の`DEFAULT_HEROIMAGE`変数を定義する
3. The mimikun-notifyスクリプト shall `get_heroimage_path`関数（または類似の命名）を実装し、`notification_type`を受け取ってHeroImage画像パスを返す
4. The mimikun-notifyスクリプト shall コメントアウトされたTODO行（line 12-15, 18）を削除し、新しい実装に置き換える

### Requirement 4: 既存機能との互換性維持

**Objective:** As a ユーザー, I want 既存の通知機能が正常に動作し続けてほしい, so that この変更によって通知システムが破損しない

#### Acceptance Criteria

1. The mimikun-notifyスクリプト shall `get_notification_title`関数の既存挙動を変更せず維持する
2. The mimikun-notifyスクリプト shall `AppLogo`画像（`APPLOGO_BASE`）の設定と使用方法を変更しない
3. The mimikun-notifyスクリプト shall PowerShell BurntToast通知の他のパラメータ（`-Text`, `-Sound`, `-Attribution`, `-Urgent`）を現状のまま維持する
4. The mimikun-notifyスクリプト shall エラーハンドリングとロギングの既存ロジックを維持する

