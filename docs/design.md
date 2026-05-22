# DESIGN_SYSTEM.md
# ScheduleAI — 完全デザインシステム

> **原則**
> 1. Apple Human Interface Guidelines (HIG) 完全準拠
> 2. Glassmorphism（ガラス素材）ベース
> 3. カラーを使わない — 白・黒・透明度のみ
> 4. ダークモードをデフォルトとし、ライトモードも完全対応

---

## 目次

1. [カラーパレット](#1-カラーパレット)
2. [タイポグラフィ](#2-タイポグラフィ)
3. [スペーシング](#3-スペーシング)
4. [コーナーラジウス](#4-コーナーラジウス)
5. [ガラスマテリアル](#5-ガラスマテリアル)
6. [アニメーション](#6-アニメーション)
7. [ボタン規格](#7-ボタン規格)
8. [チャットUI](#8-チャットui)
9. [送信ボタン States](#9-送信ボタン-states)
10. [タブバー](#10-タブバー)
11. [背景エフェクト](#11-背景エフェクト)
12. [アクセシビリティ](#12-アクセシビリティ)
13. [未実装・TODO](#13-未実装todo)
14. [AIへの指示プロンプト](#14-aiへの指示プロンプト)
15. [ファイル配置](#15-ファイル配置)

---

## 1. カラーパレット

### 基本ルール
- アクセントカラー（青・赤・緑・黄など）は**一切使用しない**
- 白・黒・グレー・透明度のみで表現する
- Semantic（成功・エラー等）も輝度差のみで表現する

### Dark Mode — Warm Charcoal

```swift
// Dark/ColorTheme.swift
extension Color {
    // Base
    static let darkBase          = Color(hex: "#0F0E0D")
    static let darkSurface       = Color(hex: "#141210")

    // Glass layers
    static let darkGlassHeavy    = Color.white.opacity(0.14)  // ユーザーバブル
    static let darkGlassMid      = Color.white.opacity(0.07)  // AIバブル・カード
    static let darkGlassLight    = Color.white.opacity(0.04)  // 入れ子要素

    // Border
    static let darkBorderStrong  = Color(hex: "#FFFCF8").opacity(0.22)
    static let darkBorderDefault = Color(hex: "#FFFCF8").opacity(0.11)
    static let darkBorderSubtle  = Color(hex: "#FFFCF8").opacity(0.07)

    // Text
    static let darkTextPrimary   = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextSecondary = Color(hex: "#FFFCF8").opacity(0.55)
    static let darkTextTertiary  = Color(hex: "#FFFCF8").opacity(0.33)
    static let darkTextDisabled  = Color(hex: "#FFFCF8").opacity(0.20)

    // Chat specific
    static let darkTextUser      = Color(hex: "#FFFCF8").opacity(0.92)
    static let darkTextAI        = Color(hex: "#FFFCF8").opacity(0.52)  // 薄い
    static let darkAILine        = Color(hex: "#FFFCF8").opacity(0.20)  // 左ライン

    // Input bar
    static let darkInputBG       = Color(hex: "#191613").opacity(0.80)
}
```

### Light Mode — Warm Paper

```swift
// Light/ColorTheme.swift
extension Color {
    // Base
    static let lightBase          = Color(hex: "#F8F6F2")
    static let lightSurface       = Color(hex: "#F3F1EC")

    // Glass layers
    static let lightGlassHeavy    = Color.black.opacity(0.09)
    static let lightGlassMid      = Color.black.opacity(0.045)
    static let lightGlassLight    = Color.black.opacity(0.025)

    // Border
    static let lightBorderStrong  = Color.black.opacity(0.13)
    static let lightBorderDefault = Color.black.opacity(0.08)
    static let lightBorderSubtle  = Color.black.opacity(0.05)

    // Text
    static let lightTextPrimary   = Color.black.opacity(0.85)
    static let lightTextSecondary = Color.black.opacity(0.50)
    static let lightTextTertiary  = Color.black.opacity(0.33)
    static let lightTextDisabled  = Color.black.opacity(0.18)

    // Chat specific
    static let lightTextUser      = Color.black.opacity(0.85)
    static let lightTextAI        = Color.black.opacity(0.48)  // 薄い
    static let lightAILine        = Color.black.opacity(0.16)  // 左ライン

    // Input bar
    static let lightInputBG       = Color(hex: "#F8F5F0").opacity(0.88)
}
```

---

## 2. タイポグラフィ

Apple HIG 準拠。SF Pro（system font）のみ使用。

```swift
// Typography.swift
extension Font {
    static let displayLarge  = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let titleLarge    = Font.system(size: 22, weight: .semibold)
    static let titleMedium   = Font.system(size: 18, weight: .semibold)
    static let titleSmall    = Font.system(size: 16, weight: .medium)
    static let bodyLarge     = Font.system(size: 17, weight: .regular)
    static let bodyMedium    = Font.system(size: 15, weight: .regular)
    static let bodySmall     = Font.system(size: 13, weight: .regular)
    static let labelMedium   = Font.system(size: 13, weight: .medium)
    static let caption       = Font.system(size: 11, weight: .semibold)
    static let micro         = Font.system(size: 10, weight: .semibold)
}
```

### ルール
- タイトル系は `.tracking(-0.3)` で引き締める
- 本文の行間は最低 `lineSpacing(4)`（約1.5）
- Dynamic Type 対応 — すべて `scaledFont` を使用

---

## 3. スペーシング

8pt グリッドシステム（Apple HIG 準拠）。

```swift
// Spacing.swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs:  CGFloat = 8
    static let sm:  CGFloat = 12
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}
```

---

## 4. コーナーラジウス

必ず `style: .continuous`（squircle）を指定する。

```swift
// CornerRadius.swift
enum Radius {
    static let xs:   CGFloat = 8
    static let sm:   CGFloat = 12
    static let md:   CGFloat = 16
    static let lg:   CGFloat = 20
    static let xl:   CGFloat = 28
    static let xxl:  CGFloat = 36
    static let pill: CGFloat = 999
}

// 使い方（必ず style: .continuous）
RoundedRectangle(cornerRadius: Radius.lg, style: .continuous)
```

---

## 5. ガラスマテリアル

`.ultraThinMaterial` + `Color.white.opacity()` の重ね合わせ。

```swift
// GlassMaterial.swift
struct GlassCard: ViewModifier {
    var opacity: Double = 0.07
    var borderOpacity: Double = 0.11
    var radius: CGFloat = Radius.lg

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .fill(Color.white.opacity(opacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(Color.white.opacity(borderOpacity), lineWidth: 0.5)
                    )
            )
    }
}

extension View {
    func glassCard(opacity: Double = 0.07, radius: CGFloat = Radius.lg) -> some View {
        modifier(GlassCard(opacity: opacity, radius: radius))
    }
}
```

### ガラスの種類

| 種類    | opacity | border | 用途                        |
|---------|---------|--------|-----------------------------|
| Heavy   | 0.14    | 22%    | ユーザーメッセージバブル    |
| Medium  | 0.07    | 11%    | AIバブル・通常カード        |
| Light   | 0.04    | 07%    | 入れ子・背景要素            |
| Input   | —       | 14%    | 入力バー（ultraThinMaterial）|

---

## 6. アニメーション

```swift
// Animations.swift
extension Animation {
    static let standard = Animation.spring(response: 0.4,  dampingFraction: 0.75)
    static let quick    = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let smooth   = Animation.interactiveSpring(response: 0.35, dampingFraction: 0.7)
    static let page     = Animation.easeInOut(duration: 0.3)
}
```

### ルール
- `withAnimation(.standard)` を必ず使う
- ボタンタップ時: `scaleEffect(0.96)` + `opacity(0.6)`
- 要素出現: `opacity + offset` の組み合わせ
- `@Environment(\.accessibilityReduceMotion)` を確認して代替アニメーション

---

## 7. ボタン規格

### サイズスケール（HIG 準拠）

| Size  | Height  | Padding H | Font            | 用途                          |
|-------|---------|-----------|-----------------|-------------------------------|
| XL    | 56pt    | 28pt      | 17 Semibold     | メインCTA・フルwidth           |
| LG    | 50pt    | 24pt      | 17 Semibold     | セクション内メインアクション   |
| **MD**| **44pt**| **20pt**  | **15 Semibold** | ⚠️ HIG最小タップ目標 — 標準   |
| SM    | 36pt    | 16pt      | 13 Medium       | 補助アクション・カード内       |
| XS    | 28pt    | 12pt      | 12 Medium       | チップ・タグ・インライン限定   |

> ⚠️ **HIG必須**: 最小タップ目標は 44 × 44pt

### スタイル一覧

| スタイル    | background       | border   | text     | 用途               |
|-------------|------------------|----------|----------|--------------------|
| Filled      | textPrimary      | なし     | baseBG   | 主要アクション     |
| Tinted      | white 10%        | なし     | primary  | キャンセル等       |
| Glass       | white 7%         | 14%      | primary  | 重ね要素上         |
| Outline     | transparent      | 1.5pt    | primary  | 代替アクション     |
| Destructive | white 8%         | red 50%  | red 90%  | 削除（赤は例外許可）|
| Plain       | transparent      | なし     | primary  | スキップ等         |

### ステート

| State    | Transform    | Opacity | 備考                    |
|----------|-------------|---------|-------------------------|
| Default  | scale(1.0)  | 1.0     | 通常                    |
| Pressed  | scale(0.96) | 0.6     | `.quick` spring         |
| Disabled | scale(1.0)  | —       | bg 12%、text 25%        |
| Loading  | scale(1.0)  | 0.85    | spinner + テキスト変更  |

### アイコンボタン

| Type        | Size      | Radius | 用途              |
|-------------|-----------|--------|-------------------|
| Circle LG   | 52×52pt   | 50%    | FAB相当           |
| Circle MD   | 44×44pt   | 50%    | 標準アイコンボタン|
| Circle SM   | 36×36pt   | 50%    | 補助              |
| Glass       | 44×44pt   | 50%    | ガラス背景        |
| Square      | 44×44pt   | 14pt   | グリッド内        |
| Pill + Icon | 44pt H    | pill   | テキスト付き      |

### Border Chaser ボタン（Apple Intelligence スタイル）

AIアクション専用。ボーダーハイライトがボタンの周りを**1周し続ける**アニメーション。

```swift
// BorderChaserButton.swift
// 実装: CAShapeLayer + CAKeyframeAnimation
// stroke-dashoffset を 0 → -(perimeter) でアニメーション
// グラデーション: white 0% → white 95% → white 40% → white 0%（彗星の尾）
```

**Speed 使い分け**

| Speed  | 時間  | 使用場面            |
|--------|-------|---------------------|
| Slow   | 4.0s  | 待機中・Idle状態    |
| Normal | 2.4s  | 通常のAIアクション  |
| Fast   | 1.2s  | AI処理中・生成中    |

---

## 8. チャットUI

### バブルスタイル

```
ユーザーバブル（右寄り）
  background : glass Heavy (white 14%)
  border     : white 22% / 0.5pt
  border-radius : 16 4 16 16
  text color : white 92%

AIバブル（左寄り）
  左ライン   : white 20% / 2pt width（AI識別）
  background : glass Medium (white 7%)
  border     : white 11% / 0.5pt
  border-radius : 4 16 16 16
  text color : white 52%（ユーザーより薄い）
```

### AI識別デザイン方針

カラーなし縛りの中での差別化（**左ライン + opacity差**を採用）：

| 要素           | ユーザー      | AI                  |
|----------------|---------------|---------------------|
| テキスト opacity | 92%         | 52%（薄い）         |
| バブル opacity   | 14%         | 7%（薄い）          |
| 左ライン       | なし          | あり（white 20%）   |
| 角丸           | 16 4 16 16    | 4 16 16 16          |
| 配置           | 右寄り        | 左寄り              |

### チップ（AI登録確認表示）

AIが登録した内容をバブル内にチップで表示する。

```
background : white 10%
border     : white 16% / 0.5pt
border-radius : pill
padding    : 3pt 9pt
font       : micro (10pt semibold)
color      : white 62%
```

---

## 9. 送信ボタン States

**4ステート遷移：**

```
Empty ──(入力)──▶ Ready ──(タップ)──▶ Processing ──(完了)──▶ Done ──(0.6s)──▶ Empty
```

| State      | 見た目                                | インタラクション        |
|------------|---------------------------------------|-------------------------|
| Empty      | 薄いガラス円 + ＋アイコン(25%)        | disabled                |
| Ready      | 白塗り円 + ↑アイコン                  | タップ可能              |
| Processing | **Border Chaser 周回(1.2s)** + アイコン薄| disabled（入力も）    |
| Done       | ガラス円 + ✓アイコン                  | 0.6s後 Empty へリセット |

```swift
// SendButton.swift
enum SendButtonState {
    case empty
    case ready
    case processing  // Border Chaser Fast (1.2s)
    case done
}
```

---

## 10. タブバー

### タブ順序（左 → 右）

```
メモ  |  TODO  |  チャット（中央・デフォルト）  |  カレンダー  |  設定
  0       1                2                         3            4
```

### 横スワイプ（Instagram式）

```swift
// MainTabView.swift
TabView(selection: $selectedTab) {
    MemoView()      .tag(0)
    TodoView()      .tag(1)
    ChatView()      .tag(2)  // 起動時デフォルト
    CalendarView()  .tag(3)
    SettingsView()  .tag(4)
}
.tabViewStyle(.page(indexDisplayMode: .never))
// デフォルト TabBar は非表示 → カスタム FooterTabBar に置き換え
```

### アイコン仕様（SF Symbols）

```swift
let tabs = [
    (inactive: "doc.text",    active: "doc.text.fill",    label: "メモ"),
    (inactive: "checklist",   active: "checklist",         label: "TODO"),
    (inactive: "bubble.left", active: "bubble.left.fill",  label: ""),   // 中央はラベルなし
    (inactive: "calendar",    active: "calendar",           label: "カレンダー"),
    (inactive: "gearshape",   active: "gearshape.fill",    label: "設定"),
]
// 非アクティブ : opacity 28%
// アクティブ   : opacity 92%
// 中央チャット : ラベルなし、アクティブ時に小ドット（3×3pt）表示
```

### フッタースタイル

```
height   : 60pt + safe area bottom
blur     : 28pt
Dark  bg : rgba(18,16,14, 0.90) + ultraThinMaterial
Dark  border-top : white 9% / 0.5pt
Light bg : rgba(250,248,244, 0.92) + ultraThinMaterial
Light border-top : black 7% / 0.5pt
```

### 浮遊入力バー（チャット専用）

```
bottom       : フッター上端 + 8pt（= 68pt from bottom）
left / right : 12pt
height       : 48pt
border-radius: 24pt（Capsule）
shadow       : 0 8pt 24pt black 40%

Dark  bg : rgba(25,22,19, 0.80) + blur(24) / border white 14%
Light bg : rgba(248,245,240, 0.85) + blur(24) / border black 10%

※ チャットタブのみ表示。他タブでは非表示。
```

---

## 11. 背景エフェクト

### Warm Charcoal（Dark）

```swift
// AmbientBackground.swift
ZStack {
    Color(hex: "#0F0E0D").ignoresSafeArea()

    // 右上 — 暖かいオーブ
    Circle()
        .fill(RadialGradient(
            colors: [Color(hex: "#FFEBCC").opacity(0.04), .clear],
            center: .center, startRadius: 0, endRadius: 200
        ))
        .frame(width: 360, height: 360)
        .offset(x: 130, y: -130)
        .blur(radius: 40)

    // 左下 — 暖かいオーブ
    Circle()
        .fill(RadialGradient(
            colors: [Color(hex: "#FFF5E8").opacity(0.025), .clear],
            center: .center, startRadius: 0, endRadius: 150
        ))
        .frame(width: 280, height: 280)
        .offset(x: -80, y: 320)
        .blur(radius: 30)
}
```

### Warm Paper（Light）

```swift
ZStack {
    Color(hex: "#F8F6F2").ignoresSafeArea()
    // ノイズテクスチャ: opacity 0.03（subtle grain）
}
```

---

## 12. アクセシビリティ

| 項目             | 対応内容                                       |
|------------------|------------------------------------------------|
| Dynamic Type     | `scaledFont` 使用、全テキスト対応              |
| コントラスト比   | 最低 4.5:1（テキスト）                         |
| VoiceOver        | 全インタラクティブ要素に `accessibilityLabel`  |
| Reduce Motion    | `@Environment(\.accessibilityReduceMotion)` 確認|
| 最小タップ目標   | 44 × 44pt（HIG必須）                           |

---

## 13. 未実装・TODO

```
[ ] アプリキャラクター（優先度: Medium）
    - AIアシスタントのキャラクターアイコン設計
    - チャット画面のAIアバターとして使用予定
    - デザイン方針: ガラスデザインに溶け込むミニマルなキャラクター
    - カラーなし縛りに合わせたモノトーンデザイン

[ ] オンボーディング画面
[ ] プッシュ通知デザイン
[ ] ウィジェット（iOS ホーム画面）
[ ] Apple Watch 対応
```

---

## 14. AIへの指示プロンプト

```
あなたはiOSアプリのUI/UXデザイナー兼Swiftエンジニアです。
DESIGN_SYSTEM.md の内容を厳守してSwiftUIコードを生成してください。

【デザイン原則】
- Apple Human Interface Guidelines (HIG) に完全準拠
- Glassmorphism（ガラス素材）を基本とする
- アクセントカラーは一切使用しない
  例外: Destructive アクションのみ赤を許容
- ダーク背景: Warm Charcoal (#0F0E0D)
- ライト背景: Warm Paper (#F8F6F2)

【必須実装】
- cornerRadius は必ず style: .continuous
- アニメーションは必ず Animation.spring() を使用
- ガラスは .ultraThinMaterial + Color.white.opacity() の重ね合わせ
- フォントは SF Pro（system font）のみ
- セーフエリアを必ず考慮する
- 最小タップ目標 44 × 44pt を守る

【チャットUI】
- ユーザーバブル: glass 14%、テキスト 92%、右寄り
- AIバブル: 左ライン(white 20%) + glass 7%、テキスト 52%、左寄り
- 送信ボタンは 4ステート（empty/ready/processing/done）
- processing は Border Chaser アニメーション（Fast 1.2s）

【タブバー】
- 順序（左→右）: メモ | TODO | チャット | カレンダー | 設定
- SF Symbols: 非アクティブ=outline、アクティブ=fill
- 横スワイプ切替（TabView .page スタイル）
- 入力バーはチャットタブのみ、フッター上に浮遊（bottom: 68pt）

【禁止事項】
- アクセントカラーの使用（Destructive以外）
- デフォルトアニメーション（withAnimation {} のみ）
- 角丸なしの要素（最低 cornerRadius: 8）
- 過剰な shadow（0.5pt border で代用）
```

---

## 15. ファイル配置

```
ScheduleAI/
│
├── App/
│   ├── ScheduleAIApp.swift
│   └── AppDelegate.swift
│
├── Core/
│   ├── Security/
│   │   ├── KeychainManager.swift
│   │   ├── BiometricAuth.swift
│   │   └── EncryptionHelper.swift
│   │
│   ├── Network/
│   │   ├── APIClient.swift
│   │   └── NetworkMonitor.swift
│   │
│   ├── Styles/                          ← デザインシステム実装
│   │   ├── ColorTheme.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   ├── CornerRadius.swift
│   │   ├── GlassMaterial.swift
│   │   ├── Animations.swift
│   │   ├── ButtonStyles.swift
│   │   └── BorderChaserButton.swift     ← AI周回アニメーション
│   │
│   ├── Components/                      ← 共通UIコンポーネント
│   │   ├── SendButton.swift             ← 4ステート送信ボタン
│   │   ├── ChatBubble.swift             ← AI・ユーザーバブル
│   │   ├── Chip.swift
│   │   ├── FloatingInputBar.swift
│   │   ├── FooterTabBar.swift
│   │   ├── AmbientBackground.swift
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   │
│   └── Extensions/
│       ├── Date+Extension.swift
│       ├── String+Extension.swift
│       ├── Color+Extension.swift        ← hex init
│       └── View+Extension.swift
│
├── Features/
│   ├── Chat/
│   │   ├── Views/
│   │   │   ├── ChatView.swift
│   │   │   ├── MessageListView.swift
│   │   │   └── MessageBubbleView.swift
│   │   ├── ViewModels/
│   │   │   └── ChatViewModel.swift
│   │   ├── Models/
│   │   │   └── Message.swift
│   │   └── Services/
│   │       └── AIService.swift
│   │
│   ├── Calendar/
│   │   ├── Views/
│   │   │   ├── CalendarView.swift
│   │   │   └── EventDetailView.swift
│   │   ├── ViewModels/
│   │   │   └── CalendarViewModel.swift
│   │   ├── Models/
│   │   │   └── CalendarEvent.swift
│   │   └── Services/
│   │       └── CalendarService.swift    ← EventKit
│   │
│   ├── Todo/
│   │   ├── Views/
│   │   │   ├── TodoListView.swift
│   │   │   └── TodoItemView.swift
│   │   ├── ViewModels/
│   │   │   └── TodoViewModel.swift
│   │   ├── Models/
│   │   │   └── TodoItem.swift
│   │   └── Services/
│   │       └── TodoService.swift
│   │
│   ├── Memo/
│   │   ├── Views/
│   │   │   ├── MemoListView.swift
│   │   │   └── MemoDetailView.swift
│   │   ├── ViewModels/
│   │   │   └── MemoViewModel.swift
│   │   ├── Models/
│   │   │   └── Memo.swift
│   │   └── Services/
│   │       └── MemoService.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   ├── ProfileView.swift        ← 名前等
│       │   └── AccountView.swift        ← ログアウト等
│       ├── ViewModels/
│       │   └── SettingsViewModel.swift
│       └── Services/
│           └── AuthService.swift
│
├── Infrastructure/
│   ├── Firebase/
│   │   ├── FirebaseManager.swift
│   │   └── FirestoreService.swift
│   └── AI/
│       ├── AIProvider.swift             ← プロトコル定義
│       └── GroqProvider.swift           ← Groq実装（メイン）
│
└── Resources/
    ├── Assets.xcassets
    ├── Colors.xcassets                  ← ダーク/ライト対応カラーセット
    ├── Info.plist
    └── Localizable.strings
```

---

> **管理ブランチ**: `feature/project-directory-structure`
> デザインの変更は必ずこのファイルを先に更新してからコードに反映すること。
> キャラクターデザインが完成したら Section 13 の TODO を更新する。