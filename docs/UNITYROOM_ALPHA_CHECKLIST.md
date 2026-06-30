# Unityroom Alpha Checklist

このチェックリストは、unityroom alpha 投稿直前に見る確認表です。
Web export の詳しい手順は `docs/UNITYROOM_EXPORT.md` を参照します。

## Build Baseline

- main HEAD: `5a92daf`
- Godot version: `4.6.1`
- Godot portable path: `C:\tmp\godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe`
- Project path: `C:\Dev\Projects\magia-physica`
- Export preset: `Unityroom Web`
- Export path: `build/unityroom/index.html`
- Thread Support: OFF
- Web UI font: `assets/fonts/NotoSansCJKjp-Regular.otf`

## Pre-Export Checks

- [ ] `main` is current and points at the expected release baseline.
- [ ] The working tree has no intended release changes left uncommitted.
- [ ] `Unityroom Web` preset exists in `export_presets.cfg`.
- [ ] `variant/thread_support=false` is still set for the Web preset.
- [ ] Godot 4.6.1 Web export templates are installed.
- [ ] `build/unityroom/` is treated as generated output and will not be committed.
- [ ] Existing untracked temporary files are not mixed into the release PR.

## Export Commands

PowerShell:

```powershell
cd C:\Dev\Projects\magia-physica
$env:APPDATA='C:\tmp\godot-appdata'
$env:LOCALAPPDATA='C:\tmp\godot-localappdata'
& 'C:\tmp\godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe' --headless --path 'C:\Dev\Projects\magia-physica' --export-release 'Unityroom Web' 'build/unityroom/index.html'
```

Expected output files:

```text
build/unityroom/index.html
build/unityroom/index.js
build/unityroom/index.pck
build/unityroom/index.wasm
```

## Local HTTP Checks

PowerShell:

```powershell
cd C:\Dev\Projects\magia-physica\build\unityroom
python -m http.server 8000 --bind 127.0.0.1
```

Open:

```text
http://127.0.0.1:8000/
```

Manual checks:

- [ ] Title screen appears.
- [ ] Japanese text is readable on the title screen.
- [ ] `すぐバトル` starts battle 1.
- [ ] Battle HUD, enemy notice, card names, and log text are readable.
- [ ] A card can be selected.
- [ ] A value can be assigned to `□`.
- [ ] The selected formula can be activated.
- [ ] A turn can be ended.
- [ ] Battle 1 can be cleared.
- [ ] Reward screen appears after victory.
- [ ] Card book opens from the title screen.
- [ ] Audio and FX do not produce console errors or warnings.

## Zip Packaging Checks

- [ ] Zip from the contents of `build/unityroom/`, not from the parent `build/` folder.
- [ ] The zip root contains `index.html`, `index.js`, `index.pck`, and `index.wasm`.
- [ ] The zip does not contain `.git`, export templates, source files, or editor cache files.
- [ ] Reopen the zip and confirm the root layout before upload.
- [ ] Keep the generated zip outside git or in an ignored location.

## Unityroom Page Draft

### Short Description

式に力を代入して、敵を押し返すブラウザ向け物理カードバトルです。

### Game Description

`マギア・フィジカ：第一式` は、カードに書かれた式の `□` に式力を入れて効果を変える、短編の物理カードバトルです。
敵の位置、壁までの距離、手札の式を見ながら、押す・回収する・小石を作るなどの効果を組み合わせて戦います。

alpha 版では、最初の戦闘と基本的なカード体験を確認できます。

### Controls

- Mouse / touch: select cards and buttons.
- `□` buttons: choose how much formula power to assign.
- `発動`: activate the selected card.
- `ターン終了`: end the current turn.
- `図鑑`: view cards from the title or battle screen.

### Author Comment

まだ alpha 版ですが、「式に代入すると盤面が動く」感触を最優先で調整しています。
遊んでいて分かりづらい点や、ブラウザでの表示崩れがあればフィードバックをもらえるとうれしいです。

### Recommended Environment

- Desktop browser is recommended for the first alpha.
- 1280x720 or larger display is recommended.
- Modern Chrome / Edge / Firefox browsers are expected.
- Audio starts after the first browser interaction.

### Known Notes

- This is an alpha build, so card balance and presentation may change.
- Web export uses Thread Support OFF for unityroom compatibility.
- The browser build includes a Japanese UI font, so the download size is larger than the desktop prototype.
- If the first load is slow, wait until the title screen appears before reloading.

## Screenshot Capture List

- [ ] Title screen with the main menu.
- [ ] Battle screen with player HUD, enemy, and hand visible.
- [ ] `□` assignment UI with a selected card.
- [ ] Formula activation moment or damage log.
- [ ] Reward screen after battle 1 victory.
- [ ] Card book screen.

## Final Publish Checks

- [ ] `git diff --check` passes.
- [ ] Godot 4.6.1 headless startup succeeds.
- [ ] Web export succeeds.
- [ ] Local HTTP browser check passes.
- [ ] Browser console has no errors or warnings during the alpha flow.
- [ ] `BATTLE_1_CLEARABILITY_OK` passes.
- [ ] `SMOKE_OK` passes.
- [ ] `ENEMY_REACTIONS_OK` passes.
- [ ] `REWARD_REASONS_OK` passes.
- [ ] `CONTENT_PACK_OK` passes.
- [ ] `NEW_CONTENT_RESOURCES_OK` passes.
- [ ] `ASSET_ALPHA_OK` passes.
- [ ] Generated `build/unityroom/` files are not staged.
- [ ] Unityroom page text and screenshots are ready.

## Known Non-Blockers

- Godot may print existing resource cleanup warnings after some headless checks. If the check prints its `*_OK` marker and exits with code 0, this is not an alpha blocker.
- `APPDATA` / `LOCALAPPDATA` overrides are local verification helpers only and should not be committed as project settings.
- Future size optimization can consider font subsetting or a lighter Japanese font, but alpha prioritizes readable Japanese text.
