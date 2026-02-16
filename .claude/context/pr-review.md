# Pull Request Review Context

This document provides comprehensive context for reviewing pull requests in the FastAPI RealWorld project.

## Code Quality Standards

### Python Style

- **Type Hints**: All functions must have type hints for parameters and return values
- **Docstrings**: Public APIs should have docstrings following Google style
- **Naming**: Follow PEP 8 conventions (snake_case for functions/variables, PascalCase for classes)
- **Line Length**: Max 88 characters (Ruff default)
- **Imports**: Organized automatically by Ruff (stdlib, third-party, local)

### Architecture Patterns

#### Repository Pattern
```python
# ✅ Good: Use repository pattern
async def get_article(
    slug: str,
    articles_repo: ArticlesRepository = Depends(get_repository(ArticlesRepository)),
) -> Article:
    return await articles_repo.get_article_by_slug(slug=slug)

# ❌ Bad: Raw SQL in routes
async def get_article(slug: str, conn: Connection = Depends(get_connection)):
    query = "SELECT * FROM articles WHERE slug = $1"
    row = await conn.fetchrow(query, slug)
```

#### Dependency Injection
```python
# ✅ Good: Use FastAPI dependency injection
@router.get("/articles/{slug}")
async def get_article(
    slug: str,
    articles_repo: ArticlesRepository = Depends(get_repository(ArticlesRepository)),
    user: Optional[User] = Depends(get_current_user_optional),
):
    ...

# ❌ Bad: Create dependencies manually
@router.get("/articles/{slug}")
async def get_article(slug: str):
    pool = await create_pool()
    conn = await pool.acquire()
    articles_repo = ArticlesRepository(conn)
    ...
```

#### Model Inheritance
```python
# ✅ Good: Use RWModel/RWSchema base classes
class ArticleInResponse(RWSchema):
    article: Article

# ❌ Bad: Direct Pydantic BaseModel
class ArticleInResponse(BaseModel):
    article: Article

    class Config:
        from_attributes = True
```

### Async Patterns

#### Correct Async Usage
```python
# ✅ Good: Proper async/await
async def create_article(
    article_create: ArticleInCreate,
    articles_repo: ArticlesRepository,
) -> Article:
    return await articles_repo.create_article(
        slug=slug,
        title=article_create.title,
        ...
    )

# ❌ Bad: Missing await
async def create_article(...) -> Article:
    return articles_repo.create_article(...)  # Missing await!

# ❌ Bad: Sync function in async context
def create_article(...) -> Article:  # Should be async
    return await articles_repo.create_article(...)
```

#### Database Connections
```python
# ✅ Good: Use dependency injection for connections
async def handler(
    articles_repo: ArticlesRepository = Depends(get_repository(ArticlesRepository)),
):
    ...

# ❌ Bad: Manual connection management
async def handler():
    conn = await pool.acquire()
    try:
        ...
    finally:
        await pool.release(conn)
```

## Testing Requirements

### Coverage

- **Target**: 100% code coverage (strictly enforced)
- **No Exceptions**: All new code must be covered
- **Command**: `./scripts/test` checks coverage automatically

### Test Structure

```python
# ✅ Good: Comprehensive test with clear assertions
@pytest.mark.asyncio
async def test_user_can_create_article(
    app: FastAPI,
    authorized_client: AsyncClient,
    test_user: User,
) -> None:
    article_data = {
        "article": {
            "title": "Test Article",
            "description": "Test Description",
            "body": "Test Body",
            "tagList": ["test", "article"],
        }
    }

    response = await authorized_client.post(
        app.url_path_for("articles:create-article"),
        json=article_data,
    )

    assert response.status_code == status.HTTP_201_CREATED
    article = response.json()["article"]
    assert article["title"] == article_data["article"]["title"]
    assert article["author"]["username"] == test_user.username

# ❌ Bad: Incomplete test
async def test_create_article(authorized_client):
    response = await authorized_client.post("/api/articles", json={...})
    assert response.status_code == 201  # No other assertions!
```

### Test Isolation

```python
# ✅ Good: Tests use fixtures for clean state
@pytest.fixture
async def test_article(
    pool: FakeAsyncPGPool,
    test_user: User,
) -> Article:
    async with pool.acquire() as conn:
        articles_repo = ArticlesRepository(conn)
        return await articles_repo.create_article(...)

# ❌ Bad: Tests depend on each other
async def test_create_then_update():
    # Creates article
    article = await create_article(...)
    # Updates it
    updated = await update_article(article.id, ...)
    # Next test will fail if this article exists!
```

### Edge Cases

Always test:
- **Empty inputs**: `""`, `[]`, `{}`
- **Null values**: `None`, optional fields
- **Boundary values**: max length, min values
- **Error cases**: 400, 401, 403, 404, 422 responses
- **Concurrent operations**: Race conditions
- **Database constraints**: Unique violations, foreign keys

## Security Checklist

### Authentication & Authorization

```python
# ✅ Good: Proper authentication dependency
@router.delete("/articles/{slug}")
async def delete_article(
    slug: str,
    user: User = Depends(get_current_user_required),  # Required auth
    articles_repo: ArticlesRepository = Depends(get_repository(ArticlesRepository)),
):
    article = await articles_repo.get_article_by_slug(slug=slug)
    if article.author_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
    ...

# ❌ Bad: Missing authorization check
@router.delete("/articles/{slug}")
async def delete_article(
    slug: str,
    user: User = Depends(get_current_user_required),
    articles_repo: ArticlesRepository = Depends(get_repository(ArticlesRepository)),
):
    # No check if user owns the article!
    await articles_repo.delete_article(slug=slug)
```

