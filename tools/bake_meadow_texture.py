"""Bake the supplied Emerald Meadow GLB to a flat, seamless grass texture.

Run from the project root with Python + numpy + Pillow and a C++17 compiler.
No generated model or large source atlas is needed in the exported game.
"""
import io
import json
from pathlib import Path
import struct
import subprocess
import tempfile

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "assets/grass/source/emerald_meadow.glb").read_bytes()
json_length = struct.unpack_from("<I", source, 12)[0]
gltf = json.loads(source[20:20 + json_length])
binary = memoryview(source)[28 + json_length:]


def view(index):
    spec = gltf["bufferViews"][index]
    start = spec.get("byteOffset", 0)
    return binary[start:start + spec["byteLength"]]


def accessor(index):
    spec = gltf["accessors"][index]
    dtype = {5126: "<f4", 5125: "<u4"}[spec["componentType"]]
    stride = {"SCALAR": 1, "VEC2": 2, "VEC3": 3}[spec["type"]]
    return np.frombuffer(view(spec["bufferView"]), dtype=dtype,
                         count=spec["count"] * stride,
                         offset=spec.get("byteOffset", 0)).reshape(-1, stride)


primitive = gltf["meshes"][0]["primitives"][0]
vertices = np.concatenate([accessor(primitive["attributes"]["POSITION"]),
                           accessor(primitive["attributes"]["TEXCOORD_0"])], axis=1)
indices = accessor(primitive["indices"])
material = gltf["materials"][primitive["material"]]
texture_index = material["pbrMetallicRoughness"]["baseColorTexture"]["index"]
image_index = gltf["textures"][texture_index]["source"]
atlas = Image.open(io.BytesIO(view(gltf["images"][image_index]["bufferView"]))).convert("RGB")
with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    input_path = directory / "input.bin"
    output_path = directory / "output.rgba"
    with input_path.open("wb") as stream:
        stream.write(struct.pack("<4I", len(vertices), indices.size, *atlas.size))
        stream.write(vertices.astype("<f4").tobytes())
        stream.write(indices.astype("<u4").tobytes())
        stream.write(atlas.tobytes())
    executable = directory / "raster"
    subprocess.run(["g++", "-std=c++17", "-O2", str(ROOT / "tools/meadow_raster.cpp"),
                    "-o", str(executable)], check=True)
    subprocess.run([str(executable), str(input_path), str(output_path)], check=True)
    patch = Image.frombytes("RGBA", (512, 512), output_path.read_bytes())
    if patch.getchannel("A").getextrema() != (255, 255):
        raise RuntimeError("The central grass patch has holes; choose a smaller bake extent")
    # Mirror both edges to make a continuous 1024 px tile, without atlas seams.
    patch = patch.convert("RGB")
    result = Image.new("RGB", (1024, 1024))
    result.paste(patch, (0, 0))
    result.paste(patch.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (512, 0))
    result.paste(patch.transpose(Image.Transpose.FLIP_TOP_BOTTOM), (0, 512))
    result.paste(patch.transpose(Image.Transpose.ROTATE_180), (512, 512))
    result.save(ROOT / "assets/grass/emerald_meadow_albedo.png")
    print("Baked Emerald Meadow: 1024 x 1024, seamless flat grass")
