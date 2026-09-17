#!/usr/bin/env bash
set -euo pipefail

provider_id="cliproxyapi"
provider_name="CLIProxyAPI"

self="$(readlink -f "${BASH_SOURCE[0]}")"
if [[ -f "${self}.local" ]]; then
  set -a
  source "${self}.local"
  set +a
fi
: "${OPENAI_API_KEY:?set OPENAI_API_KEY in $(basename "${self}").local}"
: "${provider_base_url:?set provider_base_url in $(basename "${self}").local}"

profile_args=()
[[ -n "${CODEX_PROFILE:-}" ]] && profile_args+=(--profile "$CODEX_PROFILE")

provider_override="model_providers.${provider_id}={name=\"${provider_name}\", base_url=\"${provider_base_url}\", env_key=\"OPENAI_API_KEY\", wire_api=\"responses\"}"

set -x
exec codex \
  "${profile_args[@]}" \
  -c "$provider_override" \
  -c "model_provider=${provider_id}" \
  "$@"
