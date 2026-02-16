# Pull Request Review Skill

This skill enables Claude Code to perform comprehensive pull request reviews for this FastAPI RealWorld project.

## Usage

```bash
# Review a PR by number
/review-pr 123

# Review a PR by URL
/review-pr https://github.com/DataDog/fastapi-realworld-example-app/pull/123

# Review current branch changes
/review-pr
```

## Review Process

When reviewing a pull request, Claude should:

### 1. Fetch PR Information

```bash
# Get PR details
gh pr view <PR_NUMBER> --json title,body,additions,deletions,files,author

# Get PR diff
gh pr diff <PR_NUMBER>

# Get PR checks status
gh pr checks <PR_NUMBER>
```

### 2. Analyze Changes

Review all modified files with focus on:

- **Code Quality**: Style, readability, maintainability
- **Architecture**: Adherence to repository pattern, dependency injection, clean architecture
- **Testing**: Test coverage, test quality, edge cases
- **Security**: SQL injection, XSS, authentication/authorization issues
- **Performance**: Database queries, async patterns, potential bottlenecks
- **Dependencies**: Proper use of dependency injection, avoiding circular dependencies

### 3. Check Against Project Standards

Verify compliance with project requirements:

- **Python Version Support**: Works with Python 3.9-3.14
- **Type Hints**: Proper type annotations throughout
- **Async Patterns**: Correct use of async/await, asyncpg
- **Pydantic Models**: Proper use of RWModel/RWSchema base classes
- **Database**: Repository pattern, no raw SQL in routes
- **Testing**: 100% coverage required, proper test isolation
- **Documentation**: Updated docstrings and comments where needed

### 4. Verify Tests

```bash
# Ensure database is running
docker compose up -d db

# Run test suite
./scripts/test

# Check specific test files if modified
./scripts/test tests/test_api/test_routes/test_<resource>.py
```

### 5. Check Code Quality

```bash
# Run linters
./scripts/lint

# Run formatters (check only, don't fix)
hatch run lint:check
```

### 6. Review Dependencies

If `pyproject.toml` or `uv.lock` was modified:

```bash
# Check for security vulnerabilities
uv pip list | grep -i <package-name>

# Verify dependency is necessary
# Check if it introduces conflicts
```

### 7. Provide Structured Feedback

Format review feedback as:

```markdown
## PR Review: <PR Title>

### Summary
<Brief overview of changes>

### Strengths
- <Positive aspects>
- <Good practices followed>

### Issues Found

#### Critical Issues 🔴
- <Security vulnerabilities>
- <Breaking changes>
- <Test failures>

#### Major Issues 🟡
- <Architecture violations>
- <Missing tests>
- <Performance concerns>

#### Minor Issues 🔵
- <Style issues>
- <Documentation gaps>
- <Code quality improvements>

### Recommendations
1. <Specific actionable recommendations>
2. <Suggested improvements>

### Test Results
- Coverage: <percentage>
- Tests passed: <count>
- Tests failed: <count>

### Checklist
- [ ] Architecture patterns followed
- [ ] 100% test coverage maintained
- [ ] Type hints present
- [ ] Security reviewed
- [ ] Documentation updated
- [ ] Works with Python 3.9-3.14
- [ ] Migration needed? (if db changes)
```

## Context Files

When reviewing PRs, also reference:
- `.claude/context/pr-review.md` - Detailed review guidelines
- `.claude/CLAUDE.md` - Project architecture and patterns

## Examples

### Example 1: Review new feature PR

```bash
# Fetch PR
gh pr view 123

# Check diff
gh pr diff 123

# Review files
<Read modified files>

# Run tests
docker compose up -d db
./scripts/test

# Provide feedback
<Structured review>
```

### Example 2: Review bug fix PR

```bash
# Get PR info
gh pr view 456

# Check what bug is being fixed
<Read issue linked in PR>

# Review fix implementation
<Check if fix addresses root cause>

# Verify tests
<Ensure bug is covered by tests>

# Check for regressions
./scripts/test
```

## Automation

The review process can be automated using GitHub CLI:

```bash
#!/bin/bash
# Automated PR review script

PR_NUMBER=$1

# Fetch PR
gh pr view $PR_NUMBER

# Checkout PR branch
gh pr checkout $PR_NUMBER

# Run tests
docker compose up -d db
./scripts/test

# Run linters
./scripts/lint

# Generate review
# <Claude analyzes changes and provides feedback>
```

## Notes

- Always be constructive and specific in feedback
- Suggest code improvements with examples
- Point to relevant documentation and patterns
- Acknowledge good practices
- Prioritize security and correctness over style
- Consider backward compatibility
- Check for proper error handling
- Verify async patterns are correct
