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

## Battle sprites (needs a transparent background AND to match the card art)

**Use img2img (`/imgedit`), not an independent txt2img generation.** First
attempt (2026-07-11) generated battle sprites from scratch with a fresh
txt2img prompt per creature, sharing only the text description with the
card art -- the results were inconsistent with the card art (different
proportions, shading, sometimes even markings) since nothing actually tied
the two generations together beyond wording. Redone the same day using
`/imgedit` with the creature's *existing card art as the reference image*,
which keeps coloring/markings/proportions consistent because the model is
now editing the same source rather than reinterpreting a text description
from nothing.

`/imgedit` (`_flux_img_edit_workflow`, ReferenceLatent-based) takes
multipart form data: `image` (the reference file), `prompt`, `seed`,
`steps` (8 works well), optional `export_path`. Poll `/status/<job_id>`
same as txt2img.

- **Prompt pattern that worked**: `"make a side profile of the <creature>
  character on an all white background, full body, <pose/stance
  description>, facing right"`. Keep it short -- ReferenceLatent
  conditioning already pulls the style/coloring from the source image, so
  the prompt only needs to describe the pose change and background, not
  re-describe the whole creature's appearance.
- **Same background rule as before**: ask for a flat white background
  (not painted scenery) so the follow-up `/bgremove` step segments
  cleanly.
- **Watch for humanoid drift on birds specifically, not just mammals.**
  "battle-ready stance" on the Robin reference produced a muscular
  armored bird-headed *humanoid warrior* -- a completely different
  subject, not a rendering-quality problem like previous humanoid-drift
  incidents. Quadruped guidance ("on all fours") doesn't apply to birds;
  needed explicit `"not a humanoid, not anthropomorphic, no muscular
  human body, no armor, no clothing, no weapons, just a small ordinary
  garden bird"` plus reinforcing `"natural bird anatomy, standing on two
  thin bird legs"` to correct it. That fix alone also lost the pixel-art
  style (came back smooth/vector-like) -- needed a *second* retry adding
  back `"keep the exact same 16-bit pixel art style as the reference
  image, chunky pixels, thick black outline, no anti-aliasing, no smooth
  vector look"` explicitly, since the heavy anti-humanoid intervention
  apparently competed with the reference image's automatic style transfer.
  **Always eyeball img2img results for subject drift, not just style
  drift** -- a strange prompt/reference interaction can change what the
  subject *is*, not just how it's rendered, and that's easy to miss if
  you're only checking "does it look like pixel art."
- **Still run every result through `/bgremove`** even though the prompt
  already asks for a white background -- `/imgedit` output is a flat white
  fill, not real transparency, and `/bgremove` (rembg subprocess) is what
  actually converts it to alpha. Same as before: `POST /bgremove` with the
  image as multipart form data, poll `/status/<job_id>`, read the result
  from `ComfyUI/output/bgremove_<id>.png` (not a subfolder).
- **Verify the result actually has alpha** before trusting it — don't just
  eyeball it, the Read tool's image preview renders transparency as opaque
  (white or black, inconsistently) so a failed removal and a successful
  one can look identical at a glance. Quick check: a PNG info tool
  reporting `RGBA` plus a corner-pixel alpha of 0 confirms it; `file
  <path>.png` reporting `8-bit/color RGBA` is the first signal.
- Any `TextureRect` this art lands in needs `stretch_mode =
  STRETCH_KEEP_ASPECT_CENTERED` (5), not `STRETCH_KEEP_ASPECT_COVERED` (6).
  Covered-mode crops to fill the frame, which is fine for card art already
  composed to fill a portrait frame, but a landscape-composed battle sprite
  in a portrait-shaped tile gets cropped down to an unrecognizable close-up
  fur patch under cover mode. Centered mode letterboxes instead — with a
  transparent background, the letterbox space is invisible.

## Ability card art (batch-generated, one script call per pass)

Ability cards (a creature's Strike/Guard, on-summon abilities, standalone
player abilities) each need their own unique art showing the *action*, not
a reused creature portrait or battle sprite — see `tools/gen_ability_art.py`
(same "build-time tool, not shipped" category as `gen_background.py`) and
the "Unique ability art" section of `docs/gameplay-notes.md` for the full
writeup. Key points for next time:

- **Reuse the source creature's exact subject description from its own
  PNG metadata** (`PIL.Image.open(path).text['prompt']` — the full ComfyUI
  workflow JSON, including the original prompt string, is embedded right
  in the file) rather than re-describing the creature from scratch. Swap
  in an ability-specific action phrase, keep the same faction style suffix.
- Add `"dynamic action pose, motion lines"` to the style suffix for ability
  art specifically — without it, Flux tends to default back toward a calm
  portrait pose even with an action verb in the subject description.
- 512x512 is fine even though the ability card's art band is a short wide
  strip, not square — the `TextureRect` already crop-fills via
  `STRETCH_KEEP_ASPECT_COVERED`, so square source art works the same way
  creature card art already does.
- The Phone App server (`server.py`, port 8080) needs `PYTHONUTF8=1` set
  when launched from a non-UTF8 Windows console — its startup banner
  prints an arrow character that crashes on cp1252 otherwise.
- `art_texture` lives on `CardAbility` itself now (not just
  `BaseCardData`), loaded via `res://assets/<faction>/ability_<slug>_
  <ability_name>.png` by naming convention (slug = card name lowercased
  with underscores) — see `CardDatabase._load_ability_art()`. Safe to
  generate incrementally: missing files just fall back to null, which
  callers already fall back from to the creature's own portrait/sprite.
