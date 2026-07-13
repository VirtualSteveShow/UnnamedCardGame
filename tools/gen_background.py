"""One-off helper for generating background art via the local ComfyUI
server, reusing the exact Flux 2 Klein workflow already embedded in the
existing Suburbs creature art (extracted from house_cat_base.png's PNG
metadata) so new backgrounds match the established pixel-art style.
Not part of the game itself -- a build-time tool, not shipped/imported
by Godot. Safe to delete once this art pass is done.

Usage: python gen_background.py <prompt> <output_path> [width] [height] [seed]
"""
import json
import sys
import time
import urllib.request

COMFY_URL = "http://127.0.0.1:8188"


def build_workflow(prompt: str, width: int, height: int, seed: int, filename_prefix: str) -> dict:
    return {
        "1": {"class_type": "VAELoader", "inputs": {"vae_name": "flux2-vae.safetensors"}},
        "2": {"class_type": "UnetLoaderGGUF", "inputs": {"unet_name": "flux-2-klein-9b-Q5_K_M.gguf"}},
        "3": {"class_type": "CLIPLoader", "inputs": {"clip_name": "qwen_3_8b_fp4mixed.safetensors", "type": "flux2", "device": "default"}},
        "4": {"class_type": "CLIPTextEncode", "inputs": {"clip": ["3", 0], "text": prompt}},
        "5": {"class_type": "ConditioningZeroOut", "inputs": {"conditioning": ["4", 0]}},
        "6": {"class_type": "CFGGuider", "inputs": {"model": ["2", 0], "positive": ["4", 0], "negative": ["5", 0], "cfg": 1.0}},
        "7": {"class_type": "RandomNoise", "inputs": {"noise_seed": seed}},
        "8": {"class_type": "KSamplerSelect", "inputs": {"sampler_name": "euler_ancestral"}},
        "9": {"class_type": "Flux2Scheduler", "inputs": {"steps": 4, "width": width, "height": height}},
        "10": {"class_type": "EmptyFlux2LatentImage", "inputs": {"width": width, "height": height, "batch_size": 1}},
        "11": {"class_type": "SamplerCustomAdvanced", "inputs": {"noise": ["7", 0], "guider": ["6", 0], "sampler": ["8", 0], "sigmas": ["9", 0], "latent_image": ["10", 0]}},
        "12": {"class_type": "VAEDecode", "inputs": {"samples": ["11", 0], "vae": ["1", 0]}},
        "13": {"class_type": "SaveImage", "inputs": {"images": ["12", 0], "filename_prefix": filename_prefix}},
    }


def submit(workflow: dict) -> str:
    body = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(f"{COMFY_URL}/prompt", data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as resp:
        return json.load(resp)["prompt_id"]


def wait_for_result(prompt_id: str, timeout: float = 120.0) -> dict:
    start = time.time()
    while time.time() - start < timeout:
        with urllib.request.urlopen(f"{COMFY_URL}/history/{prompt_id}") as resp:
            history = json.load(resp)
        if prompt_id in history:
            return history[prompt_id]
        time.sleep(1.0)
    raise TimeoutError(f"ComfyUI did not finish prompt {prompt_id} in {timeout}s")


def fetch_image(filename: str, subfolder: str, folder_type: str) -> bytes:
    from urllib.parse import urlencode
    query = urlencode({"filename": filename, "subfolder": subfolder, "type": folder_type})
    with urllib.request.urlopen(f"{COMFY_URL}/view?{query}") as resp:
        return resp.read()


def main() -> None:
    prompt, output_path = sys.argv[1], sys.argv[2]
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
    height = int(sys.argv[4]) if len(sys.argv) > 4 else 576
    seed = int(sys.argv[5]) if len(sys.argv) > 5 else 42

    filename_prefix = "BackgroundGen/tmp"
    workflow = build_workflow(prompt, width, height, seed, filename_prefix)
    prompt_id = submit(workflow)
    print(f"Submitted {prompt_id}, waiting...")
    result = wait_for_result(prompt_id)

    outputs = result["outputs"]
    image_info = None
    for node_output in outputs.values():
        if "images" in node_output:
            image_info = node_output["images"][0]
            break
    if image_info is None:
        raise RuntimeError(f"No image output found: {json.dumps(result)[:500]}")

    data = fetch_image(image_info["filename"], image_info["subfolder"], image_info["type"])
    with open(output_path, "wb") as f:
        f.write(data)
    print(f"Saved {output_path} ({len(data)} bytes)")


if __name__ == "__main__":
    main()
