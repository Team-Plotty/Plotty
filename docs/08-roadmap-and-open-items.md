# 08. ロードマップと未決項目

要件の正本は `01`〜`13`（特に `09` / `10` / `11`）。本ファイルは **MVP までの実装ペース・残タスク・未決事項** を管理する。

---

## 現状サマリ（2026/06/03 時点）

| 領域 | 進捗 | 備考 |
|---|---|---|
| iOS UI（SwiftUI） | おおむね完成 | 全画面・Liquid Glass・共通状態 UI あり |
| iOS ↔ Edge 接続 | 未着手 | `PlotAPIClient` 等なし。データはモック |
| Edge API | 部分完成 | `edge/` に handler あり。Supabase Edge Functions（`plotty-api`）へデプロイ・reclassify 未 |
| Supabase 運用 | DDL のみ | migration 適用・cron・auth トリガーは未 |
| 認証 | 部分完成 | Google OAuth のみ実装。Apple / Email はモック |

**ボトルネック:** iOS から Edge への接続と Supabase 本番化。UI シェルは先行しているため、以降は **バックエンド接続 → 認証本番化 → 体験仕上げ** の順が効率的。

---

## インフラ方針（Edge / コスト）

### Edge とは（本プロダクトでの意味）

docs の **Edge** は「iOS と Supabase の間に立つ API サーバー」の総称。`06` / `10` の責務:

- Supabase JWT の検証
- Groq 呼び出し（API キーは Edge のみ保持）
- 暗号化 / 復号
- DB 読み書き（`service_role` は Edge 内のみ）

iOS は **Edge の HTTPS URL** に JSON でリクエストするだけ（Web ブラウザ専用ではない）。

### Edge ランタイム: Supabase Edge Functions（確定）

