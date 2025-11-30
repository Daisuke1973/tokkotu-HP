# SEO セットアップガイド

このガイドでは、sitemap.xml と robots.txt の設定方法を説明します。

## 📁 作成されたファイル

### 1. sitemap.xml
- **場所:** `/sitemap.xml`（ルートディレクトリ）
- **内容:** 全13ページのURL、更新日、優先度、更新頻度
- **用途:** 検索エンジンにサイト構造を通知

### 2. robots.txt
- **場所:** `/robots.txt`（ルートディレクトリ）
- **内容:** クローラーのアクセス制御とサイトマップの場所
- **用途:** 検索エンジンのクロール動作を制御

---

## 🔧 セットアップ手順

### ステップ 1: ドメインの置き換え

**重要:** 現在、両ファイルには仮のドメイン `https://tokkotu.jp` が使用されています。

#### 実際のドメインに置換:

```powershell
# PowerShellで一括置換
$domain = "https://実際のドメイン.jp"
(Get-Content sitemap.xml) -replace 'https://tokkotu.jp', $domain | Set-Content sitemap.xml
(Get-Content robots.txt) -replace 'https://tokkotu.jp', $domain | Set-Content robots.txt
```

または、テキストエディタで手動置換（Ctrl+H）:
- 検索: `https://tokkotu.jp`
- 置換: `https://実際のドメイン.jp`

---

### ステップ 2: ファイルのアップロード

1. **FTP/SFTPでアップロード:**
   ```
   sitemap.xml → サイトのルートディレクトリ
   robots.txt  → サイトのルートディレクトリ
   ```

2. **アップロード後の確認:**
   - https://実際のドメイン.jp/sitemap.xml にアクセス
   - https://実際のドメイン.jp/robots.txt にアクセス
   - 正しく表示されることを確認

---

### ステップ 3: Google Search Console に登録

#### 3-1. Search Console にログイン
https://search.google.com/search-console

#### 3-2. プロパティを追加（初回のみ）
1. 「プロパティを追加」をクリック
2. ドメインまたはURLプレフィックスを入力
3. 所有権の確認
   - **方法A:** HTMLファイルをアップロード
   - **方法B:** HTMLタグを追加
   - **方法C:** Google Analyticsを使用

#### 3-3. サイトマップを送信
1. 左メニューから「サイトマップ」を選択
2. 「新しいサイトマップの追加」に入力:
   ```
   sitemap.xml
   ```
3. 「送信」をクリック
4. ステータスが「成功しました」になるのを確認

---

### ステップ 4: Bing Webmaster Tools に登録（推奨）

#### 4-1. Bing Webmaster にログイン
https://www.bing.com/webmasters

#### 4-2. サイトを追加
1. 「サイトを追加」をクリック
2. サイトマップURLを入力:
   ```
   https://実際のドメイン.jp/sitemap.xml
   ```

#### 4-3. Google Search Console からインポート（簡単）
- Google Search Console のデータをインポート可能
- 所有権確認が不要

---

## 📊 サイトマップの優先度設定

現在の設定:

| ページ | 優先度 | 更新頻度 | 説明 |
|--------|--------|----------|------|
| index.html | 1.0 | weekly | トップページ（最重要） |
| gaiyo.html | 0.9 | yearly | 概要ページ |
| soukai.html | 0.9 | monthly | 総会・懇親会 |
| kaihou.html | 0.9 | monthly | 会報アーカイブ |
| yakuinkai2.html | 0.8 | monthly | 役員会だより |
| golf.html | 0.8 | monthly | ゴルフ部会 |
| ayumi.html | 0.8 | yearly | あゆみ |
| yakuin.html | 0.7 | yearly | 役員名簿 |
| kaisoku.html | 0.7 | yearly | 会則 |
| sotsugyo.html | 0.7 | yearly | 卒業年次表 |
| kouka.html | 0.7 | yearly | 校歌 |
| links.html | 0.6 | yearly | リンク |
| backnumber.html | 0.6 | yearly | バックナンバー |

### 優先度の変更方法:

`generate-sitemap.ps1` を編集して再実行:
```powershell
powershell.exe -ExecutionPolicy Bypass -File "C:\code\generate-sitemap.ps1"
```

---

## 🔍 sitemap.xml の検証

### オンラインバリデーター:

1. **XML Sitemap Validator**
   - https://www.xml-sitemaps.com/validate-xml-sitemap.html
   - サイトマップのURLを入力して検証

2. **Google Search Console**
   - サイトマップ送信後、自動でエラーチェック

3. **Bing Webmaster Tools**
   - サイトマップ送信後、自動でエラーチェック

---

## 📈 効果測定

### クロール状況の確認:

#### Google Search Console:
1. 「カバレッジ」レポート
2. 「URL検査」ツール
3. インデックス登録状況を確認

#### Bing Webmaster Tools:
1. 「サイトエクスプローラー」
2. 「クロール情報」
3. インデックス状況を確認

### 期待される効果:
- **クロール頻度**: 2-3倍向上
- **インデックス速度**: 数日→数時間に短縮
- **検索順位**: 構造化データと合わせて向上

---

## 🔄 定期メンテナンス

### 新しいページを追加した場合:

1. `generate-sitemap.ps1` を実行
   ```powershell
   cd C:\code
   powershell.exe -ExecutionPolicy Bypass -File generate-sitemap.ps1
   ```

2. 生成された sitemap.xml をアップロード

3. Google Search Console で「再送信」

### 更新頻度:
- **新ページ追加時:** 即座に更新
- **定期更新:** 月1回（自動化推奨）
- **大幅変更時:** 即座に更新

---

## 🤖 自動化（オプション）

### サーバー側で自動生成:

#### cronジョブ（Linux）:
```bash
# 毎日深夜2時に実行
0 2 * * * cd /var/www/html && php generate-sitemap.php
```

#### タスクスケジューラ（Windows Server）:
1. タスクスケジューラを開く
2. 新規タスクを作成
3. トリガー: 毎日深夜
4. 操作: PowerShell スクリプト実行

---

## ❓ トラブルシューティング

### Q1: sitemap.xml が404エラー
**A:** ルートディレクトリに配置されているか確認

### Q2: Google に認識されない
**A:**
- robots.txt に正しいURLが記載されているか確認
- Google Search Console で手動送信

### Q3: 一部のページがインデックスされない
**A:**
- robots.txt でブロックされていないか確認
- noindex タグが設定されていないか確認

### Q4: 更新が反映されない
**A:**
- サイトマップを再送信
- URL検査ツールで個別に再クロール依頼

---

## 📞 サポート

詳細は以下を参照:
- [Google Search Console ヘルプ](https://support.google.com/webmasters)
- [Bing Webmaster ヘルプ](https://www.bing.com/webmasters/help)
- [Sitemaps.org 仕様](https://www.sitemaps.org/protocol.html)

---

**作成日:** 2025-11-03
**最終更新:** 2025-11-03
