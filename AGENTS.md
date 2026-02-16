# AI Agents Documentation

This repository is optimized for AI-assisted development using various AI coding agents.

## Supported AI Agents

### Claude Code (claude.ai/code)

Claude Code is Anthropic's official CLI tool for interactive software development with Claude AI.

**Documentation:** See [.claude/CLAUDE.md](.claude/CLAUDE.md) for detailed instructions specific to this project.

**Available Skills:**
- `/review-pr` - Comprehensive pull request review

**Quick Start:**
```bash
# Install Claude Code
npm install -g @anthropic/claude-code

# Start working with Claude
claude
```

### Other AI Agents

This repository can work with various AI coding agents including:

- **GitHub Copilot** - Code completion and suggestions
- **Cursor** - AI-powered code editor
- **Aider** - Terminal-based AI pair programming
- **Continue.dev** - IDE extension for AI coding assistance

## Agent Configuration

AI agent configurations are stored in the `.claude/` directory:

```
.claude/
├── CLAUDE.md           # Project-specific instructions for Claude Code
├── skills/             # Custom skills/commands for AI agents
│   └── review-pr.md    # Pull request review skill
├── context/            # Contextual information for AI agents
│   └── pr-review.md    # PR review guidelines and standards
└── settings.local.json # Local Claude Code settings
```

## Contributing with AI Agents

When using AI agents to contribute to this project:

1. **Read the documentation** - Start with [.claude/CLAUDE.md](.claude/CLAUDE.md)
2. **Follow code standards** - AI agents should respect existing patterns and tooling (uv, Ruff, Hatch)
3. **Run tests** - Always ensure tests pass before submitting PRs: `./scripts/test`
4. **Use linters** - Format code with: `./scripts/format`
5. **Review changes** - AI-generated code should be reviewed for correctness and security

## Best Practices

### For Human Developers Using AI Agents

- Review all AI-generated code before committing
- Verify that tests pass and coverage remains at 100%
- Ensure AI follows the architecture patterns described in `.claude/CLAUDE.md`
- Check that AI agents use the correct tooling (uv, not poetry; Ruff, not Black)

### For AI Agents

AI agents should:
- Read `.claude/CLAUDE.md` for project-specific context
- Follow the established architecture patterns
- Maintain 100% test coverage
- Use the modern Python tooling stack (uv, Ruff, Hatch)
- Respect the repository pattern and dependency injection
- Follow the testing strategy (database requirements, isolation, etc.)

## Getting Help

- **Claude Code**: Use `/help` command or visit https://github.com/anthropics/claude-code
- **Project Questions**: See [.claude/CLAUDE.md](.claude/CLAUDE.md) or README.md
- **Issues**: Report bugs at https://github.com/nsidnev/fastapi-realworld-example-app/issues
