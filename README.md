# agent-skills

A collection of **agent skills** - portable, human-readable instruction packs for AI
coding agents. Each skill lives in its own directory and works with both
**opencode** and **Claude Code** (they share the same `SKILL.md` format).

## Skills

| Skill | Description |
|-------|-------------|
| [audit-owasp-asvs](skills/audit-owasp-asvs) | Non-destructive security audit of a codebase against the official OWASP ASVS v5.0.0 standard; produces a severity-prioritized Markdown report for product owners and security engineers. |

## Installation

Skills are plain directories containing a `SKILL.md`. Install/uninstall to all
supported agent homes with:

```bash
./install.sh            # symlink skills into ~/.claude/skills and ~/.opencode/skills
./install.sh --copy     # copy instead of symlink (for Windows/WSL or portability)
./install.sh --remove   # remove the symlinks/copies
```

Manual install - symlink or copy the skill folder to any of these locations:

```
~/.claude/skills/audit-owasp-asvs    # Claude Code (personal)
.claude/skills/audit-owasp-asvs      # Claude Code (project)
.opencode/skills/audit-owasp-asvs    # opencode (project or ~/.config/opencode/)
```

opencode also auto-loads `~/.claude/skills/*`, so either location covers both agents.

> Restart opencode / Claude Code after installing for the skill to be picked up.

## Usage

Ask the agent to audit a project, e.g.:

- "Run an OWASP ASVS audit on this repo (Level 1) and write the report to `reports/`."
- "Security audit of the auth module only, ASVS L2."
- "ASVS compliance check - show the top risks in chat first."
- "Run the audit in parallel across agents" - splits chapters across multiple read-only
  worker agents and produces a single merged report (see
  `skills/audit-owasp-asvs/references/parallel-audit.md`).

The skill is **non-destructive by design**: it only reads and searches the codebase,
never executes the application, never modifies files, and never contacts the audited
hosts. Its only artefact is the Markdown report it produces.

## Adding a new skill

1. Create a directory: `skills/<your-skill>/`.
2. Add a `SKILL.md` with YAML frontmatter:
   ```markdown
   ---
   name: your-skill
   description: What the skill does AND when to use it (trigger keywords upfront).
   ---
   ```
3. Bundle supporting material (references, templates, scripts) inside the skill folder.
4. Add a row to the table above and open a PR. See `AGENTS.md`.

## License

MIT - see [LICENSE](LICENSE). The bundled OWASP ASVS v5.0.0 requirement reference is
drawn from the official OWASP ASVS project and remains CC BY-SA 4.0
(https://creativecommons.org/licenses/by-sa/4.0/).