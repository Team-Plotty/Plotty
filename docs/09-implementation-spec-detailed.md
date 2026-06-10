# 09. 実装要件仕様（詳細版）

実装で参照しやすい粒度で整理した、要件仕様の詳細版（正本）。

---

## 1. コンセプトと体験要件

## 1.1 コンセプト

- 単一チャット入力から、AI が `schedule` / `task` / `memo` へ半自動振り分けする。
- ユーザーは必要に応じてカテゴリを明示できる（ハイブリッド入力）。

## 1.2 ハイブリッド入力要件

- 事前カテゴリ選択 UI（送信前）
- AI 推論アシスト（入力中）
  - キー入力ごとの API 呼び出しは行わない
  - 500ms デバンス、または送信直前確認で推論
- 後付け修正（送信後）
  - メッセージ削除後（30日超）は相対参照の修正不可

## 1.3 UXフロー

1. 入力（自由文 + 任意カテゴリ）
2. 解析・登録（AI抽出 + データ生成）
3. 確認カード表示
4. ストック表示（カレンダー/リスト）

---

## 2. MVP スコープ

## 2.1 MVPに含める

- 高精度な抽出（日時/内容/カテゴリ）
- カテゴリ選択と確認フロー
- 登録直後のリスト反映（ローカル状態更新）

## 2.2 MVPから除外

- OS標準カレンダー連携（Phase 2）
- オフライン送信キュー
- プッシュ通知

## 2.3 同期方針

- Realtime 非依存を基本とする
- Edge 成功レスポンスでクライアントの単一状態を更新
- 再読み込みで最終整合性を担保

---

## 3. データモデル詳細

## 3.1 テーブル構成

- `public.users`: 認証拡張プロファイル
- `messages`: 対話ログ（30日保持）
- `schedules`: 予定
- `tasks`: タスク
- `memos`: メモ

## 3.2 `public.users`（推奨カラム）

| カラム | 型 | 用途 |
|---|---|---|
| `id` | uuid PK | `auth.users.id` と一致 |
| `display_name` | text | 表示名 |
| `avatar_url` | text | アイコンURL |
| `timezone` | text | 自然言語日時解釈に使用 |
| `default_category` | text | 判定不能時の既定 |
| `ai_persona_config` | jsonb | AI口調設定 |
| `encryption_key_id` | text | Vault 鍵参照ID |
| `created_at` | timestamptz | 作成日時 |

## 3.3 `messages`（確定）

| カラム | 型 | 用途 |
|---|---|---|
| `id` | uuid PK | メッセージID |
| `user_id` | uuid FK | 所有者 |
| `role` | text | `user` / `assistant` |
| `content_encrypted` | text | 暗号化本文 |
| `iv` | text | 本文復号用 IV |
| `related_entities` | jsonb | `[{type,id}]` の生成先参照 |
| `analysis_results_encrypted` | jsonb | `{"iv":"...","data":"..."}` |
| `created_at` | timestamptz | 作成日時（UTC） |
| `expires_at` | timestamptz | 削除判定用（`created_at + 720時間`。DB は **GENERATED 列ではなく INSERT 前トリガー**で値を設定する。※`timestamptz` の生成列式が immutable と見なされず失敗するため） |

`related_entities` 例:

```json
[
  { "type": "schedule", "id": "uuid-1" },
  { "type": "task", "id": "uuid-2" }
]
```

`analysis_results_encrypted` 例:

```json
{
  "iv": "base64-iv",
  "data": "base64-ciphertext"
}
```

## 3.4 実体テーブル共通

| カラム | 型 | 用途 |
|---|---|---|
| `id` | uuid PK | 実体ID |
| `user_id` | uuid FK | 所有者 |
| `source_message_id` | uuid FK nullable | 元メッセージ（`ON DELETE SET NULL`） |
| `origin_text_encrypted` | text | 元文バックアップ |
| `title_encrypted` | text | タイトル |
| `title_hash` | text | 検索用ハッシュ |
| `iv` | text | 復号用 IV |
| `is_deleted` | boolean | 論理削除 |
| `created_at` | timestamptz | 作成日時 |
| `updated_at` | timestamptz | 更新日時 |

## 3.5 個別カラム

### `schedules`

- `start_at` timestamptz
- `end_at` timestamptz
- `is_all_day` boolean
- `location` text（MVPでは平文）

### `tasks`

- `is_completed` boolean
- `due_date` timestamptz
- `priority` integer（1/2/3）

### `memos`

