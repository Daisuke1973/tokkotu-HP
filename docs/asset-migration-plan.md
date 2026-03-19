# Asset Migration Plan

## 目的

このサイトは、画像・音声・運用用ファイルの置き場が時期ごとに増築されており、次の課題があります。

- 公開ファイルと運用ファイルが同じ階層に混在している
- 画像の分類軸が `photo/`、`2025/`、`music/` などで分かれている
- ファイル名に全角数字、空白、`(1)`、端末依存名が混在している
- 原本と公開用画像が分かれておらず、大きい画像をそのまま配信している

この計画では、現行ページを壊さずに、段階的に新しい資産構造へ移行する。

## 現在の移行状態

- 主要ページの画像・音声参照は `assets/` 配下へ移行済み
- 旧 `photo/`、`music/`、`2024/`、`2025/` 原本は `work/originals/` に退避済み
- 監査スクリプトで `MissingReferences: 0` を継続確認する運用へ切り替えている

## 今回採用する移行方針

- HTML、CSS、JS は当面ルート直下に残す
- 新しい画像・音声は `assets/` 配下へ集約する
- 一時ファイル、棚卸しレポート、原本退避先は `work/` 配下に置く
- 運用スクリプトは `tools/`、設計文書は `docs/` に集約する
- 既存の参照は一気に変えず、ページ単位で移行する

## 目標ディレクトリ構成

```text
/
|-- index.html
|-- gaiyo.html
|-- soukai.html
|-- kaihou.html
|-- yakuinkai2.html
|-- golf.html
|-- style.css
|-- script.js
|-- assets/
|   |-- images/
|   |   |-- shared/
|   |   |   |-- branding/
|   |   |   |-- ui/
|   |   |   `-- backgrounds/
|   |   |-- events/
|   |   |   |-- soukai/
|   |   |   |-- yakuinkai/
|   |   |   `-- golf/
|   |   `-- archives/
|   |       |-- kaiho/
|   |       `-- legacy/
|   `-- audio/
|       `-- songs/
|-- docs/
|   `-- asset-migration-plan.md
|-- tools/
|   `-- asset-audit.ps1
`-- work/
    |-- originals/
    `-- reports/
```

## 置き場ルール

### 1. 共通画像

- ロゴ、QR、背景、UI用画像は `assets/images/shared/` に置く
- 例:
  - `assets/images/shared/branding/logo-mark1.gif`
  - `assets/images/shared/ui/63-tokkotsukai-qr.png`
  - `assets/images/shared/backgrounds/site-background.jpg`

### 2. イベント画像

- イベント単位で `assets/images/events/<category>/<yyyy-mm-dd>/` に置く
- `category` は `soukai`、`yakuinkai`、`golf` を使う
- 例:
  - `assets/images/events/soukai/2025-06-07/gallery-01.jpg`
  - `assets/images/events/yakuinkai/2026-02-17/gallery-26.jpg`
  - `assets/images/events/golf/2015-11-19/gallery-01.jpg`

### 3. 会報などのアーカイブ画像

- 会報は `assets/images/archives/kaiho/<issue-number>/` に置く
- 旧ページの分類が読み解けないものは `assets/images/archives/legacy/` に一時退避する
- 例:
  - `assets/images/archives/kaiho/42/page-01.jpg`
  - `assets/images/archives/kaiho/42/page-12.jpg`

### 4. 音声

- 校歌・応援歌などは `assets/audio/songs/` に集約する
- 例:
  - `assets/audio/songs/asahikawa-junior-high-school-song.m4a`
  - `assets/audio/songs/asahikawa-higashi-school-song.m4a`
  - `assets/audio/songs/asahikawa-higashi-ouenka.m4a`

### 5. 原本と公開用の分離

- 原本は `work/originals/` に退避する
- 公開用は `assets/` のみを参照する
- 高解像度の元画像は非公開運用に寄せる

## 命名ルール

- 公開用ファイル名は `lowercase-ascii + hyphen` を基本にする
- 全角数字、空白、日本語、`(1)`、`IMG_1234.JPG` は公開名に使わない
- 連番は `01`, `02`, `03` のゼロ埋めにする
- 拡張子は小文字に統一する

### 良い例

- `gallery-01.jpg`
- `page-01.jpg`
- `63-tokkotsukai-qr.png`
- `site-background.jpg`

