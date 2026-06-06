# 10. API/RLS 設計（詳細版）

実装・レビュー・テストで使える詳細度に整理した、API/RLS 設計の詳細版（正本）。

---

## 1. 設計原則

- クライアントは JWT を持つが、復号権限は持たない
- 平文の業務データ返却は Edge API 経由のみ
- DB直アクセスは RLS と暗号文で防御
- `service_role` は限定用途のみ

---

## 2. API境界と責務

| 層 | 役割 | 禁止事項 |
|---|---|---|
| iOS | 入力、描画、ローカル状態更新 | 直接復号、鍵保持 |
| Edge（Supabase Edge Functions） | 検証、Groq、暗号化/復号、DB操作 | クライアントへの秘密情報露出 |
| DB | 永続化、RLS、cron | 業務ロジック集中化 |
| Vault | 鍵保管 | アプリから直接参照 |

---

## 3. エンドポイント詳細

### URL 構成

- **ホスト:** Supabase Edge Functions（関数名 `plotty-api`）
- **公開 URL 例:** `https://<project-ref>.supabase.co/functions/v1/plotty-api/api/v1/chat/messages`
- **アプリ内パス:** `/api/v1/...`（下表のパスはこの suffix）

iOS の Base URL は `https://<project-ref>.supabase.co/functions/v1/plotty-api` とし、各 API は `/api/v1/...` を連結する。

## 3.1 `POST /chat/messages`

### Request

```json
{
  "text": "明日10時に会議",
  "forced_category": null,
  "client_message_id": "uuid-or-ulid"
}
```

### Processing

1. JWTから `user_id` を確定
2. `public.users.ai_persona_config` を取得
3. Groqで抽出
4. `messages` 保存（`related_entities` / `analysis_results_encrypted` 含む）
5. 実体テーブル保存
6. DTO整形して返却

### Response（例）

```json
{
  "message_id": "uuid",
  "confirmation_text": "明日10:00に会議を登録しました",
  "created_entities": [
    {
      "type": "schedule",
      "id": "uuid",
      "title": "会議",
      "start_at": "2026-05-06T01:00:00Z"
    }
  ]
}
```

## 3.2 `POST /chat/reclassify`

契約の正本: `docs/contracts/api-contract-mvp.md` §4。

### Request

```json
{
  "source": { "type": "task", "id": "uuid" },
  "target_type": "memo",
  "reason_text": "やっぱりメモにしたい"
}
```

| フィールド | 必須 | 備考 |
|---|---|---|
| `source.type` / `source.id` | ✓ | 変更元実体 |
| `target_type` | ✓ | `source.type` と異なること |
| `reason_text` | 任意 | 0–500 文字 |

### Processing

1. 元実体を論理削除
2. 新種別で新 UUID の実体を作成（内容は `origin_text_encrypted` 等から引き継ぎ）
3. 元メッセージが残っていれば `related_entities` を新 ID に更新

### Response（例）

```json
{
  "confirmation_text": "メモに変更したよ！",
  "migrated_entity": {
    "type": "memo",
    "id": "uuid-new",
    "title": "資料の提出",
    "content": "明日までに資料を提出する",
    "is_pinned": false,
    "updated_at": "2026-05-06T12:00:00Z"
  }
}
```

## 3.3 `GET /entities`

契約の正本: `docs/contracts/api-contract-mvp.md` §1–§2。

### Query（MVP）

| パラメータ | 説明 |
|---|---|
| `type` | 任意。`schedule` / `task` / `memo` |
| `limit` | 任意。1–200、既定 50 |

**MVP 除外:** `cursor`, `from`, `to`（`next_cursor` は常に `null`）

### Response（例）

```json
{
  "items": [
    {
      "type": "schedule",
      "id": "uuid",
      "title": "会議",
      "start_at": "2026-05-06T01:00:00Z",
      "end_at": "2026-05-06T02:00:00Z",
      "is_all_day": false,
      "location": "会議室A",
      "notes": "",
      "updated_at": "2026-05-06T00:00:00Z"
    },
    {
      "type": "task",
      "id": "uuid",
      "title": "資料作成",
      "is_completed": false,
      "due_date": "2026-05-07T14:59:59Z",
      "priority": 2,
      "created_at": "2026-05-05T00:00:00Z",
      "updated_at": "2026-05-05T00:00:00Z"
    },
    {
      "type": "memo",
      "id": "uuid",
      "title": "買い物リスト",
      "content": "牛乳、卵",
      "is_pinned": true,
      "updated_at": "2026-05-06T10:00:00Z"
    }
  ],
  "next_cursor": null
}
```

