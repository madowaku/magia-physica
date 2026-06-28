## 変更内容
- 新敵2体を追加しました。
  - バネクラゲ
  - 帯電ネズミ
- 新カード3枚を追加しました。
  - 弾性測定 / Elastic Scan
  - 磁場反転 / Magnetic Flip
  - 接地式 / Grounding
- 新敵2体は `data/enemies.json` から画像アセットを参照するようにしました。
- 新カード3枚は `data/cards.json` から `assets/images/cards` 側の画像を参照するようにしました。
- カード図鑑を実装し、新カードを中身ありで表示できるようにしました。
- 敵画像はゲーム用に透明背景・軽量化し、バネクラゲと帯電ネズミの `hit` 差分、帯電ネズミの `discharge` 差分を追加しました。

## 確認
- Godot 4.6.1 headless 起動: OK
- SMOKE_OK: OK
- ENEMY_REACTIONS_OK: OK
- REWARD_REASONS_OK: OK
- CONTENT_PACK_OK: OK
- NEW_CONTENT_RESOURCES_OK: OK
- ASSET_ALPHA_OK: OK
- git diff --check: OK

## 補足
- 終了時に既存のリソース解放警告が出るsmokeがありますが、今回追加した新敵・新カードの読み込み確認は通過しています。
- 未追跡の古いパッチ類、不要な `.import` / `.uid` は含めていません。
