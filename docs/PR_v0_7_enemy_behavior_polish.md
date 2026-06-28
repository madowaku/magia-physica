## 変更内容
- バネクラゲの敵予告を、反発やびよんと跳ね返る性格が伝わる文言に調整しました。
- バネクラゲを押した時に `hit` 差分と戻り揺れを使い、反発したことが伝わるログを追加しました。
- 帯電ネズミの敵予告を「充電中」「次は放電注意」「放電」に分け、放電周期を読みやすくしました。
- 帯電ネズミの放電時に `discharge` 差分と浮き文字を少し強めました。
- 次の敵がバネクラゲ / 帯電ネズミの時の報酬理由を短く調整しました。

## 確認
- Godot 4.6.1 headless 起動: OK
- SMOKE_OK: OK
- ENEMY_REACTIONS_OK: OK
- REWARD_REASONS_OK: OK
- CONTENT_PACK_OK: OK
- NEW_CONTENT_RESOURCES_OK: OK
- ASSET_ALPHA_OK: OK
- ENEMY_BEHAVIOR_POLISH_OK: OK
- git diff --check: OK

## 補足
- 新カード、新敵、新規画像は追加していません。
- 敵HP、攻撃値、押し量、壁衝突ダメージは変更していません。
- 終了時に既存のリソース解放警告が出るsmokeがありますが、今回の確認項目は通過しています。
