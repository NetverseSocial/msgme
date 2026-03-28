# msgme

A macOS CLI wrapper that runs any command and sends you an AI-summarized notification when it finishes — via iMessage, email, speech, or any combination.

Powered by [Ollama](https://ollama.com) for local AI summarization.

## Why?

Long-running builds, deploys, and test suites don't need you watching the terminal. Wrap your command with `msgme` and get a text when it's done.

## Features

- **iMessage notifications** — get a text with an AI-generated summary of your command's output (Apple devices)
- **Email notifications** — cross-platform delivery via SMTP API (default: [Brevo](https://www.brevo.com))
- **Speech announcements** — hear the result spoken aloud via macOS `say`
- **Local AI summaries** — uses Ollama to generate concise, context-aware messages (no cloud APIs)
- **Verbosity control** — tune how chatty the AI summary is (brief, normal, chatty)
- **Background by default** — notifications fire in the background so you get your shell back instantly
- **Debug mode** — run in foreground with pretty-printed JSON to see the full AI request/response

## Requirements

- macOS (iMessage + `say` are macOS-only; email works anywhere)
- [Ollama](https://ollama.com) running locally (or on a remote host)
- Python 3 (pre-installed on macOS)
- zsh (default macOS shell)
- For email: a [Brevo](https://www.brevo.com) account (free tier available) with API key

## Install

```bash
# Clone and copy to your PATH
git clone https://github.com/NetverseSocial/msgme.git
cp msgme/main/msgme /usr/local/bin/msgme
chmod +x /usr/local/bin/msgme
```

## Configuration

Create `~/.msgme.conf` with your defaults:

```bash
PHONE="+15551234567"
EMAIL="user@example.com"
AI_HOST="localhost:11434"
AI_MODEL="gemma3:27b"
VERBOSITY=3
```

For email notifications, set your Brevo API key as an environment variable:

```bash
export BREVO_SMTP_API_KEY="your-api-key-here"
```

Optionally customize the sender in `~/.msgme.conf`:

```bash
EMAIL_FROM="notifications@yourdomain.com"
EMAIL_FROM_NAME="My Build Server"
```

All settings can be overridden via command-line flags.

### Notification Methods

| Method | Flag | Best For |
|--------|------|----------|
| **iMessage** | `-n <number>` | Apple device users on the same iMessage network |
| **Email** | `--email <addr>` | Cross-platform — works with any email address, any device |
| **Speech** | `-s [text]` | Local audio announcement on the Mac running the command |

You can combine all three — use `-n`, `--email`, and `-s` together.

## Usage

```
Usage: msgme [options] -- command [args]

Options:
  -n <number>        iMessage phone number (e.g., +17605551234)
  --email <addr>     Email notification address
  --msg <text>       Static text message (skip AI)
  -s [text]          Enable speech (optional custom text)
  -v <1-3>           Verbosity (1: Brief, 2: Normal, 3: Chatty)
  --ai [host:port] <model>  AI config (default host: localhost:11434)
  --aip <prompt>     Additional AI instructions
  -d                 Debug mode (foreground, shows JSON traffic)
  -h                 Show this help
```

## Examples

```bash
# Text me when the build finishes
msgme -- make build

# With speech announcement
msgme -s -- ./run_tests.sh

# Override AI model on the fly
msgme --ai "gemma3:27b" -- docker compose up --build

# Debug mode — see the AI request/response
msgme -d -- echo "hello world"

# Static message (no AI)
msgme --msg "Deploy done" -- ./deploy.sh

# Custom AI instructions
msgme --aip "focus on any errors or warnings" -- npm test

# Email notification (cross-platform, no iMessage needed)
msgme --email colleague@example.com -- ./deploy.sh

# Combine iMessage + email + speech
msgme -n +15551234567 --email team@example.com -s -- make build
```

## How It Works

1. Runs your command, capturing output via `tee`
2. Sends the last 100 lines + exit code to Ollama for summarization
3. Delivers the AI-generated summary via iMessage, email, and/or speech
4. Without `-d`, notifications happen in the background — your shell returns immediately

## License

MIT
