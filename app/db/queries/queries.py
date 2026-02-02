import inspect
import pathlib
from typing import Any, List

import aiosql

# Check if from_path supports mandatory_parameters (aiosql >= 15.0)
# For Python 3.9 compatibility with aiosql 13.4
sig = inspect.signature(aiosql.from_path)
AIOSQL_HAS_MANDATORY_PARAMS = "mandatory_parameters" in sig.parameters

if AIOSQL_HAS_MANDATORY_PARAMS:
    queries = aiosql.from_path(
        pathlib.Path(__file__).parent / "sql", "asyncpg", mandatory_parameters=False
    )
else:
    queries = aiosql.from_path(pathlib.Path(__file__).parent / "sql", "asyncpg")


async def _execute_query(query_fn: Any, *args: Any, **kwargs: Any) -> List[Any]:
    """
    Execute an aiosql query handling both async generator (aiosql 15.0+)
    and coroutine (aiosql 13.4) return types.

    aiosql 13.4 (Python 3.9): Returns coroutine that yields list
    aiosql 15.0+ with mandatory_parameters=False: Returns async generator
    """
    result = query_fn(*args, **kwargs)

    # Check if it's an async generator (aiosql 15.0+ behavior)
    if hasattr(result, "__aiter__"):
        return [row async for row in result]

    # Otherwise it's a coroutine (aiosql 13.4 behavior)
    return await result