### SQL Injection

```python
# ✅ Good: Parameterized queries
query = "SELECT * FROM articles WHERE slug = $1"
row = await conn.fetchrow(query, slug)

# ✅ Good: PyPika query builder
query = (
    Query.from_(ARTICLES_TABLE)
    .select("*")
    .where(ARTICLES_TABLE.slug == Parameter("$1"))
)

# ❌ Bad: String formatting
query = f"SELECT * FROM articles WHERE slug = '{slug}'"
row = await conn.fetchrow(query)
```

### Password Handling

```python
# ✅ Good: Use password hashing service
from app.services.security import verify_password, generate_salt, get_password_hash

hashed_password = get_password_hash(salt + password)

# ❌ Bad: Plain text passwords
user.password = password  # Never store plain text!
```

### JWT Tokens

```python
# ✅ Good: Use JWT service with proper validation
from app.services.jwt import create_access_token, get_username_from_token

token = create_access_token(user.username)
username = get_username_from_token(token)  # Validates signature

# ❌ Bad: Manual token creation
import jwt
token = jwt.encode({"username": username}, "secret")  # No expiry!
```

## Performance Considerations

### Database Queries

```python
# ✅ Good: Efficient single query
async def get_article_with_author(slug: str) -> Article:
    query = """
        SELECT a.*, u.username, u.email, u.bio, u.image
        FROM articles a
        JOIN users u ON a.author_id = u.id
        WHERE a.slug = $1
    """
    row = await conn.fetchrow(query, slug)

# ❌ Bad: N+1 queries
async def get_article_with_author(slug: str) -> Article:
    article = await get_article(slug)  # Query 1
    author = await get_user(article.author_id)  # Query 2
```

### Async Optimization

```python
# ✅ Good: Concurrent operations
async def get_article_with_counts(slug: str):
    article, favorites_count, comments_count = await asyncio.gather(
        get_article(slug),
        count_favorites(slug),
        count_comments(slug),
    )

# ❌ Bad: Sequential operations
async def get_article_with_counts(slug: str):
    article = await get_article(slug)
    favorites_count = await count_favorites(slug)
    comments_count = await count_comments(slug)
```

## Common Issues

### Issue: Missing Type Hints

```python
# ❌ Bad
async def get_article(slug):
    return await articles_repo.get_article_by_slug(slug)

# ✅ Good
async def get_article(slug: str) -> Article:
    return await articles_repo.get_article_by_slug(slug=slug)
```

### Issue: Not Using Optional for Nullable Fields

```python
# ❌ Bad
class User(RWModel):
    bio: str  # Could be None
    image: str  # Could be None

# ✅ Good
class User(RWModel):
    bio: Optional[str] = None
    image: Optional[str] = None
```

### Issue: Incorrect Exception Handling

```python
# ❌ Bad: Swallowing exceptions
try:
    article = await articles_repo.get_article_by_slug(slug=slug)
except Exception:
    pass  # Silent failure!

# ✅ Good: Proper error handling
try:
    article = await articles_repo.get_article_by_slug(slug=slug)
except EntityDoesNotExist:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=strings.ARTICLE_DOES_NOT_EXIST_ERROR,
    )
```

### Issue: Using Old Tooling

```python
# ❌ Bad: Old tooling references
# poetry add requests
# black app/
# isort app/

# ✅ Good: Modern tooling
# uv add requests
# ./scripts/format  (uses Ruff)
```

## Migration Guidelines

### Database Migrations

If PR includes schema changes:

```bash
# Create migration
alembic revision -m "add_favorites_table"

# Review migration
# - Check upgrade() and downgrade() functions
# - Verify data migrations are safe
# - Test on clean database
# - Test rollback

# Test migration
docker compose up -d db
alembic upgrade head
./scripts/test
alembic downgrade -1
alembic upgrade head
```

### Dependency Changes

If `pyproject.toml` or `uv.lock` changed:

```bash
# Verify lock file is up to date
uv lock --check

# Check for security issues
# (manual review of new dependencies)

# Test with new dependencies
uv sync
./scripts/test
```

## Review Priorities

### Critical (Must Fix Before Merge)

1. Security vulnerabilities
2. Test coverage below 100%
3. Breaking changes without migration path
4. Data loss risks
5. Authentication/authorization bypasses

### High Priority (Should Fix)

1. Architecture pattern violations
2. Performance issues (N+1 queries, blocking I/O)
3. Missing error handling
4. Type hint violations
5. Incorrect async patterns

### Medium Priority (Should Consider)

1. Code duplication
2. Missing docstrings for public APIs
3. Inconsistent naming
4. Incomplete test coverage of edge cases
5. Documentation updates needed

### Low Priority (Nice to Have)

1. Minor style inconsistencies
2. Code comments for complex logic
3. Refactoring opportunities
4. Additional test cases for robustness

## Helpful Commands

```bash
# Review PR
gh pr view <PR_NUMBER>
gh pr diff <PR_NUMBER>
gh pr checks <PR_NUMBER>

# Test PR
gh pr checkout <PR_NUMBER>
docker compose up -d db
./scripts/test
./scripts/lint

# Compare with main
git diff main...HEAD
git log main..HEAD

# Check specific files
./scripts/test tests/test_api/test_routes/test_articles.py
```

## References

- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/)
- [Async Python Patterns](https://docs.python.org/3/library/asyncio.html)
- [PEP 8 Style Guide](https://peps.python.org/pep-0008/)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
