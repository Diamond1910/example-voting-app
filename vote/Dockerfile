
# 1. Pin explicit, minimal base image
FROM python:3.11-slim@sha256:6e01a61327170889c25f4486d38e93240e1d13db1b01ba90d1f7365c404dfba3

WORKDIR /app

# 2. Layer caching for dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

# 3. Create and enforce a non-root system user
RUN useradd -u 10001 -m appuser && chown -R appuser:appuser /app
USER 10001

EXPOSE 80

CMD ["gunicorn", "app:app", "-b", "0.0.0.0:80", "--log-file", "-"]
