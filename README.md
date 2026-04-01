# @paperclipai/plugin-chat

Multi-adapter AI chat plugin for Paperclip. Provides a conversational interface to Paperclip agents with thread management, slash commands, and real-time streaming.

## Installation from Zero

### Prerequisites

- A running Paperclip instance (`paperclipai` CLI available)
- Node.js 20+ and npm
- At least one agent with `adapterType: "claude_local"` (or another supported adapter)

### Step 1: Clone and install

```bash
git clone https://github.com/NSXBet/paperclip-plugin-chat.git
cd paperclip-plugin-chat
npm install
npm run build
```

The `preinstall` script automatically locates and copies the Paperclip Plugin SDK from your local Paperclip installation (bun cache, npm cache, or plugins directory).

If the auto-detection fails, set it up manually:

```bash
# Find the SDK in your Paperclip installation's cache:
mkdir -p .paperclip-sdk
cp -r ~/.bun/install/cache/@paperclipai/plugin-sdk@*/ .paperclip-sdk/plugin-sdk
# Then re-run:
npm install
npm run build
```

The build pipeline:
1. `tsc` — type-checks and emits declaration files
2. `build-worker.mjs` — bundles `src/worker.ts` with esbuild (all deps inlined, zero runtime resolution needed)
3. `build-ui.mjs` — bundles `src/ui/index.tsx` with esbuild (React/SDK UI externalized)

Output: `dist/worker.js` (server-side, self-contained) and `dist/ui/index.js` (browser bundle).

### Step 3: Install the plugin into Paperclip

```bash
paperclipai plugin install "$(pwd)" --local
```

> **Note:** This command requires board-level access. Run it as the Paperclip board user, not as an agent.

### Step 4: Verify the plugin is running

```bash
paperclipai plugin inspect paperclip-chat
```

Look for `status: running`. If it shows `errored`, check `paperclipai plugin inspect paperclip-chat` for error details.

### Step 5: Access the chat

After installation, hard-refresh your browser (Ctrl+Shift+R). You should see:
- A **"Chat"** link in the company sidebar (between Inbox and Issues)
- Clicking it navigates to `/:companyPrefix/chat`

## How It Works

The plugin creates a chat UI inside the Paperclip plugin page slot. When a user sends a message, the plugin:

1. Creates a thread (persisted in plugin state)
2. Finds a compatible agent via `ctx.agents.list()` (prefers "Chat Assistant", falls back to role "general")
3. Creates or resumes an agent session via `ctx.agents.sessions`
4. Streams the agent's response back to the UI

All LLM access goes through Paperclip's agent session system. The plugin does not talk to models directly — it talks to agents that talk to models. See [Plugin vs Core Analysis](docs/plugin-vs-core-chat.md) for the implications of this architecture.

## Features

### Chat UI
- Welcome screen with quick action chips (check issues, review goals, plan work, agent status)
- Threaded conversations with sidebar navigation
- Rich markdown rendering (tables, code blocks, lists, links, blockquotes)
- Collapsible tool usage display ("Used 3 tools Bash x3")
- Auto-generated thread titles from first message
- Inline thread rename (double-click) and delete (with confirmation)

### Slash Commands
Type `/` in the input to access built-in commands:

| Command | Action |
|---------|--------|
| `/tasks` | List active tasks |
| `/dashboard` | Workspace dashboard |
| `/agents` | Agent status overview |
| `/create` | Create a new task |
| `/projects` | List projects |
| `/costs` | Cost breakdown |
| `/activity` | Recent activity |
| `/blocked` | Blocked tasks |
| `/plan` | Plan and break down work |
| `/handoff` | Hand off work to an agent |

### Streaming
The plugin supports real-time streaming via SSE (`ctx.streams`). During agent execution, users see live text output with a blinking cursor, tool activity indicators, and a stop button.

## Configuration

Navigate to **Settings > Plugins > Chat** (gear icon):

| Setting | Description |
|---------|-------------|
| Default Adapter | Adapter type for new threads (`claude_local`, `codex_local`, `opencode_local`) |
| System Prompt Override | Custom text appended to chat sessions |

## Plugin Capabilities

| Capability | Purpose |
|-----------|---------|
| `ui.page.register` | Full chat page at `/:prefix/chat` |
| `ui.sidebar.register` | Sidebar nav link |
| `agent.sessions.*` | Create and message agent sessions |
| `agents.read` | Discover available agents/adapters |
| `plugin.state.*` | Thread and message persistence |
| `activity.log.write` | Activity logging |

## Architecture

```
Browser                          Server
-------                          ------
ChatPage (React)
  |
  |-- usePluginData("threads")    --> Worker: getData("threads")
  |-- usePluginData("messages")   --> Worker: getData("messages")
  |-- usePluginAction("sendMessage") --> Worker: sendMessage action
  |                                      |
  |                                      |--> ctx.agents.sessions.create()
  |                                      |--> ctx.agents.sessions.sendMessage()
  |                                      |      |
  |                                      |      +--> Agent adapter --> CLI process
  |                                      |      |
  |                                      |      +--> onEvent callbacks
  |                                      |
  |                                      |--> ctx.streams.emit() (SSE)
  |
  |-- usePluginStream("chat:threadId") <-- SSE events (text, thinking, tool, done)
```

## Troubleshooting

### Plugin fails to activate with `ERR_MODULE_NOT_FOUND: Cannot find package 'zod'`

The worker must be bundled with esbuild so all dependencies (including `@paperclipai/plugin-sdk`, `zod`, `@paperclipai/shared`) are inlined. If you see this error, run `npm run build` — the build script bundles the worker via `scripts/build-worker.mjs`.

### Chat link doesn't appear in sidebar

Paperclip's sidebar renders `PluginSlotOutlet` with `slotTypes=["sidebar"]`, which matches `ui.slots` entries — not `launchers`. The manifest must include a `sidebar` type slot (not just a launcher). This is already configured in the current version.

### Plugin shows `status: errored` after install

```bash
paperclipai plugin inspect paperclip-chat
```

Check the error message. Common causes:
- Missing SDK: ensure `.paperclip-sdk/plugin-sdk` exists and `npm install` completed
- Build not run: ensure `npm run build` completed without errors

## Development

```bash
# Type-check without building
npm run typecheck

# Full build
npm run build

# Clean build artifacts
npm run clean

# Reinstall after changes
paperclipai plugin uninstall paperclip-chat
paperclipai plugin install "$(pwd)" --local
```

## Known Limitations

- **No direct LLM access** — requires a pre-configured agent; can't create agents or select models
- **Agent sessions are task-oriented** — no way to distinguish "answer this question" from "execute this task"
- **No deep linking** — thread state is lost on page refresh
- **Host page chrome** — breadcrumbs and back button can't be hidden

For the full analysis, see [Plugin vs Core: Chat Feature Analysis](docs/plugin-vs-core-chat.md).

## Testing

See the [Testing Guide](docs/plugin-chat-testing-guide.md) for setup instructions, a full test checklist, and troubleshooting steps.

## Related Docs

| Document | Description |
|----------|-------------|
| [Plugin vs Core Analysis](docs/plugin-vs-core-chat.md) | Why chat as a plugin has fundamental limitations |
| [Testing Guide](docs/plugin-chat-testing-guide.md) | Test checklist and setup for testers |
| [Core Integration Spec](docs/chat-core-integration.md) | Recommendation for building chat as a core page |
| [Streaming Implementation](docs/plugin-chat-streaming-implementation.md) | SSE streaming architecture notes |
| [Stream Bus Gap](docs/stream-bus-wiring-gap.md) | Stream bus wiring analysis |
