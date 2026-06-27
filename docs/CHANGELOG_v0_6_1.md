# v0.6.1 UiFactory抽出

## 追加
- `scripts/ui/UiFactory.gd` を追加し、共通UI helperを分離
- パネル、ラベル、ボタン、背景、テクスチャ、矩形配置の生成処理を `Main.gd` から移動

## 変更
- `Main.gd` は `UiFactory` を経由してUI部品を組み立てる形に整理
- 安全に変更できる範囲で、SFX名と敵素材のローカル変数名を調整して shadowing warning を削減

## 未対応
- `BattleState` 抽出は v0.6.2 で対応予定
- `CardEffects` 抽出は v0.6.3 で対応予定
- `FxController` / `Sfx` 整理は v0.6.4 で対応予定
