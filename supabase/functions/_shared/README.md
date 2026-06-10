# _shared/plotty-edge

`edge/src` のデプロイ用コピー。Supabase CLI は `supabase/functions/` 外をバンドルしないため配置している。

**`edge/src` を更新したら同期する:**

```bash
rsync -a --delete edge/src/ supabase/functions/_shared/plotty-edge/
find supabase/functions/_shared/plotty-edge -name '*.ts' -exec sed -i '' 's/\.js"/\.ts"/g' {} +
```

または `cd edge && npm run sync:supabase-shared`

Deno バンドル用に import 拡張子を `.js` → `.ts` に変換している（`edge/src` 正本は Node 向け `.js` のまま）。
