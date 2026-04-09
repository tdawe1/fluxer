#!/usr/bin/env sh
set -eu

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst not found. Install gettext-base first." >&2
  exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)

mkdir -p "$root_dir/config"

set -a
. "$root_dir/.env"
set +a

envsubst < "$root_dir/config/config.json.template" > "$root_dir/config/config.json"
envsubst < "$root_dir/config/livekit.yaml.template" > "$root_dir/config/livekit.yaml"

chmod 600 "$root_dir/config/config.json" "$root_dir/config/livekit.yaml"
echo "Rendered config/config.json and config/livekit.yaml"
