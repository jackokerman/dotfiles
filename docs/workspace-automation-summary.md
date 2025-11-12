# Workspace Automation Summary

**Date:** October 30, 2025  
**Status:** Shell scripts working perfectly. Aerospace-layout-manager evaluated with limitations identified.

---

## Table of Contents
1. [What Was Accomplished](#what-was-accomplished)
2. [Working Shell Scripts](#working-shell-scripts)
3. [Aerospace-Layout-Manager Setup](#aerospace-layout-manager-setup)
4. [Technical Details](#technical-details)
5. [Upstream Contribution Opportunities](#upstream-contribution-opportunities)
6. [Next Steps](#next-steps)

---

## What Was Accomplished

### ✅ Completed
- **Created working shell scripts** for all workspace arrangements (B, M, N, P, T)
- **Mastered Workspace M layout** - Complex arrangement with Slack left, Gmail+Calendar vertical accordion right
- **Identified Chrome profile handling** - Using window title patterns to distinguish profiles
- **Evaluated aerospace-layout-manager** - Installed and configured, identified limitations
- **Documented bundle IDs** for all apps and PWAs

### 📋 Workspace Configuration

| Workspace | App(s) | Notes |
|-----------|--------|-------|
| B | Chrome (Stripe work profile) | Uses window title pattern `%(Stripe%)` |
| M | Slack + Gmail + Calendar | Complex layout: Slack left, Gmail+Calendar vertical accordion right |
| N | Obsidian | Simple single app |
| P | Chrome (Personal profile) | Uses window title pattern `%(Personal%)` |
| T | Godspeed (PWA) | Simple single app |
| Z | Zoom | Excluded - handled by AeroSpace rules |

---

## Working Shell Scripts

### Location
All scripts in: `/Users/jackokerman/dotfiles/scripts/`

### Scripts Created

#### 1. `test-list-windows.sh`
Debug helper to list all windows with their IDs, names, titles, and workspaces.
```bash
./test-list-windows.sh
```

#### 2. Individual Workspace Scripts
- `arrange-workspace-b.sh` - Chrome (Stripe)
- `arrange-workspace-m.sh` - Messaging (Slack + Gmail + Calendar)
- `arrange-workspace-n.sh` - Obsidian
- `arrange-workspace-p.sh` - Chrome (Personal)
- `arrange-workspace-t.sh` - Godspeed

#### 3. `arrange-all-workspaces.sh`
Master script that runs all workspace arrangements sequentially.

```bash
cd ~/dotfiles/scripts
./arrange-all-workspaces.sh
```

#### 4. `arrange-work.sh`
Alternative using aerospace-layout-manager (see limitations below).

### Key Implementation Details

#### Workspace M (Most Complex)
The final working approach:
```bash
# 1. Flatten everything
/opt/homebrew/bin/aerospace flatten-workspace-tree

# 2. Set root to horizontal tiles
/opt/homebrew/bin/aerospace layout tiles horizontal

# 3. Join Gmail and Calendar
/opt/homebrew/bin/aerospace focus --window-id $GMAIL_ID
/opt/homebrew/bin/aerospace focus --window-id $CAL_ID
/opt/homebrew/bin/aerospace join-with up  # Creates vertical container

# 4. Set accordion on the vertical container
/opt/homebrew/bin/aerospace layout accordion vertical
```

**Critical Discovery:** With AeroSpace normalization enabled:
- `enable-normalization-flatten-containers = true`
- `enable-normalization-opposite-orientation-for-nested-containers = true`

When root is horizontal, joining windows creates a vertical container automatically (opposite orientation). Cannot use `split` command - must use `join-with`.

#### Chrome Profile Identification
All Chrome windows share bundle ID: `com.google.Chrome`

Distinguished by window title:
- Stripe profile: `"Jack (Stripe)"` in title
- Personal profile: `"Jack (Personal)"` in title
- Launch command: `--profile-directory=Default` or `--profile-directory=Profile 1`

Shell script uses grep with patterns:
```bash
grep "%(Stripe%)"  # Matches "(Stripe)" in window title
grep "%(Personal%)"  # Matches "(Personal)" in window title
```

---

## Aerospace-Layout-Manager Setup

### Installation
Already installed at: `/usr/local/bin/aerospace-layout-manager`

### Configuration
**Location:** `~/.config/aerospace/layouts.json`

### Current Layouts
- `browser` - Workspace B (Chrome)
- `messaging` - Workspace M (Slack + Gmail + Calendar)
- `notes` - Workspace N (Obsidian)
- `tasks` - Workspace T (Godspeed)

### Usage
```bash
# List available layouts
aerospace-layout-manager --listLayouts

# Run individual layout
aerospace-layout-manager messaging

# Run all via wrapper script
~/dotfiles/scripts/arrange-work.sh
```

### ⚠️ Limitations Discovered

1. **No nested group layouts**
   - Nested groups can only have `orientation` (horizontal/vertical)
   - Cannot specify `layout` (tiles/accordion) for nested groups
   - Root workspace gets one layout type applied to everything
   - **Impact:** Cannot replicate Workspace M's exact layout (Slack tiles + Gmail/Calendar accordion)

2. **No Chrome profile support**
   - All Chrome windows share same bundle ID: `com.google.Chrome`
   - Cannot distinguish between Stripe vs Personal profile
   - No `windowTitlePattern` field to filter by title
   - No `launchArgs` field to launch with specific profile
   - **Impact:** Cannot correctly arrange workspaces B and P

3. **Tool workflow**
   - Each layout targets ONE workspace (not multiple)
   - Must run multiple layouts sequentially for full setup
   - Tool checks if app is running first, then launches if needed

---

## Technical Details

### Bundle IDs Discovered

| App/PWA | Bundle ID |
|---------|-----------|
| Chrome (any profile) | `com.google.Chrome` |
| Gmail PWA | `com.google.Chrome.app.fmgjjmmmlfnkbppncabfkddbjimcfncm` |
| Google Calendar PWA | `com.google.Chrome.app.kjbdgfilnfhdoflbpgamdcdgpehopbep` |
| Godspeed PWA | `com.google.Chrome.app.ncocdijngbioiajbolgcnndalmbpaabn` |
| Slack | `com.tinyspeck.slackmacgap` |
| Obsidian | `md.obsidian` |
| Cursor | `com.todesktop.230313mzl4w4u92` |

**Key Finding:** PWAs have unique bundle IDs, so they work perfectly with aerospace-layout-manager!

### Chrome Profile Directories
- **Work (Stripe):** `Default` - Window title contains "(Stripe)"
- **Personal:** `Profile 1` - Window title contains "(Personal)"

Launch with profile:
```bash
open -b "com.google.Chrome" --args --profile-directory="Default"
open -b "com.google.Chrome" --args --profile-directory="Profile 1"
```

Or via CLI:
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --profile-directory=Default
```

### AeroSpace Normalization Impact

From `/Users/jackokerman/dotfiles/config/aerospace/aerospace.toml`:
```toml
enable-normalization-flatten-containers = true
enable-normalization-opposite-orientation-for-nested-containers = true
```

**Effects:**
- Containers with one child are flattened (except root)
- Nested containers must have opposite orientations
- If root is horizontal, nested container becomes vertical automatically
- `split` commands don't work - must use `join-with`

**Example:**
```
h_tiles (root)
├── Slack
└── v_tiles (created automatically by normalization)
    ├── Gmail
    └── Calendar
```

---

## Upstream Contribution Opportunities

### 1. Nested Group Layouts (High Value)
**Problem:** Nested groups can only specify orientation, not layout type.

**Proposed Solution:**
```typescript
interface LayoutGroup {
    orientation: Orientation;
    layout?: WorkspaceLayout;  // NEW: optional layout for nested groups
    windows: LayoutWindow[];
}
```

**Config example:**
```json
{
  "orientation": "vertical",
  "layout": "v_accordion",  // NEW
  "windows": [...]
}
```

**Implementation:** Modify `traverseTreeReposition` function to apply layout when focusing first window in a group:
```typescript
if ("windows" in item && item.layout) {
    const firstWindowId = await getWindowId(item.windows[0].bundleId);
    if (firstWindowId) {
        await focusWindow(firstWindowId);
        await $`aerospace layout ${item.layout}`;
    }
}
```

**Estimated Effort:** ~20-30 lines of code  
**Impact:** Enables complex layouts like Workspace M  
**Community Value:** High - common use case

### 2. Chrome Profile Support (High Value)
**Problem:** Cannot distinguish Chrome windows by profile or launch with specific profiles.

**Proposed Solution:**
```typescript
interface LayoutWindow {
    bundleId: string;
    windowTitlePattern?: string;  // NEW: regex to match window title
    launchArgs?: string[];        // NEW: args to pass when launching
}
```

**Config example:**
```json
{
  "bundleId": "com.google.Chrome",
  "windowTitlePattern": "Jack \\(Stripe\\)",
  "launchArgs": ["--profile-directory=Default"]
}
```

**Implementation Changes:**

1. **Update `getWindowId` function:**
```typescript
async function getWindowId(bundleId: string, windowTitlePattern?: string) {
    const bundleJson = await $`aerospace list-windows --monitor all --app-bundle-id "${bundleId}" --json`.json();
    
    let windows = bundleJson || [];
    if (windowTitlePattern && windows.length > 0) {
        const regex = new RegExp(windowTitlePattern);
        windows = windows.filter((w: any) => regex.test(w["window-title"]));
    }
    
    return windows.length > 0 ? windows[0]["window-id"] : null;
}
```

2. **Update `launchIfNotRunning` function:**
```typescript
async function launchIfNotRunning(bundleId: string, launchArgs?: string[]) {
    const isRunning = await $`osascript -e "application id \"${bundleId}\" is running" | grep -q true`.text() === "true";
    if (!isRunning) {
        if (launchArgs && launchArgs.length > 0) {
            await $`open -b "${bundleId}" --args ${launchArgs}`;
        } else {
            await $`open -b "${bundleId}"`;
        }
    }
}
```

3. **Update `ensureWindow` function:**
```typescript
async function ensureWindow(window: LayoutWindow) {
    await launchIfNotRunning(window.bundleId, window.launchArgs);
    for await (const i of Array(30)) {
        const windowId = await getWindowId(window.bundleId, window.windowTitlePattern);
        if (windowId) return windowId;
        await new Promise((resolve) => setTimeout(resolve, 100));
    }
    return null;
}
```

**Estimated Effort:** ~50-100 lines of code  
**Impact:** Enables workspaces B and P  
**Community Value:** Very high - Chrome profiles are common

### Testing Strategy for Contributions

**Development Environment Options:**

1. **Bun (Recommended)** - Tool's native runtime
   ```bash
   curl -fsSL https://bun.sh/install | bash  # No sudo needed
   bun install
   bun run index.ts --layout test
   ```

2. **Deno (Alternative)** - For restricted work environments
   - Change shebang: `#!/usr/bin/env -S deno run --allow-read --allow-run --allow-env`
   - Change imports: `import $ from "https://deno.land/x/dax@0.39.2/mod.ts"`
   - Replace `Bun.file()` with `Deno.readTextFile()`
   - Test in `deno-testing` branch
   - Port changes to `main` branch for PR

**Contribution Workflow:**
1. Fork repo: `https://github.com/CarterMcAlister/aerospace-layout-manager`
2. Create feature branch from `main`
3. Make changes and test locally
4. Submit PR with clear use case examples
5. Consider separate PRs for each feature

---

## Next Steps

### Immediate Options

**Option A: Use Shell Scripts (Recommended for now)**
- Shell scripts work perfectly for all workspaces
- No limitations
- Already implemented and tested
- Run: `~/dotfiles/scripts/arrange-all-workspaces.sh`

**Option B: Hybrid Approach**
- Use aerospace-layout-manager for simple workspaces (N, T)
- Use shell scripts for complex ones (B, M, P)
- Create combined wrapper script

**Option C: Contribute Upstream**
- Fork aerospace-layout-manager
- Add nested group layout support
- Add Chrome profile support
- Use improved tool for everything

### Future Enhancements

1. **App Opening Logic**
   - Add logic to open apps if not running
   - Smart detection of already-running apps
   - Sequenced opening with delays if needed

2. **Raycast Integration**
   - Create Raycast script to trigger workspace arrangement
   - Make it easily accessible via Cmd+Space
   - Store script in dotfiles for portability

3. **Chrome Window State Persistence**
   - Save Chrome window positions before updates
   - Restore after Chrome restarts
   - Handle PWAs separately from browser windows
   - Two-script approach: save state, restore state

### Related Files and Configurations

**Dotfiles:**
- `/Users/jackokerman/dotfiles/config/aerospace/aerospace.toml` - AeroSpace config
- `/Users/jackokerman/dotfiles/scripts/` - All workspace arrangement scripts
- `/Users/jackokerman/dotfiles/config/hammerspoon/MySpoons/SmartLinkManager.spoon/` - Chrome profile routing for URLs

**Machine-Specific:**
- `/Users/jackokerman/stripe-dotfiles/.config/hammerspoon/init-local.lua` - Hammerspoon local config
- Shows Chrome profile names: `Default` (work), `Profile 1` (personal)

**Aerospace-Layout-Manager:**
- Repo: https://github.com/CarterMcAlister/aerospace-layout-manager
- Local config: `~/.config/aerospace/layouts.json`
- Binary: `/usr/local/bin/aerospace-layout-manager`

---

## Command Reference

### Testing and Debugging
```bash
# List all windows with details
/opt/homebrew/bin/aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}|%{workspace}'

# List with bundle IDs
/opt/homebrew/bin/aerospace list-windows --all --format '%{app-bundle-id}|%{app-name}|%{window-title}'

# List windows in specific workspace
/opt/homebrew/bin/aerospace list-windows --workspace M --format '%{window-id}|%{app-name}'

# Focus specific window
/opt/homebrew/bin/aerospace focus --window-id WINDOW_ID

# Move window to workspace
/opt/homebrew/bin/aerospace move-node-to-workspace --window-id WINDOW_ID WORKSPACE
```

### Workspace Arrangement
```bash
# Shell script approach (working perfectly)
cd ~/dotfiles/scripts
./arrange-all-workspaces.sh

# Individual workspaces
./arrange-workspace-b.sh
./arrange-workspace-m.sh
./arrange-workspace-n.sh
./arrange-workspace-p.sh
./arrange-workspace-t.sh

# Aerospace-layout-manager approach
aerospace-layout-manager --listLayouts
aerospace-layout-manager browser
aerospace-layout-manager messaging
aerospace-layout-manager notes
aerospace-layout-manager tasks

# Or via wrapper
~/dotfiles/scripts/arrange-work.sh
```

### Layout Commands (within workspace)
```bash
# Flatten workspace
/opt/homebrew/bin/aerospace flatten-workspace-tree

# Set layout
/opt/homebrew/bin/aerospace layout tiles horizontal
/opt/homebrew/bin/aerospace layout accordion vertical

# Join windows
/opt/homebrew/bin/aerospace join-with up
/opt/homebrew/bin/aerospace join-with left
```

---

## Lessons Learned

### AeroSpace Normalization
- Normalization rules fundamentally change how layouts work
- Can't use `split` commands with flatten-containers enabled
- Must use `join-with` to create nested containers
- Opposite orientation is automatically enforced

### Window Identification
- PWAs have unique bundle IDs (great for automation!)
- Chrome profiles share same bundle ID (needs title matching)
- Window titles include profile names in parentheses
- Bundle IDs are the reliable way to identify apps

### Tool Evaluation
- aerospace-layout-manager is well-designed but has specific limitations
- JSON config is cleaner than shell scripts for simple cases
- Shell scripts provide more flexibility for complex layouts
- Upstream contributions could make the tool work for our use case

### Incremental Development
- Starting with simple scripts and building up worked well
- Testing each workspace individually caught issues early
- Debug output (printing window lists) was essential
- User feedback on visual results was critical for layout issues

---

## Questions for Future Consideration

1. Should we create a hybrid system or wait for upstream improvements?
2. Is the nested layout feature worth contributing upstream?
3. Would Chrome window state persistence be valuable given frequent updates?
4. Should Raycast integration be built now or wait for final tool decision?
5. Should we explore other window managers or stick with AeroSpace?

---

## Resources

- **AeroSpace Documentation:** https://nikitabobko.github.io/AeroSpace/guide
- **Aerospace-Layout-Manager:** https://github.com/CarterMcAlister/aerospace-layout-manager
- **Hammerspoon:** https://www.hammerspoon.org/
- **SmartLinkManager Spoon:** `/Users/jackokerman/dotfiles/config/hammerspoon/MySpoons/SmartLinkManager.spoon/init.lua`

---

**End of Summary**

*This document captures the complete context of workspace automation work done on October 30, 2025. All shell scripts are working and production-ready. The aerospace-layout-manager evaluation identified specific limitations that could be addressed through upstream contributions.*

