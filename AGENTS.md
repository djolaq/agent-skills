# AGENTS.md - repo conventions for agent-skills

This repository is a collection of agent skills. Follow these conventions when adding or
editing skills.

## Adding a new skill
- One directory per skill: `skills/<skill-name>/`.
- Every skill **must** contain a `SKILL.md` file with YAML frontmatter:
  - `name`: lowercase, hyphen-separated, matches the folder name.
  - `description`: what the skill does **and** when to trigger it; front-load trigger
    keywords (e.g. "owasp asvs audit", "security review"). Third person, not "I ...".
- Bundle supporting material inside the skill folder: `references/`, `templates/`,
  `scripts/`. The `SKILL.md` body should stay lean and reference these files, so the
  skill loads cheaply (progressive disclosure).
- Keep every skill **non-destructive by default** unless the user explicitly opts in:
  prefer read-only inspection and clearly document any write operations the skill may do.
- Update the skills table in `README.md`.
- Convention for multiple agents: any content that differs between opencode and
  Claude Code goes in the frontmatter (`compatibility`, `allowed-tools`, etc.); the
  `SKILL.md` body itself must stay tool-agnostic.

## Style
- Write skills in English.
- Use `file:line` evidence conventions and concrete, actionable instructions.
- No emojis in skill files unless requested.
- Do not add code comments unless they carry real information.

## Verification
- After adding/editing a skill, run `./install.sh --copy` into a scratch dir or validate
  the frontmatter parses as YAML and `name` matches the folder name.
- Checklist: `SKILL.md` exists + frontmatter `name`/`description` valid, referenced files
  exist under the skill folder, README table updated.