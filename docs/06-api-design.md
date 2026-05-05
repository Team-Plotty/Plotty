# 06. API設計書

## API責務

- クライアント: 入出力と表示
- Edge: 検証、暗号化/復号、Groq呼び出し、DB操作
- DB: 永続化とRLS

## 主要エンドポイント（MVP）

- `POST /chat/messages`
  - 入力文を解析し、`messages` と実体データを作成
- `POST /chat/reclassify`
  - 実体カテゴリの再分類
- `GET /entities`
  - 統合一覧取得
- `GET /schedules`, `GET /tasks`, `GET /memos`
  - 種別ごとの一覧取得
- `PATCH /schedules/{id}`, `PATCH /tasks/{id}`, `PATCH /memos/{id}`
  - 種別ごとの更新
- `DELETE /entities/{type}/{id}`
  - 論理削除

## I/O方針

- DBの暗号文をそのままUIへ返さない
- Edgeで復号後、表示用DTOとして返却
- `client_message_id` を使った冪等制御を推奨
