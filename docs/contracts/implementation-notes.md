# 実装メモ（設計確定・施工待ち）

MVP 設計は確定済み。**方針変更は不要**だが、実装・migration・mapper で吸収する項目をここに集約する。  
正本の API 契約: `api-contract-mvp.md`。ロードマップ: `08-roadmap-and-open-items.md`。

**最終更新:** 2026/06/03

### 設計完成度（参照・2026/06/03 時点）

| 観点 | 評価 |
|---|---|
| MVP 設計（何を作るか・API・順序） | **約 80–85%** — 実装開始に足る |
| 実装・DDL が契約どおり | **約 15–20%** — Phase A/B の施工待ち |
| docs push | **問題ない成熟度**（方針確定後はコード/DDL 反映が次） |

**ユーザー確認（2026/06/03）:** §2・§4 に挙げるズレ・後回し項目は **いずれも実装で吸収可能**。**方針を変える必要はない**。

---

## 1. ドキュメント正本の整理

| 用途 | 正本 | 備考 |
|---|---|---|
| 番号付き要件 | `docs/01`〜`13` | `09` / `10` が詳細正本 |
| MVP API 契約 | `docs/contracts/api-contract-mvp.md` | DTO・reclassify・冪等 |
| chat/messages JSON Schema | `docs/contracts/phase-0-api-contract.json` | **§3.1 の部分スキーマ**。拡張は `api-contract-mvp.md` を正とする |
| DDL | `edge/sql/plotty_schema.sql` | 説明は `13-database-ddl.md` |
| 実装 Zod | `edge/src/contracts/chat-messages.ts` | **施工後**は `api-contract-mvp.md` と同期必須 |
| デザインシステム詳細 | `docs/design.md` | **参考用・レガシー**（旧 ScheduleAI 表記あり）。UI 要件は `11` を正とする |
| 意思決定・ペース | `docs/08-roadmap-and-open-items.md` | 意思決定ログを追記 |

---

## 2. 実装で吸収する項目（方針変更なし）

設計上は解決済み。Phase A/B/C のコード・migration で反映する。

### 2.1 API ↔ iOS mapper

| 項目 | 設計 | 実装時の扱い |
|---|---|---|
| **task `priority`** | API/DB: **1–3**（1=低, 2=中, 3=高） | iOS `TodoItem.Priority` raw 0–2 ↔ API は **単一 mapper**（`PlotAPIClient` または DTO 層）で変換 |
| **task `due_date`** | DB: `NOT NULL` | UI は期限なし可 → Edge 作成/更新時に **`public.users.timezone` 基準で当日 23:59:59** をデフォルト（`12` §2.2 と整合） |
| **`accent` / `swatch`** | API・DB に **載せない**（確定） | iOS のみ。再 fetch 後は **デフォルト色**（例: graphite / sky）に戻る。将来永続化するなら Phase 2 で列追加を検討 |
| **schedule `notes`** | API フィールド名 | DB の `origin_text_encrypted` 復号値。手入力編集も同列に暗号化保存 |

### 2.2 Edge / DB 施工

| 項目 | 設計 | 実装タスク |
|---|---|---|
| **`client_message_id` 冪等** | 200 + 初回 body（`api-contract-mvp.md` §5） | `messages.client_message_id` 列 + UNIQUE `(user_id, client_message_id)`、または idempotency テーブル |
| **Groq 日次トークン上限** | 50k tokens / user / day（`05` §利用量制限） | `user_daily_groq_usage` テーブル（下記 §3）+ Edge 加算ロジック |
| **reclassify** | 契約確定（§4） | handler 未実装 → `feature/edge-chat-reclassify` |
| **GET/PATCH DTO 拡張** | 契約確定（§2） | Zod + persistence + handler → `feature/edge-entity-dto-expansion` |
| **Edge ランタイム** | Supabase Edge Functions | `edge/` を Deno 入口に移植 → `feature/supabase-edge-functions-deploy` |
| **`auth.users` → `public.users`** | `04` / `09` | `plotty_schema.sql` 外の Supabase 標準トリガー。`13` 適用順 §2 |

### 2.3 コードと docs の現状差（施工で解消）

| 項目 | docs | 現コード |
|---|---|---|
| Email 認証 | マジックリンク / OTP | パスワード UI（モック） |
| 一覧 API | `GET /entities` のみ | router 一致。DTO は狭い |
| チャット AI | Edge + Groq | `ChatMockResponder` |
| iOS データ | Edge 経由 | `PlotDataStore` インメモリ + sample |
| `design.md` | 番号付き docs + `11` が UI 正本 | 参考資料（先頭に位置づけ注記。ScheduleAI 表記はレガシー） |
| `phase-0-api-contract.json` | `api-contract-mvp.md` が MVP 正本 | chat/messages 部分スキーマのみ（`x-plotty-doc-hierarchy` 参照） |

