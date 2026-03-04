FROM python:3.12-slim

# System dependencies: browser, image/video processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    firefox-esr \
    imagemagick \
    ffmpeg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Allow MoviePy to invoke ImageMagick convert
RUN sed -i 's/rights="none" pattern="@\*"/rights="read|write" pattern="@*"/' \
    /etc/ImageMagick-6/policy.xml 2>/dev/null || true

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Baked-in Firefox profile — uncomment after copying your profile into
# the repo as ./firefox-profile/ (see deployment instructions)
# COPY firefox-profile /app/firefox-profile

# Create .mp state directory (overridden by Render Disk mount in production)
RUN mkdir -p .mp

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]
CMD ["python", "src/cron.py"]
