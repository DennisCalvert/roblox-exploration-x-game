# Editor setup for .luau files

This workspace uses **Luau** (Roblox) with type checking. To get both **syntax highlighting** and **correct linting** (Roblox globals like `game`, `Folder`, `RemoteEvent`):

1. **Install [Luau Language Server](https://marketplace.visualstudio.com/items?itemName=JohnnyMorganz.luau-lsp)** (JohnnyMorganz).  
   It provides the Luau grammar (highlighting) and the language server (linting with Roblox API).

2. **Use language mode "Luau"** for `.luau` files.  
   The workspace already has `"*.luau": "luau"` in `settings.json`, so this should be automatic. If a file still shows "Plain Text" or "Lua", click the language in the status bar (or `Ctrl+K M` / `Cmd+K M`) and choose **Luau**.

3. **Reload the window** after installing: Command Palette → "Developer: Reload Window".

If you see **highlighting but wrong lint errors** (e.g. "undefined global" for `game`): the file is in **Lua** mode; switch it to **Luau** so Luau LSP runs instead of the Lua linter.

If you see **correct linting but no highlighting**: Luau LSP is running but its grammar may not be loading. Try Reload Window, or ensure the Luau Language Server extension is enabled for this workspace.

---

**Fallback (highlighting only, reduce Lua noise)**  
If Luau LSP’s grammar never loads in your environment and you prefer to keep `"*.luau": "lua"` for highlighting, you can at least hide the “undefined global” warnings from the Lua linter by adding to `settings.json`:

```json
"Lua.diagnostics.disable": ["undefined-global"]
```

You will still get incorrect Lua errors on Luau type syntax (`: Type`, `?`, etc.). The only way to get correct linting and highlighting together is for Luau LSP to handle `.luau` files (language mode **Luau**).
