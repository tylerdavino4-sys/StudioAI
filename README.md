# StudioAI

A Roblox Studio assistant with a local plugin and a backend that can run free with Ollama on your PC. An optional OpenAI API mode is also available.

## Free local setup (recommended)
1. Install Node.js 18 or newer: https://nodejs.org/
2. Install Ollama: https://ollama.com/download/windows
3. Download this repository using **Code → Download ZIP**, then extract it.
4. Double-click `START_STUDIOAI_FREE.bat`. The first run downloads the local `qwen2.5-coder:3b` model.
5. Install `plugin/StudioAI.plugin.lua` as a local Roblox Studio plugin.
6. Keep the backend window open, restart Roblox Studio, open StudioAI from the Plugins toolbar, and describe what you want to build.

## Optional OpenAI mode
Use `START_STUDIOAI.bat` only if you have an OpenAI API key and API billing enabled. ChatGPT subscriptions and API billing are separate.

## Current capabilities
- Chat with the assistant inside Roblox Studio.
- Propose new parts, folders, and scripts.
- Review proposed changes and click **Apply** before insertion.
- Create objects inside folders created earlier in the same approved build.
- Keep API credentials in the local backend, never in the Studio plugin.

## Safety and limitations
- The plugin only creates new objects; it does not safely edit or delete existing objects.
- Creation is restricted to approved Roblox services and folders underneath them.
- Review generated scripts and save a copy of your place before applying large changes.
- This is an early project and may still need fixes for unusual AI responses or Roblox Studio versions.
- Never share your API key.
