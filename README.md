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

The `--ai` flag auto-detects the provider from the model name:

| Provider | Example | Requires | Install |
|----------|---------|----------|---------|
| **Ollama** | `--ai gemma3:27b` | [Ollama](https://ollama.com) running locally | `brew install ollama` |
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
| `-n` | **Add** iMessage recipients | `-n +1555 +1666` |
| `-nr` | **Replace** config phones | `-nr +1999` |
| `--email` / `-e` | **Add** email recipients | `--email a@b.com c@d.com` |
| `--emailr` / `-er` | **Replace** config emails | `-er solo@b.com` |
| `-s` | **Enable** speech | `-s "custom text"` |

- **Add** flags append to config values (e.g., `-n +1555` sends to config phones AND +1555)
- **Replace** flags discard config values and use only what's on the command line
- Flags accept multiple space-separated values — everything until the next `-` flag or `--`
- Each channel is independent — using `-n` doesn't affect email or speech defaults
- iMessage requires Apple devices; for Android/Google Voice users, use email instead

## Usage

```
Usage: msgme [options] -- command [args]

Channels:
  -n  <numbers...>       Add iMessage recipients (space-separated)
  -nr <numbers...>       Replace config phone list with these
  --email  <addrs...>    Add email recipients (space-separated)
  --emailr <addrs...>    Replace config email list with these
  -e  / -er              Short forms of --email / --emailr
  -s [text]              Enable speech (optional custom text)

Options:
  --msg <text>           Static text message (skip AI)
  -v <1-3>               Verbosity (1: Brief, 2: Normal, 3: Chatty)
  --ai <model>           AI provider/model (auto-detected from name)
  --aip <prompt>         Additional AI instructions
  -d                     Debug mode (foreground, shows JSON traffic)
  -h                     Show this help
```

## Examples

```bash
# Uses DEFAULT channels from config
msgme -- make build

# AI providers
msgme --ai gemma3:1b -- make build           # Ollama (local, fast, tiny)
msgme --ai claude-haiku-4-5 -- make build    # Claude (Sub Max)
msgme --ai gpt-5.1-codex-mini -- make build  # Codex (OpenAI)
msgme --ai gemini -- make build              # Gemini

# Add recipients on top of config defaults
msgme -n +15559999999 -- make build          # add a phone
msgme --email extra@team.com -- ./deploy.sh  # add an email
msgme -n +1555 +1666 --email a@b.com -s -- cmd  # add multiple + speech

# Replace config recipients for this run only
msgme -nr +15559999999 -- make build         # only this phone
msgme -er solo@team.com -- ./deploy.sh       # only this email

# Static message (no AI)
msgme --msg "Deploy done" -- ./deploy.sh

# Debug mode — see the AI request/response
msgme -d -- echo "hello world"

# Custom AI instructions
msgme --aip "focus on any errors or warnings" -- npm test
```

## How It Works

1. Runs your command, capturing output via `tee`
2. Sends the last 100 lines + exit code to your chosen AI provider for summarization
3. Delivers the AI-generated summary via iMessage, email, and/or speech
4. Without `-d`, notifications happen in the background — your shell returns immediately

## License

MIT
