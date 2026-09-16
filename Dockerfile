FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY runtime.zip /tmp/runtime.zip

RUN python - <<'PY'
import pathlib, zipfile
src = pathlib.Path('/tmp/runtime.zip')
with zipfile.ZipFile(src) as zf:
    members = zf.infolist()
    for m in members:
        p = pathlib.PurePosixPath(m.filename)
        if p.is_absolute() or '..' in p.parts:
            raise RuntimeError('unsafe archive path')
    zf.extractall('/app')
PY

RUN pip install --disable-pip-version-check --no-cache-dir -r /app/requirements.txt
RUN mkdir -p /data/uploads /data/logs /data/backups

CMD ["sh", "-lc", "python scripts/migrate.py && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1 --proxy-headers --forwarded-allow-ips='*'"]
