import hashlib

import bcrypt


def generate_salt() -> str:
    return bcrypt.gensalt().decode()


def _prepare(password: str) -> bytes:
    return hashlib.sha256(password.encode()).digest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(_prepare(plain_password), hashed_password.encode())


def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(_prepare(password), bcrypt.gensalt()).decode()
