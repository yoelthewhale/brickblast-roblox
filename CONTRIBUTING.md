# Contributing to BrickBlast

This project is worked on by a small team plus AI assistants (Claude, Codex, Copilot). This guide describes the workflow everyone follows.

If you are brand new here, read [`BLOCK_BLAST_START_HERE.md`](BLOCK_BLAST_START_HERE.md) first, and see the pinned onboarding issue for a suggested order of first tasks.

---

## 1. Getting set up

### Clone the repository

```bash
git clone https://github.com/yoelthewhale/brickblast-roblox.git
cd brickblast-roblox
```

Put it anywhere you like — no script depends on a specific folder.

### Install the tools

The project pins its tool versions in `rokit.toml` so everyone runs identical versions. Install [Rokit](https://github.com/rojo-rbx/rokit), then from the repository root:

```bash
rokit install
```

That gives you `rojo`, `stylua`, `selene`, and `lune` on your PATH. (Windows users: prebuilt copies also live in `tools/`, e.g. `.\tools\stylua.exe`, if you would rather not install Rokit.)

You also need **Roblox Studio**.

### How Rojo and Studio fit together

The game's source code lives in this repository as `.luau` text files. Roblox Studio cannot read those directly — **Rojo** is the bridge that syncs them into Studio.

Normal loop:

1. Run `rojo serve` (or the "Rojo: Serve" task in VS Code).
2. In Studio, open the Rojo plugin and click Connect.
3. Edit a `.luau` file in VS Code — Studio updates automatically.
4. Press Play in Studio to test.

Edit code in **VS Code**, not in Studio. Changes made inside Studio are not saved back to the repository and will be lost.

### Where the code lives

| Path | What it is |
| --- | --- |
| `src/client/ui/` | Everything the player sees — HUD, menus, shop, gameplay screen. Runs on each player's device. |
| `src/server/services/` | Server-authoritative logic — scoring, saving, rewards, purchases. |
| `src/server/world/` | The hub/lobby world, generated in code. |
| `src/shared/game/` | Rules used by both client and server — board logic, pieces, config, and all tests. |
| `docs/` | Current documentation. `docs/archive/` is historical and not accurate anymore. |
| `scripts/` | Helper scripts, including the test runner. |

---

## 2. Starting a piece of work

### Pick an issue

All work is tracked in [GitHub Issues](https://github.com/yoelthewhale/brickblast-roblox/issues). Pick one that is assigned to you or clearly unclaimed, and comment on it so nobody duplicates your effort.

New contributors should start with issues labeled **`good first issue`**, then **`beginner-friendly`**. Those have extra explanation attached in a "Notes for a first-time contributor" comment.

### Sync master and branch off it

Always start from an up-to-date `master`:

```bash
git checkout master
git pull
git checkout -b your-branch-name
```

**Never commit directly to `master`.** All work happens on a branch and arrives through a pull request.

### Branch naming

Use `type/issue-number-short-description`:

```
fix/29-spawn-shadow
feat/25-achievement-xp
docs/61-stale-docs
chore/39-remove-stale-task
```

Prefixes: `fix/` (bug), `feat/` (new capability), `docs/` (documentation), `chore/` (tooling/cleanup), `test/` (tests).

---

## 3. While you work

**Stay inside the issue's scope.** One issue, one branch, one pull request. If you spot an unrelated problem, open a new issue instead of fixing it here — it keeps reviews small and makes changes easy to undo.

### Project rules that matter

- **BrickBlast is Solo-first.** Battle, Story, and Custom Lab exist in the code but are switched off behind flags in `src/shared/game/ExperienceConfig.luau`. Do not re-enable or extend them unless an issue explicitly asks.
- **The board is always 8x8.** Exactly 64 cell buttons under `BoardGridContainer`, and no decorative objects added as direct children of it. See the "Locked Board Invariant" section in [`AGENTS.md`](AGENTS.md).
- **The server is the authority.** Anything involving score, currency, rewards, ownership, or saved data must be decided on the server. Never let the client send a value the server simply trusts.
- **Two files are near a hard Luau limit** on top-level variables (200 of them). Both have already broken the game by exceeding it, and the only symptom either time was a single "Out of local registers" line in Studio's Output:
  - `src/client/ui/BlockBlastClient.client.luau` — broke the entire HUD. Attach new values to the existing `day43Ui` table.
  - `src/server/services/GameServer.server.luau` — broke the entire server: no hub was built, no remotes were created, and players spawned onto a bare grass slab. Attach new values to an existing table, or move the concern into a new ModuleScript, which gets its own budget.
  In neither file should you add a new top-level `local`, including a local function. CI checks this (`lune run scripts/check-local-registers.luau`). If it fails, remove a local — do not raise the budget in that script, and do not add locals elsewhere just to reorganize code.

### Areas to leave alone unless the issue says otherwise

These can cause lost player data, exploits, or broken purchases:

- DataStore / profile saving and loading
- Anything about currency, purchases, receipts, or gamepasses
- RemoteEvent validation and rate limiting
- The developer-tools authorization allowlist

If an issue does put you in one of these areas, get the change reviewed before merging.

---

## 4. Validate your work

Run these from the repository root before you commit. CI runs the same ones, so passing locally means no surprises on your pull request.

```bash
stylua src                          # auto-format code
selene src                          # lint for mistakes
lune run scripts/run-tests.luau     # run the automated tests
rojo build default.project.json --output BrickBlast-check.rbxl   # confirm it still builds
git diff --check                    # catch stray whitespace / conflict markers
```

Notes:

- `stylua src` **rewrites** files to the correct format. CI runs `stylua --check src`, which fails instead of fixing — so run the rewriting version yourself first.
- The tests only cover `src/shared/game/`. Anything in `src/client/` or `src/server/` still needs a real check in Roblox Studio.
- **Always test in Studio too** if your change affects anything visual or interactive. Reading the code is not enough to know it looks right.

---

## 5. Commit and open a pull request

```bash
git add <the files you changed>
git commit -m "Short description of what changed"
git push -u origin your-branch-name
```

Write commit messages that say what changed and why — "Fix invisible Play button icon" beats "fix stuff".

Then open a pull request on GitHub (it will offer a "Compare & pull request" button after you push). Fill in the template and **reference the issue** in the description:

```
Closes #29
```

That links them, and merging the PR closes the issue automatically.

### What happens next

1. **CI runs automatically** and shows a green check or a red X on the PR.
2. **If it fails**, click "Details" to see which step broke, fix it locally, then commit and push again — the PR updates itself.
3. **Review the diff yourself** on the Files Changed tab before asking anyone else. You will catch your own mistakes.
4. **Get a review** from the other person on the project.
5. **Merge** once CI is green and the change is approved.
6. **Delete the branch** (GitHub offers a button right after merging).

Then start the next issue from a fresh, updated `master`.

---

## 6. If you get stuck

- Ask on the issue itself — that keeps the context with the work.
- If an issue seems wrong or out of date, say so. Several were written from an automated audit and may need correcting.
- A pull request that is not finished is fine. Open it as a **draft** and ask for input.
