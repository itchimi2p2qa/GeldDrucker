#!/usr/bin/env bash
set -euo pipefail

# Create config.json from example if not already present
if [ ! -f /app/config.json ]; then
  cp /app/config.example.json /app/config.json
  echo "[start] Created config.json from config.example.json"
fi

# Map Render environment variables into config.json
python3 -c "
import json, os

with open('/app/config.json', 'r') as f:
    cfg = json.load(f)

# Environment variable -> config.json key mapping
# Tuple values like ('email', 'smtp_server') target nested keys
env_map = {
    'OLLAMA_BASE_URL':    'ollama_base_url',
    'OLLAMA_MODEL':       'ollama_model',
    'GEMINI_API_KEY':     'nanobanana2_api_key',
    'ASSEMBLYAI_API_KEY': 'assembly_ai_api_key',
    'SMTP_SERVER':        ('email', 'smtp_server'),
    'SMTP_PORT':          ('email', 'smtp_port'),
    'SMTP_USERNAME':      ('email', 'username'),
    'SMTP_PASSWORD':      ('email', 'password'),
    'FIREFOX_PROFILE':    'firefox_profile',
    'TTS_VOICE':          'tts_voice',
    'TWITTER_LANGUAGE':   'twitter_language',
}

for env_key, cfg_key in env_map.items():
    val = os.environ.get(env_key)
    if val is not None:
        if isinstance(cfg_key, tuple):
            parent, child = cfg_key
            cfg.setdefault(parent, {})[child] = val
        else:
            # Convert boolean strings
            if val.lower() in ('true', 'false'):
                val = val.lower() == 'true'
            else:
                try:
                    val = int(val)
                except (ValueError, TypeError):
                    pass
            cfg[cfg_key] = val

# Force headless mode (Render has no display)
cfg['headless'] = True

# Set ImageMagick path for Linux container
if not cfg.get('imagemagick_path') or cfg['imagemagick_path'].endswith('.exe'):
    cfg['imagemagick_path'] = '/usr/bin/convert'

with open('/app/config.json', 'w') as f:
    json.dump(cfg, f, indent=2)

print('[start] Config applied successfully.')
"

echo "[start] Running: $*"
exec "$@"
