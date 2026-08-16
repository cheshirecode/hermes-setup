---
name: code-analysis
description: Perform deep structural code analysis, finding hotspots, dependency graphs, and test gaps across a repository.
---

# Code Analysis Skill

## Purpose
Analyze the target codebase to map architecture, detect untested paths, and suggest high-leverage refactorings.

## Workflow
1. **Discover Structure**: Map top-level modules, entry points, and build manifests (`package.json`, `Cargo.toml`, `pyproject.toml`).
2. **Search Invariants**: Trace critical paths (data flow, auth boundaries, database transactions).
3. **Audit Safety Net**: Evaluate test coverage and CI configs.
4. **Emit Report**: Deliver structured findings with `path:line_number` citations and clear risk ratings.
