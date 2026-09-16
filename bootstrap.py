import os
import pathlib
import shutil
import subprocess
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent
ARCHIVE = ROOT / "runtime.zip"
TARGET = ROOT / "runtime"

if TARGET.exists():
    shutil.rmtree(TARGET)
TARGET.mkdir(parents=True, exist_ok=True)

with zipfile.ZipFile(ARCHIVE) as zf:
    for item in zf.infolist():
        path = pathlib.PurePosixPath(item.filename)
        if path.is_absolute() or ".." in path.parts:
            raise RuntimeError("unsafe runtime archive")
    zf.extractall(TARGET)

subprocess.check_call([sys.executable, "scripts/migrate.py"], cwd=TARGET)
os.chdir(TARGET)
port = os.environ.get("PORT", "8000")
os.execv(sys.executable, [
    sys.executable, "-m", "uvicorn", "app.main:app",
    "--host", "0.0.0.0", "--port", port,
    "--workers", "1", "--proxy-headers", "--forwarded-allow-ips=*",
])
