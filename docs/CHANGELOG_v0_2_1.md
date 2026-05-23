# v0.2.1 修正メモ

Godot 4.6 で `inference_on_variant` 警告がエラー扱いになり、`Main.gd` の `min()` / `clamp()` 由来の Variant 型推論で起動できない問題を修正しました。

## 修正内容

- `min()` / `max()` / `clamp()` を、型安全な `mini()` / `maxi()` / `clampi()` に置き換え
- `var next_index := ...` を `var next_index: int = ...` に変更
- `project.godot` に `debug/gdscript/warnings/inference_on_variant=0` を追加

## 目的

Godot 4.6 系でプロジェクトを開いた時に、Variant 推論警告でパーサーが止まらないようにするための互換修正です。