**2026/06/03 決定:** Plotty の API 層は [Supabase Edge Functions](https://supabase.com/docs/guides/functions)（Deno）でホストする。Cloudflare Workers は不採用。

| 項目 | 内容 |
|---|---|
| 関数名（仮） | `plotty-api`（変更可。iOS の Base URL とセットで更新） |
| 公開 URL | `https://<project-ref>.supabase.co/functions/v1/plotty-api/...` |
| アプリ内パス | `/api/v1/chat/messages` 等（`10` §3 と同一契約） |
| ソース配置 | `supabase/functions/plotty-api/`（`edge/` のロジックを移植・統合） |
| 秘密情報 | Supabase Dashboard → Edge Functions Secrets（Groq キー、`service_role`、暗号鍵） |
| JWT | リクエスト `Authorization: Bearer <supabase_access_token>`。Function 内で検証 |

**Workers 形式からの差分（A4）:**

- 入口: `export default { fetch }` → `Deno.serve` + ルーター
- デプロイ: `supabase functions deploy plotty-api`
- ローカル: `supabase functions serve plotty-api`

`edge/` 配下の handler / contract / service は **可能な限りそのまま再利用** し、ランタイム adapter のみ差し替える。

### 無料枠で収めるための前提（2026 年時点の目安）

MVP は **個人〜小規模利用** を想定し、以下で設計する。公式 limit は変更され得るため、リリース前に各ダッシュボードで再確認する。

| サービス | 無料枠の目安 | Plotty での用途 | 注意 |
|---|---|---|---|
| **Supabase（全体）** | Free プロジェクト | Auth、DB、RLS、Edge Functions | **1 週間無操作で pause**（データは保持、手動 resume 可） |
| **Supabase Edge Functions** | 50 万 invocations / 月 | API 本体 | CPU **2s / req**（I/O 除く）。低利用なら十分 |
| **Groq** | 無料クレジット / レート制限あり | LLM 抽出 | **コストの主因**。B7 の日次トークン上限とセット |
| **Apple Developer** | 登録済み（コスト懸念外） | App Store / TestFlight 配布 | — |

**Supabase Edge Functions で特に気をつける点:**

- **プロジェクト pause:** 個人利用で長期未使用時に API が止まる。必要なら週次 ping または手動 resume（`08` 意思決定ログ参照）。
- **レート制限:** in-memory のみではインスタンス跨ぎで抜ける。**日次トークン集計は Postgres テーブル**（`05` §利用量制限）。
- **鍵管理:** MVP は Edge Functions Secrets + 環境変数。docs の Vault 参照は将来拡張。

**コスト方針:**

- MVP: **Supabase Free + Groq 無料枠**（追加 PaaS アカウント不要）
- Groq 超過リスク: user 日次トークン上限 → dev 用 8B モデル → 上限引き下げ
- App Store: Developer 登録済み
- Groq 日次上限: 初期 50k tokens / user / day（`05` §利用量制限）

---

## ブランチ命名

README の `feature/<category>-<topic>` に従う。**1 機能 1 ブランチ**。作業前に `main` を最新化する。

| category の目安 | 用途 |
|---|---|
| `feature/` | 機能追加・本番接続 |
| `fix/` | バグ修正 |
| `docs/` | ドキュメントのみ |
| `clean/` | モック削除・整理 |

以下、各タスクに推奨ブランチ名を記載する（Phase 名はブランチに含めない）。

---

## MVP 実装ペース（推奨順序）

依存関係を踏まえ、以下の Phase 順で進める。各 Phase 完了時に「動作確認できる単位」を設ける。

```mermaid
flowchart TD
    A[Phase A: 基盤] --> B[Phase B: Edge API 完成]
    A --> D[Phase D: 認証本番化]
    B --> C[Phase C: iOS 接続]
    D --> C
    C --> E[Phase E: 体験仕上げ]
    C --> F[Phase F: リリース前チェック]
    F --> G[Phase G: モック削除]
```

### Phase A — 基盤（Supabase + Edge デプロイ）

**目的:** 本番相当の DB・API 実行環境を用意する。

| # | タスク | ブランチ | 参照 |
|---|---|---|---|
| A1 | `edge/sql/plotty_schema.sql` を Supabase migration として適用 | `feature/supabase-schema-migration` | `13` |
| A2 | `auth.users` → `public.users` 自動作成トリガーを適用 | `feature/supabase-auth-user-trigger` | `04`, `09`, `13` |
| A3 | `messages` 30 日削除 cron（`edge/sql/messages-retention-job.sql`） | `feature/messages-retention-cron` | `02`, `07` |
| A4 | `edge/` を Supabase Edge Function（`plotty-api`）としてデプロイ。Secrets 設定 | `feature/supabase-edge-functions-deploy` | `05`, `06`, `09` §10, 本ファイル §インフラ |
| A5 | iOS に Edge Base URL を設定（`.../functions/v1/plotty-api`） | `feature/ios-edge-base-url` | `06`, `10` §3 |
| A6 | RLS を migration 化し、本番と開発で同一手順にする | `feature/supabase-rls-migrations` | `07`, `13` |

**完了条件:** curl / 統合テストで JWT 付き `POST /api/v1/chat/messages` が本番 DB に書き込める。

**推奨マージ順:** A1 → A2 → A6 → A3 → A4 → A5（A1/A2/A6 は依存が強いため連続作業可）

---

### Phase B — Edge API 完成

**目的:** `06` / `10` に記載の MVP エンドポイントをコードと契約で揃える。

| # | タスク | 状態 | ブランチ | 参照 |
|---|---|---|---|---|
| B1 | `POST /api/v1/chat/reclassify` 実装 + router 登録 | 未実装 | `feature/edge-chat-reclassify` | `06`, `10` §3.2, `contracts/api-contract-mvp.md` §4 |
| B2 | 一覧 API を `GET /entities` に統一（種別 GET は MVP 不提供） | **確定** | `docs/api-entities-routing`（本 push に含む） | `contracts/api-contract-mvp.md` §1 |
| B3 | PATCH / GET DTO を UI 必須フィールドまで拡張 | **契約確定** / 実装未 | `feature/edge-entity-dto-expansion` | `contracts/api-contract-mvp.md` §2 |
| B4 | 初回利用時の `encryption_key_id` 発行 | 未実装 | `feature/edge-encryption-key-provisioning` | `09` §5.2 |
| B5 | `client_message_id` 冪等の本番検証 | **契約確定** / 実装未 | `feature/edge-chat-idempotency` | `contracts/api-contract-mvp.md` §5 |
| B6 | Groq 障害時のエラーコード・文言を確定 | 未決 | `feature/edge-groq-error-responses` | 本ファイル §未決 |
| B7 | Groq 日次トークン上限（user 単位、UTC 日次）+ 短時間 req 制限 | 方針確定 | `feature/edge-groq-daily-token-limit` | `05` §利用量制限 |

**完了条件:** `edge/src/tests/integration.test.ts` に reclassify を追加し、本番 Supabase でも同等フローが通る。

**推奨マージ順:** B2（方針確定）→ B3 → B1 → B4 → B5 → B6 → B7

---

### Phase C — iOS ↔ Edge 接続

**目的:** モックデータをやめ、docs 通りのデータフローに切り替える。

| # | タスク | ブランチ | 参照 |
|---|---|---|---|
| C1 | `PlotAPIClient` 新設（Bearer JWT、`request_id` エラー mapping） | `feature/ios-api-client` | `06`, `10` |
| C2 | Edge DTO ↔ 各 Item / ChatMessage mapper | `feature/ios-api-dto-mapping` | `10` §4 |
| C3 | `PlotDataStore.reload()` → `GET /api/v1/entities` | `feature/ios-entities-fetch` | `02` §同期方針 |
| C4 | 編集・削除・完了切替・ピン留め → PATCH / DELETE | `feature/ios-entities-mutation` | `11` §3.4–3.6 |
| C5 | `ChatView` 送信 → `POST /api/v1/chat/messages` + Store 更新 | `feature/ios-chat-edge-send` | `01`, `11` §3.7 |
| C6 | 再分類 → `POST /api/v1/chat/reclassify`（B1 完了後） | `feature/ios-chat-reclassify` | `01`, `11` §3.7 |
| C7 | 送信ごとに `client_message_id`（UUID）を付与 | `feature/ios-chat-client-message-id` | `06` |

**完了条件:** `11` §6 のチェック 5（チャット → 実体作成 → 各一覧反映）が本番 API で一連確認できる。

**推奨マージ順:** C1 → C2 → C3 → C4 → C5 + C7（同一 PR 可）→ C6

---

### Phase D — 認証本番化

**目的:** `04` / `11` §3.1–3.2 の 3 方式を Supabase Auth で通す。

| # | タスク | ブランチ | 参照 |
|---|---|---|---|
| D1 | Google OAuth 成功 → Supabase session → `AccountSession`（samples 廃止） | `feature/supabase-google-session` | `04` |
| D2 | Sign in with Apple | `feature/supabase-apple-sign-in` | `04` |
| D3 | Email をマジックリンク / OTP に変更 | `feature/supabase-email-magic-link` | `04`, `11` §3.1 |
| D4 | 前回ログイン方式の推奨表示 | `feature/auth-last-provider-hint` | `04` §Apple Relay |
| D5 | Apple Relay 時のヘルプ誘導（Login → Help 連携） | `feature/auth-apple-relay-help` | `11` §3.1 |
| D6 | 新規登録時タイムゾーンを端末 → `public.users.timezone` | `feature/signup-timezone-bootstrap` | `11` §3.2 |
| D7 | ログアウト / アカウント削除を Supabase + DB に接続 | `feature/account-logout-delete` | `11` §3.3 |
| D8 | `PlotDebug` デモフラグを本番ビルドから除外 | `feature/debug-flags-release-gating` | — |

**完了条件:** `11` §6 のチェック 2・3 が通る。

**推奨マージ順:** D1 → D2 → D3 → D4 → D5 → D6 → D7 → D8

**メモ:** Phase C と並行可能だが、**C1 以降は有効 JWT が必要**なため D1 は C5 より前に完了させるのが望ましい。

---

### Phase E — 体験仕上げ

**目的:** UI シェルだけでは足りない docs 要件を埋める。

| # | タスク | ブランチ | 参照 |
|---|---|---|---|
| E1 | `ai_persona_config` / `timezone` / `display_name` を `public.users` と双方向同期 | `feature/settings-users-sync` | `09` §3.2, `11` §3.3 |
| E2 | チャット履歴の取得・表示（必要なら Edge に messages GET を追加） | `feature/chat-messages-history` | `11` §3.7 |
| E3 | AI 推論アシスト UI（500ms デバウンス、キー入力ごとの API 呼び出し禁止） | `feature/chat-category-inference-ui` | `01`, `09` §1.2 |
| E4 | 元メッセージ 30 日経過後の再分類不可 | `feature/chat-reclassify-expiry` | `01`, `09` §1.2 |
| E5 | 主要イベント計測 + 失敗時 `request_id` 連携 | `feature/analytics-request-id` | `11` §2.4 |

**完了条件:** `11` §6 のチェック 6 が通る。

**推奨マージ順:** E1 → E2 → E3 → E4 → E5

---

### Phase F — リリース前チェック

`11` §6 を正本として全項目を確認する。チェックで見つかった不足は **内容ごとに** ブランチを切る。

| チェック | 不足時のブランチ例 |
|---|---|
| 1. 法務画面の全導線 | `fix/legal-navigation-paths` |
| 2. 認証 3 方式 | Phase D の各ブランチで対応 |
| 3. Apple Relay 導線 | `feature/auth-apple-relay-help`（D5 と共用可） |
| 4. 共通 UI 状態 | `fix/screen-status-states` |
| 5. チャット → 一覧の一連 | Phase C の各ブランチで対応 |
| 6. 設定反映 | `feature/settings-users-sync`（E1 と共用可） |
| OSS ライセンス本文 | `feature/oss-licenses-content` |

---

### Phase G — モック削除・整理

| 対象 | ブランチ |
|---|---|
| `ChatMockResponder` / `*.sampleData` / `PlottyAccount.samples` | `clean/remove-mock-data-layer` |
| `PlotDebug` デモ用フラグ | `clean/remove-debug-demo-flags` |
| `SupabaseDatabaseService` stub 整理 | `clean/supabase-service-layer` |
| `Plotty/Core/` 重複ファイル | `clean/legacy-core-duplicates` |

---

## 実装順序の理由（要約）

| 順 | Phase | 理由 |
|---|---|---|
| 1 | A | API も iOS も DB がないと何も検証できない |
| 2 | B | iOS 接続前に Edge 契約・reclassify を固める |
| 3 | D（D1 優先） | JWT がないと Edge を呼べない |
| 4 | C | 一覧 CRUD → チャット → 再分類の順がデバッグしやすい |
| 5 | E | 接続後に UX 要件（履歴・推論 UI・設定同期）を仕上げる |
| 6 | F | リリースゲート |
| 7 | G | モック削除は接続完了後でよい |

---

## コードと docs のズレ（docs 準拠で解消する）

| 項目 | docs | 現コード | 解消ブランチ |
|---|---|---|---|
| Email 認証 | マジックリンク / OTP | パスワードフォーム | `feature/supabase-email-magic-link` |
| 種別 GET | `/schedules` 等 | **`GET /entities` のみ**（確定） | 実装: `feature/edge-entity-dto-expansion` |
| PATCH / GET フィールド | UI 必須フィールド | 契約未反映 | `contracts/api-contract-mvp.md` → コード |
| Edge ランタイム | Supabase Edge Functions | `edge/` が Workers 形式 | `feature/supabase-edge-functions-deploy` |
| チャット履歴 | `messages` 表示 | セッション内メモリのみ | `feature/chat-messages-history` |
| AI 推論アシスト | 入力中 UI | 未実装 | `feature/chat-category-inference-ui` |
| OSS ライセンス | 利用ライブラリ一覧 | プレースホルダー | `feature/oss-licenses-content` |

---

## Phase 2 候補（MVP 外）

| 内容 | ブランチ例（着手時） |
|---|---|
| OS 標準カレンダー連携 | `feature/ios-eventkit-calendar-sync` |
| プッシュ通知 | `feature/ios-push-notifications` |
| 別メールアカウントの手動統合 UI | `feature/account-manual-link-ui` |

---

## 追加で詰める項目（未決）

- Groq 障害時の UX（文言、再試行導線）→ `feature/edge-groq-error-responses` / `feature/analytics-request-id`
- Groq 日次トークン上限の実装・初期値チューニング → `feature/edge-groq-daily-token-limit`（方針: `05` §利用量制限）
- RLS SQL の最終形（migration 化）→ `feature/supabase-rls-migrations`
- Supabase Free プロジェクト pause 対策（週次 ping 等）→ A4 デプロイ後に要否判断
- `messages.client_message_id` 列（または idempotency テーブル）の migration → `feature/edge-chat-idempotency`（詳細: `contracts/implementation-notes.md` §3）

---

## 実装メモ（施工待ち・方針変更なし）

設計は確定。コード / migration / mapper で吸収する項目の一覧は **`docs/contracts/implementation-notes.md`** を正本とする。

含む内容:

- ドキュメント正本の整理（`design.md` / `phase-0-api-contract.json` 等）
- API ↔ iOS mapper（priority 1–3、due_date デフォルト、accent 非永続）
- Migration バックログ（`client_message_id`、`user_daily_groq_usage`）
- Phase E 以降に回す項目
- インフラ運用メモ（Supabase pause 等）

---

## 意思決定ログ（追記用）

- 2026/06/03: App Store 配布は Apple Developer 登録済みのためインフラコスト懸念から除外。
- 2026/06/03: Groq は **user 単位・1日・トークン上限** を Edge で enforce する（初期 50,000 tokens / user / day、UTC リセット）。Plotty は大量利用を求めないが、コスト暴走防止の安全弁として設ける。値は env で調整し、Groq ダッシュボードを見ながら後から厳しくしてよい。
- 2026/06/03: Edge ランタイムは **Supabase Edge Functions** に確定（Cloudflare Workers は不採用）。理由: Supabase スタック統一、CPU 2s/req で暗号処理に余裕、日次トークン集計を同一 DB で扱いやすい。トレードオフ: Free プロジェクトの 1 週間 pause、`edge/` の Deno 向け載せ替え（A4）。
- 2026/06/03: **一覧 API** は `GET /entities?type=` のみ（種別 GET は MVP 不提供）。`docs/contracts/api-contract-mvp.md` §1。
- 2026/06/03: **GET/PATCH DTO** を UI 必須フィールドまで確定（schedule: 日時・終日・場所・notes / task: 完了・期限・priority 1–3 / memo: content・pin）。`accent`/`swatch` は iOS のみ。§2。
- 2026/06/03: **`POST /chat/reclassify`** 契約確定（論理削除 + 新規作成、`migrated_entity` + `confirmation_text`）。§4。
- 2026/06/03: **`client_message_id` 冪等** — 同一 user+key の再 POST は **200 + 初回レスポンス**。§5。
- 2026/06/03: §2〜§4 の実装吸収項目・migration バックログ・doc 正本整理を **`docs/contracts/implementation-notes.md`** に集約。方針変更は不要、施工のみ。
- 2026/06/03: **設計レビュー結論** — MVP 設計は実装開始可能（完成度 約 80–85%、実装 約 15–20%）。priority / due_date / doc 正本のズレ・Phase E 後回しは **いずれも実装で吸収可能**（ユーザー確認済み）。docs push 後の次手: Phase A → B。
