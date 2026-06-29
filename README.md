# Plotty
日常の管理を、1つの会話で。

iOS アプリの Xcode プロジェクトは **`Plotty/Plotty.xcodeproj`** を開いてください（`Plottyy/` は未使用のため削除済み）。




## ブランチルール

- ブランチ名は英数字小文字と `-` を使用する
- 命名形式は `feature/<category>-<topic>` を基本とする
- 1機能実装 1ブランチを徹底する
- 作業前に `main` を最新化してから、対象ブランチへ切り替える
  - 新しく作る場合: `git switch main && git pull && git switch -c <branch-name>`
  - 既存ブランチに切り替える場合: `git switch <branch-name>`

## プルリクエストルール

- PRタイトルはそのブランチでの最初のコミットメッセージを使用


##  commitメッセージ規則

- feat：新機能追加
- fix：バグ修正
- hotfix：クリティカルなバグ修正
- add：新規（ファイル）機能追加
- update：機能修正（バグではない）
- change：仕様変更
- clean：整理（リファクタリング等）
- disable：無効化（コメントアウト等）
- remove：削除（ファイル）
- upgrade：バージョンアップ
- revert：変更取り消し
- docs：ドキュメント修正（README、コメント等）
- tyle：コードフォーマット修正（インデント、スペース等）
- perf：パフォーマンス改善
- test：テストコード追加・修正
- ci：CI/CD 設定変更（GitHub Actions 等）
- build：ビルド関連変更（依存関係、ビルドツール設定等）
- chore：雑務的変更（ユーザーに直接影響なし）