- `content_encrypted` text
- `is_pinned` boolean

---

## 4. 暗号化・鍵管理

## 4.1 暗号化範囲

- `title` / `content` / `origin_text` を対象
- 検索用は `title_hash`（HMAC-SHA256 + ペッパー）

## 4.2 鍵管理

- ユーザー単位 DEK を推奨
- DEK は KEK でラップして Vault 管理
- 鍵素材と復号ロジックはクライアントへ配布しない

## 4.3 責務分担

- 暗号化/復号は Edge 主体
- DB直参照時は暗号文のみ見える状態を前提

---

## 5. 認証とアカウント要件

## 5.1 プロバイダ

- Google OAuth
- Email（マジックリンク/OTP）
- Sign in with Apple

## 5.2 ユーザー作成フロー

1. `auth.users` に作成
2. DBトリガーで `public.users` 自動作成
3. `encryption_key_id` は初期 null 許容
4. 初回実利用時に Edge で鍵発行・更新

## 5.3 アカウントリンク

- 同一メールは Supabase のリンク機能で自動統合
- 異なるメールは MVP では別アカウント
- 手動統合UIは Phase 2 以降
- Apple Relay で分裂し得るため、初回プロバイダを記録し同方式ログインを推奨

---

## 6. AI/Groq 実行要件

- 本番モデル: `llama-3.3-70b-versatile`
- 開発モデル: `llama-3.1-8b-instant`
- タイムアウト: 10秒
- リトライ: 最大1回
- APIキーは Edge 側のみ保持

`ai_persona_config` 例:

```json
{
  "name": "Plotty",
  "tone": "friendly",
  "identity": "優秀な秘書",
  "prohibited_topics": ["politics", "religion"]
}
```

LLMへ渡すのは会話制御項目のみとし、システム管理値は含めない。

---

## 7. データ保持と削除

- `messages` は 30日（720時間）で物理削除
- 判定基準は UTC
- `pg_cron` で毎日実行
- 実体は `source_message_id = NULL` へ遷移し保持

---

## 8. 用語・命名ルール

- 元メッセージ参照は `source_message_id` に統一
- 生成先参照は `related_entities` に統一
- 旧名称（`message_id` / `related_entity_type` など）は新実装で使用しない

---

## 9. 実装前チェック

1. `related_entities` を `[{type,id}]` で実装統一しているか
2. `analysis_results_encrypted` を `iv + data` で統一しているか
3. Edge 以外に復号経路がないか
4. RLS が `auth.uid() = user_id` で網羅されているか
5. 30日削除ジョブの監視導線があるか

---

## 10. Edge ランタイム（Supabase Edge Functions）

### 10.1 決定事項

- API 層は **Supabase Edge Functions** でホストする（Cloudflare Workers は不採用）。
- 関数名（MVP）: **`plotty-api`**
- ロジックの正本: リポジトリ `edge/` の router / handler / contracts（移植元）

### 10.2 デプロイ構成

| 項目 | 内容 |
|---|---|
| 配置 | `supabase/functions/plotty-api/index.ts`（入口）+ 共有モジュール |
| Secrets | `GROQ_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `APP_ENCRYPTION_KEY_BASE64` 等 |
| 公開 URL | `https://<project-ref>.supabase.co/functions/v1/plotty-api/api/v1/...` |
| ローカル | `supabase functions serve plotty-api --env-file supabase/.env.local` |
| 本番 | `supabase functions deploy plotty-api` |

### 10.3 ランタイム制約（Hosted）

- Wall clock: Free で最大 150s（Groq 10s タイムアウトは問題なし）
- CPU time: 2s / req（I/O 除く）— 暗号 + JSON 処理向き
- Invocations: Free で 50 万 / 月（低利用 MVP 向き）

### 10.4 iOS 接続

- Base URL: Supabase プロジェクトの Functions URL + `/plotty-api`
- 認証: Supabase Auth の access token を Bearer に付与
- 詳細 URL 例は `10` §3

### 10.5 運用上の注意

- Supabase Free プロジェクトは **1 週間 API 無操作で pause** されうる。個人 MVP では手動 resume または軽い keep-alive で対処（`08` 未決項目）。
- `service_role` は Function 内のみ。クライアント・RLS ユーザー JWT からは参照不可。

### 10.6 API 契約

- MVP の Request/Response・DTO・冪等・reclassify: **`docs/contracts/api-contract-mvp.md`**
- 実装施工メモ（mapper・migration・doc 正本）: **`docs/contracts/implementation-notes.md`**
