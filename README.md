# msgme

A macOS CLI wrapper that runs any command and sends you an AI-summarized notification when it finishes — via iMessage, email, speech, or any combination.

Supports multiple AI providers — local models via [Ollama](https://ollama.com), or cloud providers via their CLI tools.

## Why?

Long-running builds, deploys, and test suites don't need you watching the terminal. Wrap your command with `msgme` and get a text when it's done.

## Features

- **iMessage notifications** — text with an AI-generated summary (Apple devices only)
- **Email notifications** — cross-platform delivery via any SMTP provider
- **Speech announcements** — hear the result spoken aloud via macOS `say`
- **Multi-provider AI** — Ollama (local), Claude, Codex (OpenAI), and Gemini
- **Multiple recipients** — space-separated lists in config, additive (`-n`) or replace (`-nr`) from CLI
- **Flexible channel control** — pick any combination per invocation; set defaults in config
- **Background by default** — notifications fire in the background so you get your shell back instantly
- **Debug mode** — run in foreground with pretty-printed JSON to see the full AI request/response

## Requirements

- macOS (iMessage + `say` are macOS-only; email works anywhere)
- Python 3 (pre-installed on macOS)
- zsh (default macOS shell)
- At least one AI provider (see below)
- For email: a [Brevo](https://www.brevo.com) account (free tier available) with API key

## Install

```bash
# Clone and copy to your PATH
git clone https://github.com/NetverseSocial/msgme.git
cp msgme/main/msgme /usr/local/bin/msgme
chmod +x /usr/local/bin/msgme
```

## AI Providers

The `--ai` (or `-a`) flag auto-detects the provider from the model name. If omitted, the `AI_MODEL` from your config is used.

| Provider | Example | Requires | Install |
|----------|---------|----------|---------|
| **Ollama** | `--ai gemma3:1b` | [Ollama](https://ollama.com) running locally | `brew install ollama` |
| **Claude** | `--ai claude-haiku-4-5` | [Claude Code](https://claude.ai/code) CLI, logged in | `npm i -g @anthropic-ai/claude-code` |
| **Codex** | `--ai gpt-5.1-codex-mini` | [Codex CLI](https://github.com/openai/codex), logged in | `npm i -g @openai/codex` |
| **Gemini** | `--ai gemini` | [Gemini CLI](https://github.com/google-gemini/gemini-cli), logged in | `npm i -g @google/gemini-cli` |

Cloud providers use their respective CLI tools, which authenticate through your existing subscription account — **no API keys required**. Ollama runs entirely locally.

> **Tip:** For Ollama, a tiny model like `gemma3:1b` (815MB) works great for notification summaries — responds in under a second. No need for large models.

## Configuration

Create `~/.msgme.conf` with your defaults:

```bash
# Multiple recipients: space-separated
PHONE="+15551234567 +15559876543"
EMAIL="user@example.com ops@example.com"

AI_HOST="localhost:11434"
AI_MODEL="gemma3:1b"
AIP="keep it brief and professional"
VERBOSITY=3

# Which channels fire when no flags are given
# Any combination of: IMESSAGE EMAIL SPEECH
DEFAULT="IMESSAGE EMAIL"
```

All settings can be overridden via command-line flags.

### Email Setup

Email works with **any SMTP provider** — Gmail, Outlook, Yahoo, Brevo, etc. Set these environment variables:

```bash
# Generic SMTP (works with any provider)
export SMTP_HOST="smtp.gmail.com"    # or smtp.mail.yahoo.com, smtp-relay.brevo.com, etc.
export SMTP_PORT="587"
export SMTP_USER="you@gmail.com"
export SMTP_PASS="your-app-password"

# Customize sender (optional)
export EMAIL_FROM="notifications@yourdomain.com"
export EMAIL_FROM_NAME="My Build Server"
```

> **Gmail users:** Use an [App Password](https://myaccount.google.com/apppasswords), not your regular password.

If you have a [Brevo](https://www.brevo.com) account, you can alternatively set `BREVO_SMTP_API_KEY` to use their REST API (takes priority over SMTP when set).

### Notification Channels

Channels are selected per invocation. If no channel flags are given, `DEFAULT` from config determines what fires.

| Flag | Action | Example |
|------|--------|---------|
| `-n` | **Add** iMessage recipients | `-n +15551234567 +15559876543` |
| `-nr` | **Replace** config phones | `-nr +15559999999` |
| `-e` | **Add** email recipients | `-e a@b.com c@d.com` |
| `-er` | **Replace** config emails | `-er solo@b.com` |
| `-s` | **Enable** speech | `-s "custom text"` |
| `-aip` | **Add** to default AI instructions | `-aip "respond in Spanish"` |
| `-aipr` | **Replace** default AI instructions | `-aipr "one word only"` |

- **Add** flags append to config values (e.g., `-n +15559999999` sends to config phones AND +15559999999)
- **Replace** flags discard config values and use only what's on the command line
- Flags accept multiple space-separated values — everything until the next `-` flag or `--`
- Each channel is independent — using `-n` doesn't affect email or speech defaults
- All flags accept any length: `-e`, `-em`, `-email` all work the same
- iMessage requires Apple devices; for Android/Google Voice users, use email instead

## Usage

```
Usage: msgme [options] -- command [args]

Channels:
  -n  <numbers...>    Add iMessage recipients
  -nr <numbers...>    Replace config phone list
  -e  <addrs...>      Add email recipients
  -er <addrs...>      Replace config email list
  -s  [text]          Enable speech (optional custom text)

AI:
  -a  <model>         AI provider/model (auto-detected from name)
  -aip <prompt>       Add to config AI instructions (AIP in .conf)
  -aipr <prompt>      Replace config AI instructions for this run

Options:
  -m <text>           Static text message (skip AI)
  -v <1-3>            Verbosity (1: Brief, 2: Normal, 3: Chatty)
  -d                  Debug mode (foreground, shows JSON traffic)
  -h                  Show this help

All flags accept any length: -e, -em, -email all work.
```

## Examples

```bash
# Uses DEFAULT channels + AI_MODEL + AIP from config
msgme -- make build

# Override AI provider for this run
msgme -a gemma3:1b -- make build             # Ollama (local, fast, tiny)
msgme -a claude-haiku-4-5 -- make build      # Claude
msgme -a gpt-5.1-codex-mini -- make build    # Codex (OpenAI)
msgme -a gemini -- make build                # Gemini

# Add recipients on top of config defaults
msgme -n +15559999999 -- make build          # config phones + this one
msgme -email extra@team.com -- ./deploy.sh   # config emails + this one (-e works too)
msgme -n +15551111111 +15552222222 -e a@b.com -s -- make build

# Replace config recipients for this run only
msgme -nr +15559999999 -- make build         # only this phone, not config
msgme -er solo@team.com -- ./deploy.sh       # only this email, not config

# AI instructions (adds to AIP from config)
msgme -aip "focus on errors and warnings" -- npm test
msgme -aip "respond in Spanish" -- ./deploy.sh
msgme -aipr "one word summary only" -- cmd   # replaces config AIP entirely

# Static message (skip AI entirely)
msgme -m "Deploy done" -- ./deploy.sh

# Debug mode — see full AI request/response JSON
msgme -d -- echo "hello world"
```

## How It Works

1. Runs your command, capturing output via `tee`
2. Sends the last 100 lines + exit code to your chosen AI provider for summarization
3. Delivers the AI-generated summary via iMessage, email, and/or speech
4. Without `-d`, notifications happen in the background — your shell returns immediately

## License

MIT
