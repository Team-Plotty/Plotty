# _shared/plotty-edge

`edge/src` のデプロイ用コピー。Supabase CLI は `supabase/functions/` 外をバンドルしないため配置している。

**`edge/src` を更新したら同期する:**

```bash
cp -R edge/src supabase/functions/_shared/plotty-edge
rm -rf supabase/functions/_shared/plotty-edge/tests
```

正本は **`edge/src`**（Node 向け `npm run typecheck` もこちら）。
