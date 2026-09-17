# codex CLIProxyAPI Launcher

Wrapper that starts Codex CLI against a CLIProxyAPI provider while keeping API keys and private URLs out of the repository.

## Two Ways to Run Codex

Codex can use a ChatGPT OAuth account, one or more API providers, or both at the same time.

### ChatGPT OAuth account

Use the normal Codex CLI login flow — no script needed:

```bash
codex login     # browser OAuth flow
codex logout    # remove stored credentials
```

For multiple OAuth accounts, log out and log back in manually, or use an account switcher such as `codex-auth`.

### API providers

Use a launcher script like `codex-cliproxyapi.sh` for CLIProxyAPI, cli2proxy, sub2api and similar services. The provider is injected per invocation (`-c model_provider=...`), so your OAuth login is never touched.

For multiple API accounts or providers, create one script plus one `.local` file per account:

```
codex-cliproxyapi.sh  +  codex-cliproxyapi.sh.local
codex-cli2proxy.sh    +  codex-cli2proxy.sh.local
codex-sub2api.sh      +  codex-sub2api.sh.local
```

### Using both at the same time

```bash
codex                                      # logged-in ChatGPT OAuth account
./codex-cliproxyapi.sh                     # CLIProxyAPI account
CODEX_PROFILE=fast ./codex-cliproxyapi.sh  # same API account, different profile
```

## Files

| File | Committed | Purpose |
|---|---|---|
| `codex-cliproxyapi.sh` | yes | launcher: sources local values, builds the provider override, execs `codex` |
| `codex-cliproxyapi.sh.local.example` | yes | template for machine-local values |
| `codex-cliproxyapi.sh.local` | no (git-ignored) | your API key, proxy URL, default profile |
| `.gitignore` | yes | ignores `*.local` and `*.shbackup` |

## Setup

```bash
cp codex-cliproxyapi.sh.local.example codex-cliproxyapi.sh.local
chmod 600 codex-cliproxyapi.sh.local
$EDITOR codex-cliproxyapi.sh.local
```

Fill in `codex-cliproxyapi.sh.local`:

```bash
: "${CODEX_PROFILE:=your-profile}"
export provider_base_url="https://your-proxy.example.com/v1"
export OPENAI_API_KEY="sk-..."
```

- `provider_base_url` and `OPENAI_API_KEY` are required.
- `CODEX_PROFILE` is optional. It sets a machine default profile; a runtime override wins:

```bash
CODEX_PROFILE=fast ./codex-cliproxyapi.sh
```

If `CODEX_PROFILE` is unset everywhere, no `--profile` flag is passed and Codex uses its default profile.

## Usage

```bash
./codex-cliproxyapi.sh [codex-args...]
bash /path/to/codex-cliproxyapi.sh [codex-args...]   # works from any directory
```

The `.local` file is always resolved next to the real script (via `readlink -f "${BASH_SOURCE[0]}"`), so the current working directory does not matter.

## How It Works

1. Resolves its own absolute path.
2. Sources `<script>.local` with `set -a` (all assignments are exported).
3. Fails fast with a clear message if `OPENAI_API_KEY` or `provider_base_url` is missing.
4. Builds `model_providers.cliproxyapi={name=..., base_url=..., env_key="OPENAI_API_KEY", wire_api="responses"}` and execs `codex -c ...`.

## Security

- Never commit `.local` files; `*.local` is git-ignored.
- `*.shbackup` is ignored as well: backups of old scripts may still contain secrets.
- If a key ever reaches a remote, rotate it immediately. Deleting the file later does not remove it from git history; use `git filter-repo` or BFG.
- Check before pushing:

```bash
git diff --cached | grep -iE 'sk-|api[_-]?key|password|token'
```

## Adding Another Provider

Copy the script, change `provider_id`, `provider_name`, and add a matching `.local` file for its URL/key/proxy. One script plus one `.local` per account keeps providers isolated even though all of them use the `OPENAI_API_KEY` variable name. Typical targets: CLIProxyAPI, cli2proxy, sub2api.

## Requirements

- bash >= 4.4
- `codex` on `PATH`
- GNU `readlink` (Linux). On macOS use `realpath` or `greadlink` instead.
