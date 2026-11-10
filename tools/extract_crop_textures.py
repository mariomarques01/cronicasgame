"""Extract the supplied crop textures at mobile resolutions. Requires Pillow."""
import io
import json
from pathlib import Path
import struct

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
for crop in ("cabbage", "carrots"):
    source = (ROOT / f"assets/crops/source/{crop}.glb").read_bytes()
    length = struct.unpack_from("<I", source, 12)[0]
    gltf = json.loads(source[20:20 + length])
    material = gltf["materials"][0]
    pbr = material["pbrMetallicRoughness"]
    for kind, spec, size in (("albedo", pbr["baseColorTexture"], 1024),
                             ("roughness_metallic", pbr["metallicRoughnessTexture"], 512),
                             ("normal", material["normalTexture"], 512)):
        image = gltf["images"][gltf["textures"][spec["index"]]["source"]]
        view = gltf["bufferViews"][image["bufferView"]]
        start = length + 28 + view.get("byteOffset", 0)
        texture = Image.open(io.BytesIO(source[start:start + view["byteLength"]])).convert("RGB")
        texture.thumbnail((size, size), Image.Resampling.LANCZOS)
        texture.save(ROOT / f"assets/crops/textures/{crop}_{kind}.png")