### 避ける例

- `０new.jpg`
- `00_表紙_H1-4.p1.p1 (1)_page-0001.jpg`
- `IMG_9659.JPG`
- `北口選手応援コーナー 416.jpg`

## 現状からのマッピング例

| 現在 | 移行先 |
| --- | --- |
| `photo/mark1.gif` | `assets/images/shared/branding/logo-mark1.gif` |
| `photo/img/63_tokkotsukai_qr.png` | `assets/images/shared/ui/63-tokkotsukai-qr.png` |
| `photo/473041961_29005869285679317_8590079737183509684_n.jpg` | `assets/images/shared/backgrounds/site-background.jpg` |
| `music/旭川東高校逍遥歌.mp3` | `assets/audio/songs/asahikawa-higashi-shoyoka.mp3` |
| `2025/０new.jpg` | `assets/images/events/soukai/2025-06-07/gallery-01.jpg` |
| `photo/yakuinkai/img/2026_02_17_yakuinkai/IMG_9659.JPG` | `assets/images/events/yakuinkai/2026-02-17/gallery-26.jpg` |
| `photo/kaiho42/00_表紙_H1-4.p1.p1 (1)_page-0001.jpg` | `assets/images/archives/kaiho/42/page-01.jpg` |

## 移行ステップ

### Phase 0. 棚卸し

- `tools/asset-audit.ps1` を実行して、現状の参照状況をCSVで出力する
- 未参照ファイル、参照切れ、1MB超画像、命名ルール違反を確認する

実行例:

```powershell
pwsh -File .\tools\asset-audit.ps1
```

### Phase 1. 骨組み作成

- `assets/`, `docs/`, `work/` を作る
- 新規追加資産は旧フォルダに置かない

### Phase 2. 共通資産の移行

- まずロゴ、QR、背景画像、音声のような共通資産から移行する
- 対象:
  - `photo/mark1.gif`
  - `photo/img/63_tokkotsukai_qr.png`
  - `photo/473041961_29005869285679317_8590079737183509684_n.jpg`
  - `music/*.m4a`, `music/*.mp3`

### Phase 3. 最近のイベントページから移行

- 影響範囲が明確な最近のページから順に進める
- 優先順:
  1. `index.html`
  2. `kouka.html`
  3. `soukai.html`
  4. `yakuinkai2.html`
  5. `golf.html`

### Phase 4. アーカイブ整理

- `photo/kaiho*`、`photo/*ki_*`、`photo/soukai*_images` を整理する
- 分類が曖昧なものは即断で捨てず、`assets/images/archives/legacy/` に逃がす

### Phase 5. 画像最適化

- 公開用画像は必要サイズへ縮小したものを使う
- 原本は `work/originals/` に退避する
- 最近の大きい写真ページから優先して縮小版へ差し替える

### Phase 6. 旧フォルダの段階的廃止

- 参照ゼロが確定した後に旧パスを削除する
- 旧原本は削除せず `work/originals/` に退避する

## ページごとの更新ルール

- 1回の変更対象は原則1ページに限定する
- 参照先の移動とHTML更新は同じコミットにまとめる
- 移行後は `rg` で旧パス参照が残っていないか確認する

確認例:

```powershell
rg -n "photo/|music/|2024/|2025/" -g "*.html" -g "*.css" -g "*.js" .
```

## JavaScript の改善方針

現状の `script.js` は、見出し文言から音声ファイルを推測している。
この方式は見出し変更に弱いため、今後は HTML 側に `data-audio` を持たせる。

### 現在

- 見出し文言に `旭川東` や `応援歌` が含まれるかで判定

### 目標

```html
<div class="song-section" data-audio="assets/audio/songs/asahikawa-higashi-school-song.m4a">
```

## 完了条件

- 新規資産が旧フォルダに追加されない
- 主要ページが `assets/` 配下だけを参照する
- 未参照資産一覧が整理済みになる
- 1MB超の公開画像が優先ページで解消される

## 次に着手する具体作業

1. `assets/images/events/` 配下の大きい画像から `display` / `thumb` を作る
2. PC / モバイル実機でギャラリー表示を目視確認する
3. イベント単位の manifest 化で HTML 直書きの画像列挙を減らす