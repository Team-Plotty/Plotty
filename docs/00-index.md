# 00. 全体インデックス

このディレクトリは、要件を要点ごとに分解して管理するための構成です。

## 読み順（推奨）

1. `01-product-concept-ux.md`
2. `02-mvp-scope-and-ops.md`
3. `03-data-model-and-encryption.md`
4. `04-auth-and-account-linking.md`
5. `05-ai-groq-and-prompt-policy.md`
6. `06-api-design.md`
7. `07-rls-and-security-ops.md`
8. `08-roadmap-and-open-items.md`
9. `09-implementation-spec-detailed.md`
10. `10-api-rls-design-detailed.md`
11. `11-screen-ui-requirements.md`
12. `12-ai-persona-and-extraction-spec.md`
13. `13-database-ddl.md`

## ドキュメント運用ルール

- 新しい意思決定は、まず該当番号ファイルに追記する。
- 複数ファイルに跨る変更は、最後に `08-roadmap-and-open-items.md` へメモを残す。
- 詳細仕様を修正する場合は、`09` と `10` を正本として扱う。
- スキーマの正本 SQL は **`edge/sql/plotty_schema.sql`**。説明は `13-database-ddl.md`。
- **Edge API ランタイム** は **Supabase Edge Functions**（`plotty-api`）。概要は `06` §Edge ランタイム、`09` §10、決定ログは `08`。
- **MVP API 契約（DTO・冪等・reclassify）** は **`docs/contracts/api-contract-mvp.md`**。
- **実装施工メモ（mapper・migration 待ち・doc 正本・設計完成度）** は **`docs/contracts/implementation-notes.md`**。
- **`docs/design.md`** は UI デザイン参考（レガシー表記あり）。画面要件の正本は `11`。
