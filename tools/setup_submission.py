from pathlib import Path
import hashlib, io, json, urllib.request, zipfile

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / "assets/calligraphy/liang-peisheng-xiaocuan-jian.ttf"
EXPECTED = "6a8f3a0e4142afbd4729a0825875d833e28def3ffd51f95a0cd379a2ffaf511b"

def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def restore_parts():
    manifest = ROOT / ".source-parts/manifest.json"
    if not manifest.exists():
        return
    for entry in json.loads(manifest.read_text(encoding="utf-8")):
        target = ROOT / entry["path"]
        assert target.resolve().is_relative_to(ROOT.resolve())
        if target.exists() and digest(target) == entry["sha256"]:
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_suffix(target.suffix + ".rebuilding")
        with temporary.open("wb") as out:
            for part in entry["parts"]:
                source = ROOT / part["path"]
                assert source.resolve().is_relative_to(ROOT.resolve())
                assert digest(source) == part["sha256"], source
                with source.open("rb") as incoming:
                    while chunk := incoming.read(1024 * 1024):
                        out.write(chunk)
        assert digest(temporary) == entry["sha256"], target
        temporary.replace(target)
        print("Restored", entry["path"])

def prepare_font():
    if FONT.exists() and digest(FONT) == EXPECTED:
        print("Original font checksum OK")
        return
    print("Downloading font from its original publisher; see assets/calligraphy/SOURCE.md")
    request = urllib.request.Request("https://www.zjw.cn/html/ziti/jian.zip", headers={"User-Agent": "CuanJingSourceSetup/0.2.1"})
    with urllib.request.urlopen(request, timeout=90) as response:
        data = response.read(64 * 1024 * 1024 + 1)
    if len(data) > 64 * 1024 * 1024:
        raise RuntimeError("Unexpectedly large publisher download")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for entry in archive.infolist():
            if entry.filename.lower().endswith(".ttf") and entry.file_size < 32 * 1024 * 1024:
                raw = archive.read(entry)
                if hashlib.sha256(raw).hexdigest() == EXPECTED:
                    FONT.parent.mkdir(parents=True, exist_ok=True)
                    FONT.write_bytes(raw)
                    print("Original font checksum OK")
                    return
    raise RuntimeError("Publisher download changed: expected font was not found; obtain it from https://www.zjw.cn/html/ziti/index.html and check the documented SHA-256")

if __name__ == "__main__":
    restore_parts()
    prepare_font()
    print("Open project.godot with Godot 4.7.2")
