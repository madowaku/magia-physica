# v0.6.3 CardEffects抽出

## 変更内容
- `scripts/battle/CardEffects.gd` を追加し、カード効果処理を `Main.gd` から分離しました。
- 押力式、勢式、熱式、余白回収、質量測定、摩擦式、小石生成の状態更新を `CardEffects` に移動しました。
- カード効果による `battle_state` 更新、バトルログ文言、`pending_fx` 用 Dictionary 生成を `CardEffects` 側にまとめました。
- `Main.gd` はカード使用時のコスト支払い、手札除去、SFX再生、返却された `pending_fx` の保持に寄せました。

## 確認
- Godot 4.6.1 で起動ログにエラーがないことを確認しました。
- ヘッドレス smoke で `SMOKE_OK` 相当の完了を確認しました。
- 「はじめる」「すぐバトル」、カード選択、全カード種の発動、ターン終了、勝利報酬画面を確認しました。

## 補足
- UI生成、Tween演出、SFX再生、敵AI、報酬画面UIは今回の対象外です。
- v0.6.4 で `FxController` / SFX 整理に進める前段として、効果処理と演出呼び出しの境界を作りました。
