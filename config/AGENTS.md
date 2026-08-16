# AGENTS.md - Multi-Agent Workspace Guidelines

## Agent Roles & Delegation Guidelines

When managing complex multi-step pipelines or parallel tasks, Hermes Agent delegates to specialized subagents:

### 1. Research & Exploration
- **Focus**: Fast repo search, API indexing, documentation parsing, prior-art review.
- **Model Recommendation**: Fast, low-cost long-context model (`openrouter/qwen/qwen3.7-flash` or `openrouter/deepseek/deepseek-v4-flash`).
- **Mode**: Read-only inspection.

### 2. Implementation & Patching
- **Focus**: Targeted code editing, bug fixing, test authorship, and feature implementation.
- **Model Recommendation**: Balanced coding model (`openrouter/google/gemini-3.7-flash` or `openrouter/z-ai/glm-5.2`).
- **Verification**: Run unit/integration tests before returning.

### 3. Review & Security Audit
- **Focus**: Pre-commit diff audit, security invariant verification, static analysis check.
- **Model Recommendation**: Strict reasoning model (`openrouter/moonshotai/kimi-k2.7-code` or `openrouter/qwen/qwen3.7-plus`).
- **Output**: APPROVE or minimal blocking items with `file_path:line_number`.
