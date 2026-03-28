# msgme

A macOS CLI wrapper that runs any command and sends you an AI-summarized notification when it finishes — via iMessage, speech, or both.

Powered by [Ollama](https://ollama.com) for local AI summarization.

## Why?

Long-running builds, deploys, and test suites don't need you watching the terminal. Wrap your command with `msgme` and get a text when it's done.

## Features

- **iMessage notifications** — get a text with an AI-generated summary of your command's output
- **Speech announcements** — hear the result spoken aloud via macOS `say`
- **Local AI summaries** — uses Ollama to generate concise, context-aware messages (no cloud APIs)
- **Verbosity control** — tune how chatty the AI summary is (brief, normal, chatty)
- **Background by default** — notifications fire in the background so you get your shell back instantly
- **Debug mode** — run in foreground with pretty-printed JSON to see the full AI request/response

## Requirements

- macOS (iMessage + `say` are macOS-only)
- [Ollama](https://ollama.com) running locally (or on a remote host)
- Python 3 (pre-installed on macOS)
- zsh (default macOS shell)

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
AI_HOST="localhost:11434"
AI_MODEL="gemma3:27b"
VERBOSITY=3
```

All settings can be overridden via command-line flags.

## Usage

```
Usage: msgme [options] -- command [args]

Options:
  -n <number>        iMessage phone number (e.g., +17605551234)
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
```

## How It Works

1. Runs your command, capturing output via `tee`
2. Sends the last 100 lines + exit code to Ollama for summarization
3. Delivers the AI-generated summary via iMessage and/or speech
4. Without `-d`, notifications happen in the background — your shell returns immediately

## License

MIT
