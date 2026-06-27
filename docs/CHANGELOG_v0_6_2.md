# v0.6.2 BattleState抽出

## 追加
- `scripts/battle/BattleState.gd` を追加
- 戦闘中の状態、デッキ、山札、捨て札、手札、バトルログを `BattleState` に集約

## 変更
- `Main.gd` は `battle_state` を参照してバトルUIを描画する形に整理
- ラン開始、戦闘開始、ドロー、手札破棄、手札からのカード除去、基本コスト計算、支払い可否、次敵名の取得を `BattleState` 側へ移動
- カード効果、敵AI、演出、SFX、報酬画面UIは既存のまま維持

## メモ
- v0.6.3 で `CardEffects` 抽出予定
- v0.6.4 で `FxController` / `Sfx` 整理予定
