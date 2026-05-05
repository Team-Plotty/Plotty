# 04. 認証とアカウント設計

## 認証プロバイダ（MVP）

- Google OAuth
- Email（マジックリンク/OTP）
- Sign in with Apple

## ユーザー作成

- `auth.users` 作成時にDBトリガーで `public.users` を自動作成
- 各プロバイダで同じ作成フローを使う

## アカウントリンク方針

- 同一メールアドレスはSupabaseのメールリンク機能で自動統合
- メールが異なる場合はMVPでは別アカウントとして扱う
- 手動統合UI/処理はPhase2以降

## Apple Relay対策

- `@privaterelay.appleid.com` により別アカウント化し得る
- 初回ログイン方式を保存し、次回も同方式を推奨するUIを採用