---

## 3. Migration バックログ（DDL 未反映）

`plotty_schema.sql` **次回 migration** で追加予定。詳細カラムは実装 PR で確定してよい。

| 対象 | 目的 | 想定 Phase / ブランチ |
|---|---|---|
| `messages.client_message_id` | 冪等キー | B5 / `feature/edge-chat-idempotency` |
| `user_daily_groq_usage` | Groq 日次トークン集計（`user_id`, `usage_date` UTC date, `tokens_used`） | B7 / `feature/edge-groq-daily-token-limit` |
| （任意）`messages` UNIQUE | `(user_id, client_message_id)` | 上記と同 PR |

**`user_daily_groq_usage` 最小案:**

```sql
-- 実装時に migration 化すること（ここは設計メモ）
create table public.user_daily_groq_usage (
  user_id uuid not null references public.users (id) on delete cascade,
  usage_date date not null,  -- UTC 日付
  tokens_used bigint not null default 0,
  primary key (user_id, usage_date)
);
```

RLS: 本人 SELECT のみ。INSERT/UPDATE は Edge `service_role` のみ。

---

## 4. Phase E 以降に回す設計（MVP 開始のブロッカーではない）

| 項目 | docs 参照 | メモ |
|---|---|---|
| チャット履歴 GET | `11` §3.7, Phase E2 | MVP 初版はセッション内 `messages` のみ可。必要なら `GET /messages` を Edge に追加 |
| 設定 API（`public.users`） | `11` §3.3, Phase E1 | RLS 下の Supabase 直 PATCH か Edge 経由かは E1 で決定。プロフィール・timezone・`ai_persona_config` |
| AI 推論アシスト UI | `01`, `09` §1.2, Phase E3 | 500ms デバウンス・**API 呼び出しなし**のローカル/heuristic |
| 再分類の 30 日制限 | `01`, Phase E4 | 元メッセージ削除後は UI で再分類不可 |
| Groq 障害 UX 文言 | B6 | エラーコードは `errors.ts` 済み。ユーザー向け文言・再試行は E5/B6 |
| OSS ライセンス本文 | Phase F | プレースホルダーから実ライブラリ一覧へ |
| ページネーション | `api-contract-mvp.md` §1 | `cursor`, `from`, `to` は Phase 2 |

---

## 5. インフラ・運用メモ

| 項目 | 内容 |
|---|---|
| **Supabase Free pause** | 1 週間無操作でプロジェクト pause。対策: 手動 resume / 週次 ping / Pro 移行（A4 後に要否判断） |
| **Groq コスト** | アカウント全体 + user 日次上限の二重の安全弁。ダッシュボード週次確認 |
| **Edge CPU** | Supabase Edge Functions: CPU 2s/req（I/O 除く）。暗号 + JSON は問題になりにくい想定 |
| **in-memory レート制限** | 本番不可。日次トークンは Postgres、短時間 req 制限も DB または共有ストアへ（B7） |
| **encryption_key_id** | 初回 Edge 利用時に発行（`09` §5.2）。Vault 完全版は Phase 2。MVP は Secrets + env |

---

## 6. 実装者チェックリスト（Phase 着手前）

- [ ] `api-contract-mvp.md` を読んだ
- [ ] mapper（priority, due_date デフォルト）の置き場所を決めた（iOS DTO 層）
- [ ] migration バックログ（§3）をどの PR に含めるか決めた
- [ ] Edge Base URL を iOS plist に設定する PR を A4/A5 で用意
- [ ] `edge/src/contracts/chat-messages.ts` 更新を B3/B5/B1 と同時または直後に行う

---

## 7. 意思決定（実装吸収の明示）

- 2026/06/03: 上記 §2 のズレは **設計変更ではなく実装タスク** として扱う。MVP スコープ・API 契約は変更しない。
- 2026/06/03: **ユーザー確認** — priority mapper、`due_date` デフォルト、`design.md` / `phase-0-api-contract.json` の位置づけ、Phase E 後回し項目など **いずれも実装で吸収可能。方針変更は不要**。
- 2026/06/03: MVP 設計は実装着手可能な成熟度（約 80–85%）。残りは Phase A/B の施工と Phase E の任意機能。
- 2026/06/03: `accent`/`swatch` は MVP で API に載せない。色の永続化が必要になった時点で Phase 2 検討。
- 2026/06/03: `phase-0-api-contract.json` は chat/messages 部分スキーマとして残し、拡張正本は `api-contract-mvp.md`。
