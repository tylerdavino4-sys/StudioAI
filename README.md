# StudioAI

A Roblox Studio assistant that uses an OpenAI model to suggest game builds and scripts. StudioAI runs a small backend on your own Windows PC and a dockable plugin inside Roblox Studio.

## Features in this starter version
- Chat with an AI assistant from Roblox Studio.
- Propose new map parts, folders, and scripts.
- Review a list of proposed changes and click **Apply** before anything is inserted.
- Keep your API key in the local backend; it is not included in the plugin.

## Quick start
1. Download this repository using **Code → Download ZIP**.
2. Extract the ZIP.
3. Install Node.js 18 or newer from https://nodejs.org/.
4. Open `START_STUDIOAI.bat` and enter your own OpenAI API key when prompted.
5. Install `plugin/StudioAI.plugin.lua` as a local Roblox Studio plugin.
6. Keep the backend terminal open, open StudioAI from the Plugins toolbar, and describe what you want to build.

Read [README.txt](README.txt) for fuller setup and safety notes.

## Important
- ChatGPT subscriptions and OpenAI API billing are separate. API usage may cost money.
- Never publish or share your API key. Each user must provide their own key.
- This is an early starter version. It can create new parts, folders, and scripts; it does not safely edit/delete existing objects or diagnose every runtime error.
- Review generated code and save a copy of your place before applying large changes.
- The project has not been independently tested on every Roblox Studio/Windows setup.