## 3.4 更新系

契約の正本: `docs/contracts/api-contract-mvp.md` §2。

| パス | PATCH で更新可能な主フィールド |
|---|---|
| `/schedules/{id}` | `title`, `start_at`, `end_at`, `is_all_day`, `location`, `notes` |
| `/tasks/{id}` | `title`, `is_completed`, `due_date`, `priority` |
| `/memos/{id}` | `title`, `content`, `is_pinned` |

- `DELETE /entities/{type}/{id}` — 論理削除（レスポンスは §6）

---

## 4. I/O 契約ルール

- DB暗号文カラムはクライアントへ直接返さない
- 返却は表示用DTO（復号済み + 必要最小限）。種別ごとのフィールドは `docs/contracts/api-contract-mvp.md` §2
- `client_message_id` で冪等性を担保（**同一 user + 同一 key の再 POST は 200 + 初回 body**。§5）
- エラー構造は共通化する

共通エラー例:

```json
{
  "error": {
    "code": "GROQ_TIMEOUT",
    "message": "通信状況を確認して再度お試しください"
  }
}
```

---

## 5. RLS マトリクス（MVP）

前提: `user_id = auth.uid()` の本人行のみ許可。

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `public.users` | `id = auth.uid()` | 不可（トリガー） | 本人のみ（許可カラム制限） | 不可 |
| `messages` | 本人のみ | 本人のみ | 原則不可（Edge管理） | 原則不可（cron管理） |
| `schedules` | 本人のみ | 本人のみ | 本人のみ | 論理削除運用 |
| `tasks` | 本人のみ | 本人のみ | 本人のみ | 論理削除運用 |
| `memos` | 本人のみ | 本人のみ | 本人のみ | 論理削除運用 |

---

## 6. `service_role` 運用

## 6.1 許可用途

1. `pg_cron` 30日削除
2. Edge（Supabase Edge Functions）での鍵取得・復号
3. 明示的な管理ジョブ

## 6.2 禁止用途

- クライアント到達可能エンドポイントでの利用
- 通常ユーザー操作の恒常的バイパス

---

## 7. cron / 削除ジョブ

- 対象: `messages`
- 条件: `created_at < now() - interval '720 hours'`
- 基準: UTC
- 実行: 毎日（時間帯は運用側で固定）
- 監視: `cron.job_run_details` + Edgeログ

---

## 8. 非機能・運用設計

- ログ項目: `request_id`, `user_id`, `function_name`, `latency_ms`, `error_code`
- Groq:
  - timeout 10秒
  - retry 最大1回
- レート制限: user単位（閾値は運用で調整）

---

## 9. テスト観点

## 9.1 API

- 正常: 各 endpoint の作成/更新/取得/削除
- 異常: JWT不正、対象なし、権限不足、Groq timeout
- 冪等: `client_message_id` 重複送信

## 9.2 RLS

- 他ユーザー行の参照/更新拒否
- `service_role` なしで管理処理不可
- Edge経由でのみ復号結果取得可

---

## 10. 関連ドキュメント

| ファイル | 内容 |
|---|---|
| `docs/contracts/api-contract-mvp.md` | **MVP API 契約（確定）** — DTO・reclassify・冪等 |
| `docs/contracts/implementation-notes.md` | **実装施工メモ** — mapper・migration 待ち・doc 正本 |
| `docs/contracts/phase-0-api-contract.json` | chat/messages の部分 JSON Schema（§3.1 と整合） |
| `edge/sql/plotty_schema.sql` | RLS 含む DDL 正本 |
| `edge/src/contracts/chat-messages.ts` | 実装側 Zod 正本（本契約と同期） |

**将来:** Edge 統合テスト仕様書、RLS migration 手順書（番号は `docs/contracts/` 配下で追加）
