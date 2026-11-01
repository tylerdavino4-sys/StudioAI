# StudioAI Tutorial (Windows)

This guide walks you through installing and using StudioAI with Roblox Studio.

## What you need

- Windows 10 or 11
- Roblox Studio
- Node.js 18 or newer
- Your own OpenAI API key

**Important:** ChatGPT subscriptions and OpenAI API billing are separate. API use may cost money. Ask a parent or guardian before adding payment details. Never share your API key in screenshots, chat, Discord, or GitHub.

## 1. Download StudioAI

1. Open the [StudioAI GitHub repository](https://github.com/tylerdavino4-sys/StudioAI).
2. Click **Code**, then **Download ZIP**.
3. Extract the ZIP.
4. Open the extracted `StudioAI-main` folder. If Windows created two folders with that name, open the inner one.

## 2. Install the local Roblox Studio plugin

1. In File Explorer, open the `plugin` folder inside the StudioAI project.
2. Find `StudioAI.plugin.lua`.
3. Copy that file.
4. Press **Windows + R**.
5. Enter `%LOCALAPPDATA%\Roblox\Plugins` and press Enter.
6. If the `Plugins` folder does not exist, create it inside `%LOCALAPPDATA%\Roblox`.
7. Paste `StudioAI.plugin.lua` into the `Plugins` folder.
8. Close Roblox Studio completely and reopen it.
9. Open the **Plugins** tab and click the **StudioAI** toolbar button.

Do not put the file in `OTAPlugins`; use the `Plugins` folder.

## 3. Start the local backend

1. Open the StudioAI project folder.
2. Double-click `START_STUDIOAI.bat`.
3. When prompted, paste your own OpenAI API key. The prompt hides what you type.
4. Press Enter.
5. Wait until the terminal says the backend is running at `http://127.0.0.1:3210`.
6. Keep this terminal window open while using StudioAI.

If you do not have an API key, visit [OpenAI API keys](https://platform.openai.com/api-keys). Create your own key and keep it private. Do not paste it into the Roblox plugin or commit it to GitHub.

## 4. Ask StudioAI to build something

1. Open a place in Roblox Studio.
2. Click **Plugins → StudioAI** (or the StudioAI toolbar button).
3. Type a clear request in the text box. For example:
   - `Create a small obby with 8 anchored platforms and a red finish platform.`
   - `Create a folder in Workspace named MapProps.`
   - `Create a Script in ServerScriptService that prints Hello from my game.`
4. Click **Ask AI** or press Enter.
5. Read the response and proposed changes.
6. Check the proposal. Click **Apply** only if you want those changes added to your place.
7. Check Explorer and the 3D view. Save your place when you are happy with the result.

## 5. Important safety and limitations

- StudioAI shows proposed changes before applying them. Always read the proposal first.
- Save a copy of your place before applying larger changes.
- Generated scripts can contain mistakes. Read and test them before publishing your game.
- This starter version creates new Parts, folders, and Scripts/LocalScripts/ModuleScripts in a limited set of services. It does not safely edit or delete existing objects.
- Do not use generated code to steal accounts, items, credentials, or data.
- Your API key is used by the local backend. Never share it or upload it to the repository.
- API requests may incur charges. Check your API usage and limits.

## Troubleshooting

### StudioAI button does not appear
- Confirm `StudioAI.plugin.lua` is directly inside `%LOCALAPPDATA%\Roblox\Plugins`.
- Restart Roblox Studio completely.
- Check the Studio **Plugins** tab again.

### StudioAI says it cannot reach the backend
- Start `START_STUDIOAI.bat`.
- Confirm the terminal says `StudioAI backend running at http://127.0.0.1:3210`.
- Keep the terminal open.
- If Windows Firewall asks about access, allow only what is needed for the local app; the backend listens on your own PC at `127.0.0.1`.

### The AI request fails
- Check that the API key was entered correctly when starting the backend.
- Check your OpenAI API account, available balance/credits, usage limits, and billing settings.
- Never send your API key to anyone for troubleshooting.

### Apply does not create what you expected
- Read any error message shown by StudioAI.
- Check Explorer and the Output window.
- Try a smaller, more specific request.
- Remember that this is an early starter project and not every request is supported.

## Project files

- `START_STUDIOAI.bat` — starts the backend setup.
- `START_STUDIOAI.ps1` — securely prompts for the API key and starts Node.
- `backend/server.js` — local server that calls the OpenAI API.
- `plugin/StudioAI.plugin.lua` — Roblox Studio dockable plugin.
