# マギア・フィジカ 面白さ強化トランシェ

## Objective

マギア・フィジカを Steam 有料販売を目指せる面白さと完成度に近づけるため、現状を壊さずに最初の安全な実装スライスを発見し、実装し、Godot 4.6.1 で検証する。

## Goal Kind

`open_ended`

## Current Tranche

リポジトリと現行バトル体験を調査し、最初に入れる価値が高く安全な改善を1つ選び、実装・検証・監査まで行う。計画だけで止めず、ただし v0.6.3 の CardEffects 抽出差分とは独立したPRとして扱う。

## Non-Negotiable Constraints

- Godot 4.6.1 で起動できる状態を維持する。
- 日本語UIと既存のゲーム文言・雰囲気を維持する。
- 戦闘数値や敵AIは変更しない。
- 未追跡の patch README、apply scripts、`.import`、`patch_assets/` は混ぜない。
- UI、演出、SFX、カード効果、データの変更は小さく検証しやすい単位に分ける。

## Stop Rule

現在のトランシェ監査が通る、すべての安全なローカル作業がブロックされる、または続行に認証・破壊的操作・オーナー判断が必要になったら止まる。

計画、調査、Judge 選定だけでは止まらない。安全な Worker タスクが選べる場合は実装して検証する。

## Canonical Board

Machine truth lives at:

`docs/goals/magia-physica-fun-tranche/state.yaml`

If this charter and `state.yaml` disagree, `state.yaml` wins for task status, active task, receipts, verification freshness, and completion truth.

## Run Command

```text
/goal Follow docs/goals/magia-physica-fun-tranche/goal.md through the first safe verified implementation slice. Do not stop after planning unless blocked.
```

