Update project documentation to reflect changes on this branch.

1. **CLAUDE.md**: Update to reflect new features, file paths, patterns, design decisions, and any lessons learned. Stay under the 40k character limit (`wc -m CLAUDE.md`). Trim verbose sections if needed to make room.

2. **README.md**: Update if the branch changes affect user-facing documentation — new features, setup steps, configuration, or usage instructions.

3. **docs/ folder** (if it exists): Update any VitePress or documentation site files that cover areas affected by the branch changes. Common files to check:
   - Project structure / file maps
   - Server architecture / routes
   - State management / Redis keys
   - Message protocol
   - Extended features

Base updates on the diff with main: `git diff main...HEAD`