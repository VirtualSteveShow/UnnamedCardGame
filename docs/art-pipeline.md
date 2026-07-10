# Card Art Pipeline

How card art actually gets made, end to end. Proven working as of 2026-07-10.

## Tools involved

- **ComfyUI Phone App** (`C:\ComfyUI_Portable\ComfyUI_Phone_App`) — the
  Flux 2 Klein generation server/UI. Has its own repo:
  github.com/VirtualSteveShow/ComfyUIPhoneApp.
- **This game's `art/wip/`** — staging area for raw generations, organized
  in per-faction subfolders (e.g. `art/wip/city_faction/`).
- **This game's `game/assets/`** — final imported textures actually used by
  the game, same per-faction subfolder convention.

## Generating a batch

The phone app's `/txt2img` endpoint accepts (JSON body or multipart form):

```
prompt, seed, steps, width, height, model_id,
save_folder   -- subfolder inside ComfyUI/output (gallery-visible)
save_name     -- base filename
export_path   -- OPTIONAL absolute path; if set, the finished image is ALSO
                 copied there (in addition to, not instead of, the normal
                 save) once the job completes. This is what gets art
                 straight into this game's art/wip/ without a manual
                 copy step, while keeping the ComfyUI gallery intact.
```

Poll `/status/<job_id>` until `status: "done"`, then `filename` is the
gallery-relative path. Each *unique* prompt costs ~45-60s (Flux 2 Klein's
QWEN text encoder has to re-run); identical prompts in the same batch are
cheap (~15s) since ComfyUI caches the conditioning tensors.

## Style notes learned so far

- **512x512, 4 steps** works well for 16-bit pixel-art style creature/scene
  art — higher resolutions push Flux toward softer, less "chunky pixel"
  results.
- Explicit style descriptors matter: "16-bit pixel art", "chunky pixels",
  "thick black outline", "no anti-aliasing", "no blur" keep it from drifting
  toward a soft painterly look.
- **Watch wording for accidental humanoid poses.** Describing an animal as
  "muscular... standing defiantly" pushed Flux toward an upright bipedal
  pose that read as a person in an animal costume. Explicit "on all fours" /
  "quadruped stance" fixes it. Related: clothing/gear draped like it's worn
  by a person (e.g. a vest over an upright torso) doesn't work anatomically
  on a quadruped — collars, bandaged paws, and back-strapped items read much
  better than anything shaped for a human torso.
- A consistent negative-space list at the end of every prompt avoids the
  usual generation junk: `no text, no watermark, no people`.

## Wiring finished art into the game

1. Pick the best generation(s), copy from `art/wip/<faction>/` into
   `game/assets/<faction>/` with a clean filename (drop ComfyUI's
   `_00001_` suffix).
2. Add an entry to `CardDatabase.REAL_CREATURES` in
   `game/scripts/data/card_database.gd`: `[display name, res:// path,
   xp_progress, level]`.
3. Run the Godot editor headless once to force-import the new PNGs:
   `Godot_v4.7-stable_win64_console.exe --headless --editor --quit`
   (generates the matching `.png.import` files — required before the
   texture will actually load).
4. Headless play-test (`--headless --path . --quit-after 10`), export the
   debug APK, deploy over ADB, confirm on-device.
5. Commit `art/wip/` raw files alongside the `game/assets/` final copies —
   keeping both means the raw generation is still around for reference/
   re-cropping without needing to regenerate.
