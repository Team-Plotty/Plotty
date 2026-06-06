# API 契約（MVP 確定版）

正本: `10-api-rls-design-detailed.md` の詳細とセットで参照する。  
実装の Zod 正本: `edge/src/contracts/chat-messages.ts`（本書と同期すること）。  
施工メモ（mapper・migration 待ち）: `implementation-notes.md`。

**確定日:** 2026/06/03

---

## 1. 一覧 API（B2 確定）

### 決定

- MVP の一覧取得は **`GET /api/v1/entities` のみ** とする。
- `GET /schedules` / `/tasks` / `/memos` は **MVP では提供しない**（将来 alias として追加可）。

### Query（MVP）

| パラメータ | 型 | 必須 | 説明 |
|---|---|---|---|
| `type` | `schedule` \| `task` \| `memo` | 任意 | 種別フィルタ。省略時は 3 種をまとめて返す |
| `limit` | integer | 任意 | 1–200、既定 50 |

**MVP から除外（Phase 2）:** `cursor`, `from`, `to` — 低利用のため全件近傍を `limit` で足りる想定。`next_cursor` は常に `null`。

---

## 2. エンティティ DTO（GET / PATCH）

`items[]` と PATCH レスポンスの `entity` は **種別ごとにフィールドが異なる**。共通フィールドは `type`, `id`, `title`。

### 2.1 `schedule`

| フィールド | GET | PATCH | 型 | 備考 |
|---|---|---|---|---|
| `type` | ✓ | — | `"schedule"` | |
| `id` | ✓ | — | uuid | |
| `title` | ✓ | ✓ | string 1–100 | 復号済み |
| `start_at` | ✓ | ✓ | ISO8601 | |
| `end_at` | ✓ | ✓ | ISO8601 | nullable |
| `is_all_day` | ✓ | ✓ | boolean | |
| `location` | ✓ | ✓ | string | DB 平文 |
| `notes` | ✓ | ✓ | string | `origin_text_encrypted` の復号値。UI の「メモ」欄 |
| `updated_at` | ✓ | — | ISO8601 | ソート用 |

**MVP 非対象:** `swatch` / `accent`（iOS UI のみ。API では持たない。再 fetch 後はデフォルト色 — `implementation-notes.md` §2.1）

### 2.2 `task`

| フィールド | GET | PATCH | 型 | 備考 |
|---|---|---|---|---|
| `type` | ✓ | — | `"task"` | |
| `id` | ✓ | — | uuid | |
| `title` | ✓ | ✓ | string 1–100 | |
| `is_completed` | ✓ | ✓ | boolean | 一覧の完了切替 |
| `due_date` | ✓ | ✓ | ISO8601 | |
| `priority` | ✓ | ✓ | integer 1–3 | 1=低, 2=中, 3=高（DB と一致） |
| `created_at` | ✓ | — | ISO8601 | ソート用 |
| `updated_at` | ✓ | — | ISO8601 | |

iOS の `Priority` raw 0–2 は mapper で 1–3 に変換する（詳細: `implementation-notes.md` §2.1）。

**task `due_date`:** DB は NOT NULL。UI で期限なしの場合、Edge は `public.users.timezone` 基準 **当日 23:59:59** を設定（`12` §2.2）。

### 2.3 `memo`

| フィールド | GET | PATCH | 型 | 備考 |
|---|---|---|---|---|
| `type` | ✓ | — | `"memo"` | |
| `id` | ✓ | — | uuid | |
| `title` | ✓ | ✓ | string 1–100 | |
| `content` | ✓ | ✓ | string 1–4000 | 復号済み本文 |
| `is_pinned` | ✓ | ✓ | boolean | |
| `updated_at` | ✓ | — | ISO8601 | ソート・表示用 |

---

## 3. `POST /api/v1/chat/messages`

### Request

```json
{
  "text": "明日10時に会議",
  "forced_category": null,
  "client_message_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

| フィールド | 型 | 備考 |
|---|---|---|
| `text` | string 1–4000 | |
| `forced_category` | `schedule` \| `task` \| `memo` \| null | null で AI 推論 |
| `client_message_id` | string 1–128 | **冪等キー**（§5） |

### Response

```json
{
  "message_id": "uuid",
  "confirmation_text": "カレンダーに登録したよ！",
  "created_entities": [
    {
      "type": "schedule",
      "id": "uuid",
      "title": "会議",
      "start_at": "2026-05-06T01:00:00Z",
      "end_at": "2026-05-06T02:00:00Z",
      "is_all_day": false,
      "location": "",
      "notes": "明日10時に会議"
    }
  ]
}
```

`created_entities[]` は §2 の GET フィールドの **作成直後に必要な subset** を含む。

---

## 4. `POST /api/v1/chat/reclassify`

### Request

```json
{
  "source": { "type": "task", "id": "uuid" },
  "target_type": "memo",
  "reason_text": "やっぱりメモにしたい"
}
```

| フィールド | 型 | 必須 | 備考 |
|---|---|---|---|
| `source.type` | enum | ✓ | 現在の種別 |
| `source.id` | uuid | ✓ | 現在の実体 ID |
| `target_type` | enum | ✓ | 移行先（`source.type` と異なること） |
| `reason_text` | string 0–500 | 任意 | 監査・将来の LLM 用。MVP では保存のみ可 |

### Processing

1. 元実体を **論理削除**
2. 同内容で **新種別の実体を新規作成**（新 UUID）
3. 元 `messages.related_entities` が残っていれば新 ID に差し替え（メッセージ削除後も再分類自体は可。`origin_text_encrypted` を参照）

### Response

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

`migrated_entity` は §2 の GET DTO と同型。

### Errors

| code | 条件 |
|---|---|
| `NOT_FOUND` | 元実体なし / 既に削除 |
| `VALIDATION_ERROR` | `source.type === target_type` |
| `FORBIDDEN` | 他人の実体 |

---

## 5. `client_message_id` 冪等（確定）

| 項目 | 方針 |
|---|---|
| スコープ | `(user_id, client_message_id)` で一意 |
| 保存 | `messages` に `client_message_id` 列を追加するか、専用 idempotency テーブル（実装時に migration） |
| **重複 POST** | 同一キーで **処理済み** なら **`200 OK` + 初回と同一 Response body** を返す（再送・タイムアウト再試行向け） |
| 処理中の競合 | **`409 CONFLICT`**（稀。MVP では簡易実装可） |
| Groq 失敗後の再送 | **同一 `client_message_id` を再利用** してよい（成功まで idempotent） |

---

## 6. `DELETE /api/v1/entities/{type}/{id}`

Response（変更なし）:

```json
{
  "deleted": true,
  "type": "task",
  "id": "uuid"
}
```

---

## 7. 共通エラー

`error.code` は `edge/src/contracts/errors.ts` に準拠。`request_id` を含める。
