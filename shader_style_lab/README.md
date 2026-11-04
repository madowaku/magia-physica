# MGSF Shader Style Lab M0.1

An isolated Godot 4.6 shader-style experiment, inspired by prompt-driven illustration-to-3D look development. No Tripo account, external API, or paid service is required.

## Run

Open this repository in Godot 4.6, open `res://shader_style_lab/StyleLab.tscn`, then run current scene (F6). This does not change the game's main scene.

- **Space / button**: cycle smooth, toon, and quantized toon.
- **Sliders**: adjust bands and outline parameters live.
- **GLB experiments**: import a licensed GLB, then assign a copy of `style_lab.gdshader` as a ShaderMaterial to its MeshInstance3D materials. Be aware that this minimal shader replaces original PBR textures.

## Scope and limitations

M0.1 demonstrates style parameters and switching on procedurally generated geometry. It does **not** generate shaders from prompts automatically, preserve PBR textures, extract exact illustration aesthetics, or implement true screen-space edge outlines / low-resolution pixels. The ink is view-angle rim shading and may differ from silhouette outlines. The lighting is a fixed view-space approximation to keep the demo dependency-free.

Next: define a JSON style recipe format (palette, bands, ink, pixel resolution), add a prompt-to-recipe *reviewable* generator, and test imported GLB on Forward+ and Compatibility renderers. Visual regression snapshots via Game Test Player come after an executable baseline is verified.

## Acceptance checks

1. The standalone scene loads without affecting `Main.tscn`.
2. Space cycles three visually distinct styles.
3. Sliders update materials immediately without exceptions.
4. Imported mesh can use a duplicated material without modifying source assets.
5. Run headless project import and scene tests in a Godot 4.6 environment before merging.

No automated Godot runtime verification was performed by this change.
