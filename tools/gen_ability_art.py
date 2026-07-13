"""Batch-generates unique ability-card art via the local ComfyUI Phone App
server (txt2img endpoint), reusing each creature's existing card-art prompt
(extracted from its PNG metadata) as a style/subject base, with an
ability-specific action phrase swapped in so e.g. a raccoon's Strike and
Guard cards show it actually attacking/defending instead of both reusing
the same idle card portrait. See docs/art-pipeline.md for the established
16-bit pixel art style and docs/gameplay-notes.md for why this exists
(previously ability cards just reused source.get_battle_texture()).

Not part of the game itself -- a build-time tool, not shipped/imported by
Godot. Safe to delete once this art pass is done.

Usage: python gen_ability_art.py [start_index]
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

APP_URL = "https://127.0.0.1:8080"
import ssl
_CTX = ssl.create_default_context()
_CTX.check_hostname = False
_CTX.verify_mode = ssl.CERT_NONE

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIP_DIR = os.path.join(REPO_ROOT, "art", "wip")
ASSETS_DIR = os.path.join(REPO_ROOT, "game", "assets")
COMFY_OUTPUT = r"C:\ComfyUI_Portable\ComfyUI\output"

CITY_STYLE = ("gritty urban night atmosphere, dark moody color palette, deep shadows, "
              "dynamic action pose, motion lines, retro RPG creature illustration, "
              "chunky pixels, thick black outline, crisp hard edges, no anti-aliasing, "
              "no blur, no text, no watermark, no people, no anthropomorphic humanoid pose, "
              "video game ability card art")
SUBURBS_STYLE = ("sunny suburban daytime atmosphere, warm bright color palette, clear hard "
                  "directional sunlight with defined shadows, naturalistic proportions, not "
                  "chibi, not kawaii, dynamic action pose, motion lines, detailed pixel-dithered "
                  "shading and fur/feather texture, retro RPG creature illustration, chunky "
                  "pixels, thick black outline, crisp hard edges, no anti-aliasing, no blur, "
                  "no soft gradients, no text, no watermark, no people, no anthropomorphic "
                  "humanoid pose, video game ability card art")
PLAYER_STYLE = ("gritty urban night atmosphere, dark moody color palette, deep shadows, "
                 "dynamic action pose, motion lines, retro RPG illustration, chunky pixels, "
                 "thick black outline, crisp hard edges, no anti-aliasing, no blur, no text, "
                 "no watermark, video game ability card art")

# Each entry: (output_path relative to game/assets, subject+action prompt, style)
ENTRIES = [
    # ---- City Faction: Strike / Guard per creature ----
    ("city_faction/ability_alley_kitten_strike.png",
     "16-bit pixel art of a scruffy black alley kitten lunging forward mid-pounce, claws "
     "extended and swiping, mouth open hissing, on a cracked sidewalk", CITY_STYLE),
    ("city_faction/ability_alley_kitten_guard.png",
     "16-bit pixel art of a scruffy black alley kitten crouched low and defensive, back "
     "arched, fur bristled, ears pinned back, on a cracked sidewalk", CITY_STYLE),

    ("city_faction/ability_cutpurse_cat_strike.png",
     "16-bit pixel art of a young lean black cat wearing a loose bandana mask, lunging "
     "forward slashing with a small shiv, on a rusty fire escape at night", CITY_STYLE),
    ("city_faction/ability_cutpurse_cat_guard.png",
     "16-bit pixel art of a young lean black cat wearing a loose bandana mask, crouched "
     "defensively behind a raised forearm, wary narrowed eyes, on a rusty fire escape at night",
     CITY_STYLE),

    ("city_faction/ability_backalley_blade_strike.png",
     "16-bit pixel art of a lean black cat wearing a tattered hood and domino mask, lunging "
     "forward slashing with a small shiv, neon sign glow in the distance", CITY_STYLE),
    ("city_faction/ability_backalley_blade_guard.png",
     "16-bit pixel art of a lean black cat wearing a tattered hood and domino mask, crouched "
     "in a defensive knife-fighter stance, blade held guarding, neon sign glow in the distance",
     CITY_STYLE),

    ("city_faction/ability_junkyard_scrapper_strike.png",
     "16-bit pixel art of a young black cat wearing a plain basic collar, one front paw "
     "bandaged, lunging forward with a heavy bandaged-paw haymaker swing", CITY_STYLE),
    ("city_faction/ability_junkyard_scrapper_guard.png",
     "16-bit pixel art of a young black cat wearing a plain basic collar, one front paw "
     "bandaged, crouched with both paws raised in a boxer's guard", CITY_STYLE),

    ("city_faction/ability_alley_boss_strike.png",
     "16-bit pixel art of a scarred black tomcat wearing a spiked leather collar, muscular "
     "haunches, lunging forward with a powerful bandaged-paw haymaker swing", CITY_STYLE),
    ("city_faction/ability_alley_boss_guard.png",
     "16-bit pixel art of a scarred black tomcat wearing a spiked leather collar, muscular "
     "haunches, braced low in a heavyweight boxer's guard stance", CITY_STYLE),

    ("city_faction/ability_raccoon_strike.png",
     "16-bit pixel art of a scruffy raccoon lunging forward on all fours, claws swiped out, "
     "bushy ringed tail flared, snarling", CITY_STYLE),
    ("city_faction/ability_raccoon_guard.png",
     "16-bit pixel art of a scruffy raccoon hunched low and defensive, bushy ringed tail "
     "puffed out, back arched, masked eyes narrowed warily", CITY_STYLE),

    ("city_faction/ability_crow_strike.png",
     "16-bit pixel art of a sleek black crow diving down in an attack, wings swept back, "
     "sharp beak striking forward, talons extended, city rooftops below", CITY_STYLE),
    ("city_faction/ability_crow_guard.png",
     "16-bit pixel art of a sleek black crow with wings flared wide and puffed up "
     "defensively, feathers bristled, perched braced on a rooftop antenna", CITY_STYLE),

    ("city_faction/ability_stray_dog_strike.png",
     "16-bit pixel art of a lean scruffy stray mutt lunging forward mid-lunge, teeth bared "
     "snarling, in a narrow alley", CITY_STYLE),
    ("city_faction/ability_stray_dog_guard.png",
     "16-bit pixel art of a lean scruffy stray mutt crouched low defensively, hackles raised "
     "along its back, ears pinned, in a narrow alley", CITY_STYLE),

    ("city_faction/ability_pigeon_strike.png",
     "16-bit pixel art of a scruffy gray city pigeon diving forward wings swept back, pecking "
     "beak strike, rooftop ledge overlooking the city skyline at night", CITY_STYLE),
    ("city_faction/ability_pigeon_guard.png",
     "16-bit pixel art of a scruffy gray city pigeon with wings puffed out defensively, "
     "feathers bristled wide, rooftop ledge overlooking the city skyline at night", CITY_STYLE),

    ("city_faction/ability_opossum_strike.png",
     "16-bit pixel art of a pale grey opossum lunging forward mouth wide open baring many "
     "sharp teeth in a hiss-attack, in a damp sewer tunnel", CITY_STYLE),
    ("city_faction/ability_opossum_guard.png",
     "16-bit pixel art of a pale grey opossum playing dead defensively, fallen on its side, "
     "tongue out, tail curled, in a damp sewer tunnel", CITY_STYLE),

    ("city_faction/ability_cockroach_strike.png",
     "16-bit pixel art of a large glossy sewer cockroach scuttling forward fast in an attack "
     "rush, antennae and legs blurred with motion, on a cracked wet concrete floor", CITY_STYLE),
    ("city_faction/ability_cockroach_guard.png",
     "16-bit pixel art of a large glossy sewer cockroach hunched low with its hard shell "
     "raised defensively, antennae drawn back, on a cracked wet concrete floor", CITY_STYLE),

    ("city_faction/ability_sewer_rat_strike.png",
     "16-bit pixel art of a large mutated sewer rat lunging forward baring sharp teeth, "
     "toxic-green eyes glowing bright, wading through shallow sewer water", CITY_STYLE),
    ("city_faction/ability_sewer_rat_guard.png",
     "16-bit pixel art of a large mutated sewer rat hunched defensively, matted fur bristled "
     "up, toxic-green eyes narrowed, wading through shallow sewer water", CITY_STYLE),

    ("city_faction/ability_sewer_alligator_strike.png",
     "16-bit pixel art of a massive sewer alligator lunging forward jaws wide open baring "
     "rows of sharp teeth, glowing yellow eyes, bursting from murky water", CITY_STYLE),
    ("city_faction/ability_sewer_alligator_guard.png",
     "16-bit pixel art of a massive sewer alligator sinking low into murky water defensively, "
     "only glowing yellow eyes and armored back ridges visible above the surface", CITY_STYLE),

    ("city_faction/ability_bat_strike.png",
     "16-bit pixel art of a small black bat diving down in an attack dive, wings swept back, "
     "fangs bared, silhouetted against a crescent moon above rooftops", CITY_STYLE),
    ("city_faction/ability_bat_guard.png",
     "16-bit pixel art of a small black bat with wings wrapped around itself defensively "
     "like a cloak, hanging upside down, silhouetted against a crescent moon", CITY_STYLE),

    # ---- Suburbs Faction: single Strike per creature (simple_abilities) ----
    ("suburbs/ability_house_cat_strike.png",
     "16-bit pixel art of a fluffy well-groomed house cat lunging forward mid-pounce, paw "
     "swiping playfully but sharp-clawed, on a sunny porch step", SUBURBS_STYLE),
    ("suburbs/ability_watchcat_strike.png",
     "16-bit pixel art of a confident house cat wearing a small red bandana, lunging forward "
     "paw swiping, chest puffed, atop a white picket fence post", SUBURBS_STYLE),
    ("suburbs/ability_family_dog_strike.png",
     "16-bit pixel art of a golden retriever lunging forward in a playful tackle, tongue out, "
     "front paws leading, on a sunny lawn", SUBURBS_STYLE),
    ("suburbs/ability_squirrel_strike.png",
     "16-bit pixel art of a bushy-tailed squirrel leaping forward mid-pounce, tiny paws "
     "outstretched, tail flared, on a backyard tree branch", SUBURBS_STYLE),
    ("suburbs/ability_rabbit_strike.png",
     "16-bit pixel art of a small brown rabbit lunging forward with a quick kicking hop "
     "attack, back legs powering off the ground, in a backyard vegetable garden", SUBURBS_STYLE),
    ("suburbs/ability_robin_strike.png",
     "16-bit pixel art of a robin diving forward wings swept back, beak pecking strike, red "
     "breast puffed, near a white picket fence", SUBURBS_STYLE),
    ("suburbs/ability_hamster_strike.png",
     "16-bit pixel art of a hamster lunging forward with cheek pouches full, tiny paws "
     "swiping, inside a cozy cage", SUBURBS_STYLE),

    # ---- Suburbs on-summon abilities ----
    ("suburbs/ability_house_cat_nuzzle.png",
     "16-bit pixel art of a fluffy well-groomed house cat nuzzling affectionately with eyes "
     "closed, warm gentle expression, on a sunny porch step", SUBURBS_STYLE),
    ("suburbs/ability_family_dog_warning_bite.png",
     "16-bit pixel art of a golden retriever with a sudden warning snap, teeth bared for just "
     "a moment, protective stance, on a sunny lawn", SUBURBS_STYLE),

    # ---- Standalone player ability cards ----
    ("player/ability_rock_throw.png",
     "16-bit pixel art of a determined young man's arm winding up to throw a fist-sized rock, "
     "close-up dynamic action shot, alley setting", PLAYER_STYLE),
    ("player/ability_brace.png",
     "16-bit pixel art of a determined young man braced defensively with both forearms raised "
     "to block, close-up dynamic action shot, alley setting", PLAYER_STYLE),
]


def build_workflow(prompt: str, width: int, height: int, seed: int) -> dict:
    return {
        "prompt": prompt, "seed": seed, "steps": 4,
        "width": width, "height": height, "model_id": "flux2_klein",
    }


def submit(prompt: str, seed: int) -> str:
    body = json.dumps(build_workflow(prompt, 512, 512, seed)).encode("utf-8")
    req = urllib.request.Request(f"{APP_URL}/txt2img", data=body,
                                  headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, context=_CTX, timeout=30) as resp:
        return json.load(resp)["job_id"]


def wait_for_result(job_id: str, timeout: float = 120.0) -> str:
    start = time.time()
    while time.time() - start < timeout:
        req = urllib.request.Request(f"{APP_URL}/status/{job_id}")
        with urllib.request.urlopen(req, context=_CTX, timeout=30) as resp:
            status = json.load(resp)
        if status.get("status") == "done":
            return status["filename"]
        if status.get("status") == "error":
            raise RuntimeError(f"job {job_id} failed: {status}")
        time.sleep(1.5)
    raise TimeoutError(f"job {job_id} did not finish in {timeout}s")


def main() -> None:
    start_index = int(sys.argv[1]) if len(sys.argv) > 1 else 0
    for i, (rel_path, subject, style) in enumerate(ENTRIES):
        if i < start_index:
            continue
        prompt = f"{subject}, {style}"
        wip_path = os.path.join(WIP_DIR, rel_path)
        assets_path = os.path.join(ASSETS_DIR, rel_path)
        os.makedirs(os.path.dirname(wip_path), exist_ok=True)
        os.makedirs(os.path.dirname(assets_path), exist_ok=True)

        print(f"[{i+1}/{len(ENTRIES)}] {rel_path} ...", flush=True)
        try:
            job_id = submit(prompt, seed=1000 + i)
            filename = wait_for_result(job_id)
            src = os.path.join(COMFY_OUTPUT, filename)
            with open(src, "rb") as f:
                data = f.read()
            with open(wip_path, "wb") as f:
                f.write(data)
            with open(assets_path, "wb") as f:
                f.write(data)
            print(f"    saved ({len(data)} bytes) -> {rel_path}", flush=True)
        except Exception as e:
            print(f"    FAILED: {e}", flush=True)


if __name__ == "__main__":
    main()
