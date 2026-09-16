FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app
COPY runtime.zip /tmp/runtime.zip

RUN python -c "import zipfile,pathlib; z=zipfile.ZipFile('/tmp/runtime.zip'); ms=z.infolist(); assert all((not pathlib.PurePosixPath(m.filename).is_absolute()) and ('..' not in pathlib.PurePosixPath(m.filename).parts) for m in ms); z.extractall('/app')"
RUN pip install --disable-pip-version-check --no-cache-dir -r /app/requirements.txt
RUN mkdir -p /data/uploads /data/logs /data/backups

CMD ["sh", "-lc", "python scripts/migrate.py && exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --workers 1 --proxy-headers --forwarded-allow-ips='*'"]
