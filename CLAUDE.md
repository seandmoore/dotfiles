# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

`draftworks` is a personal test bench for building experimental or professional projects. It is not a monorepo with a fixed stack — the language, tooling, and structure will vary by project added here.

## Current State

The repository currently contains only a `README.md` and `LICENSE` (GPL v3). There is no established build system, test runner, or language toolchain yet.

## Working in This Repository

When a new project or experiment is added:

- Identify the language and toolchain from the files present (e.g. `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`) before assuming any commands.
- Check for a `Makefile`, `justfile`, or `scripts/` directory for project-specific task runners.
- Look for CI configuration (`.github/workflows/`) to discover canonical build, lint, and test commands.

## License

All code in this repository is under the GNU General Public License v3 (GPL-3.0).
