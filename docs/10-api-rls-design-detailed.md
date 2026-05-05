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
| Edge | 検証、Groq、暗号化/復号、DB操作 | クライアントへの秘密情報露出 |
| DB | 永続化、RLS、cron | 業務ロジック集中化 |
| Vault | 鍵保管 | アプリから直接参照 |

---

## 3. エンドポイント詳細

基底パスは `/api/v1`（Edge Function 名に合わせ調整可）。

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

### Request

```json
{
  "source": { "type": "task", "id": "uuid" },
  "target_type": "memo",
  "reason_text": "やっぱりメモにしたい"
}
```

### Response（例）

```json
{
  "migrated_entity": { "type": "memo", "id": "uuid-new" }
}
```

## 3.3 `GET /entities`

### Query

- `type`（任意）
- `from`, `to`（任意）
- `limit`, `cursor`

### Response（例）

```json
{
  "items": [
    { "type": "schedule", "id": "uuid", "title": "会議" },
    { "type": "task", "id": "uuid", "title": "資料作成" }
  ],
  "next_cursor": "opaque-cursor"
}
```

## 3.4 更新系

- `PATCH /schedules/{id}`
- `PATCH /tasks/{id}`
- `PATCH /memos/{id}`
- `DELETE /entities/{type}/{id}`（論理削除）

---

## 4. I/O 契約ルール

- DB暗号文カラムはクライアントへ直接返さない
- 返却は表示用DTO（復号済み + 必要最小限）
- `client_message_id` で冪等性を担保
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
2. Edgeでの鍵取得・復号
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

## 10. 次の成果物

1. `docs/11-api-contract-json.md`（項目レベル契約）
2. `docs/12-rls-policies-sql.md`（適用SQL）
3. `docs/13-edge-test-cases.md`（統合テスト仕様）
