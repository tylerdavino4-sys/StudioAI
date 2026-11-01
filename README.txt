# StudioAI — Roblox Studio AI plugin

StudioAI is a local-first Roblox Studio plugin plus a small Node.js backend. The plugin sends prompts to a local backend, which calls the OpenAI Responses API. Proposed changes are shown for review before you click Apply.

## Requirements
- Windows 10/11
- Roblox Studio
- Node.js 18 or newer
- An OpenAI API key with API billing enabled

ChatGPT subscriptions and API billing are separate. Never share your API key. Ask a parent or guardian to help with API billing if needed.

## Start the backend
1. Install Node.js 18+ from https://nodejs.org/.
2. Double-click START_STUDIOAI.bat.
3. Enter your own OpenAI API key in the hidden prompt.
4. Keep the terminal window open. The backend listens at http://127.0.0.1:3210.

The key is held by the backend process and is not sent to Roblox Studio or saved in this project.

## Install the plugin
Open Roblox Studio's Plugins tab and choose Plugins Folder / Open Plugins Folder. Follow Roblox Studio's supported local-plugin workflow to install plugin/StudioAI.plugin.lua. If your Studio version does not accept a Lua source file directly, create a Script, paste the plugin source, then use Save as Local Plugin.

## Use it
Start the backend, open StudioAI from the Plugins toolbar, enter a build request, review the proposed changes, and click Apply only if they look right.

## Current limitations
This first version can create parts, folders, and scripts. It does not safely edit or delete existing objects, inspect every script, or automatically diagnose all runtime errors. Review generated scripts and save a copy of your place before applying larger changes.

## Security
The backend listens only on 127.0.0.1. The plugin uses an allowlist of operation types, classes, and parent services. It does not execute arbitrary shell commands.
