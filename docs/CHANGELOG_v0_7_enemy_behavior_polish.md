# v0.7 Enemy Behavior Polish

## Changed
- バネクラゲの敵予告を「反発」や「びよん反撃」が伝わる文言に調整。
- バネクラゲを押した時のログに、反発したことが分かる短文を追加。
- バネクラゲの押されリアクションで `hit` 差分と戻り揺れを強めた。
- 帯電ネズミの敵予告を「充電中」と「放電」に分かれる文言へ調整。
- 帯電ネズミの充電ログに、放電までの残りターンを表示。
- 帯電ネズミの放電演出で `discharge` 差分と浮き文字を少し強化。
- 新敵向けの報酬理由を短く読みやすい文言へ調整。

## Not Changed
- 新カード、新敵、画像は追加していません。
- 敵HP、攻撃値、押し量、壁衝突ダメージは変更していません。

## Verification
- Godot 4.6.1 headless 起動: OK
- SMOKE_OK
- ENEMY_REACTIONS_OK
- REWARD_REASONS_OK
- CONTENT_PACK_OK
- NEW_CONTENT_RESOURCES_OK
- ASSET_ALPHA_OK
- ENEMY_BEHAVIOR_POLISH_OK
- git diff --check: OK
