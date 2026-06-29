# Unityroom Web Export

このメモは、Godot 4.6.1 で `Magia Physica: First Formula` を unityroom 投稿用の Web ビルドにする手順です。

## 1. 前提環境

- Godot 4.6.1
- Web export templates が Godot にインストール済み
- Windows / PowerShell
- プロジェクトパス: `C:\Dev\Projects\magia-physica`
- unityroom 用出力先: `build/unityroom/`

このリポジトリでは `export_presets.cfg` に `Unityroom Web` preset を用意しています。

ローカル検証で Godot のユーザーデータ保存先が詰まる場合は、検証時だけ次の環境変数を使います。

```powershell
$env:APPDATA='C:\tmp\godot-appdata'
$env:LOCALAPPDATA='C:\tmp\godot-localappdata'
```

Godot 4.6.1 portable を使う場合の想定パス:

```powershell
C:\tmp\godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe
```

## 2. Godot から Web export する手順

1. Godot 4.6.1 で `C:\Dev\Projects\magia-physica` を開く。
2. `Project > Export...` を開く。
3. `Unityroom Web` preset を選ぶ。
4. `Thread Support` が OFF になっていることを確認する。
5. Export Path が `build/unityroom/index.html` になっていることを確認する。
6. `Export Project...` を押して出力する。

## 3. CLI export する手順

PowerShell で実行します。

```powershell
cd C:\Dev\Projects\magia-physica
$env:APPDATA='C:\tmp\godot-appdata'
$env:LOCALAPPDATA='C:\tmp\godot-localappdata'
& 'C:\tmp\godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:\Dev\Projects\magia-physica' --export-release 'Unityroom Web' 'build/unityroom/index.html'
```

Web export templates が無い場合は、Godot 側で export templates をインストールしてから再実行します。

## 4. build/unityroom/ の中身確認

出力後に、少なくとも次のようなファイルがあることを確認します。

```text
build/unityroom/index.html
build/unityroom/index.js
build/unityroom/index.pck
build/unityroom/index.wasm
```

`build/unityroom/` は `.gitignore` 済みなので、出力物はコミットしません。

## 5. ローカル HTTP サーバーでの起動確認

ブラウザで直接 `index.html` を開くのではなく、HTTP サーバー経由で確認します。

```powershell
cd C:\Dev\Projects\magia-physica\build\unityroom
python -m http.server 8000
```

ブラウザで開くURL:

```text
http://localhost:8000/
```

確認後、PowerShell で `Ctrl+C` を押してサーバーを止めます。

## 6. unityroom アップロード前チェックリスト

- `Unityroom Web` preset で出力している。
- `Thread Support` が OFF。
- 出力先が `build/unityroom/index.html`。
- `build/unityroom/` に `index.html`, `index.js`, `index.pck`, `index.wasm` がある。
- `http://localhost:8000/` で起動できる。
- 1280x720基準で画面が崩れていない。
- 音が鳴る場合、ブラウザの初回操作後に鳴ることを確認する。
- `build/unityroom/` をコミットしていない。

## 7. 既知の注意点

- unityroom 向けには Thread Support OFF を前提にします。
- Web export templates が未インストールだと CLI export は失敗します。
- Godot の終了時に既存のリソース解放警告が出る smoke があります。exit code 0 で smoke が通る限り、現時点ではブロッカー扱いにしません。
- `APPDATA` / `LOCALAPPDATA` を `C:\tmp` 配下に向ける設定は検証時だけの環境回避です。プロジェクト設定には入れません。
- ブラウザ環境ごとの日本語フォント差を避けるため、UI 用フォントは `assets/fonts/` に同梱します。フォント追加時はライセンスファイルも一緒に管理します。
