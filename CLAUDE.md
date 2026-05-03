# draftworks

Personal test bench for building things — professional projects, experiments, and side work.

## Repository Layout

Projects live in their own top-level directories. Each project is self-contained and may use any language or toolchain.

```
draftworks/
├── CLAUDE.md           ← you are here
├── README.md
├── LICENSE
└── <project-name>/     ← one directory per project
    ├── README.md
    └── ...
```

## Working in This Repo

- New projects go in their own directory at the root level.
- Each project manages its own dependencies and build tooling.
- There is no shared build system — run commands from within the project directory.

## Common Tasks

### Start a new project
Create a directory and add a `README.md` describing what it does.

### Run tests
Tests are project-specific. Check the project's `README.md` for instructions.

## Notes for Claude

- This is a personal repo — prefer clear, readable code over heavy abstraction.
- Experiments are allowed to be incomplete; just note their status in the project README.
- Ask before adding dependencies at the root level.
