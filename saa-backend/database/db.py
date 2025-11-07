"""Funções auxiliares para conexão com SQLite."""

from __future__ import annotations

import sqlite3
from pathlib import Path
from typing import Iterator


BASE_DIR = Path(__file__).resolve().parent.parent
DEFAULT_DB_PATH = BASE_DIR / "data" / "saa.db"


def get_connection(db_path: Path | None = None) -> sqlite3.Connection:
    """Retorna uma conexão com o banco de dados."""

    target = db_path or DEFAULT_DB_PATH
    target.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(target)
    conn.row_factory = sqlite3.Row
    return conn


def iter_rows(cursor: sqlite3.Cursor) -> Iterator[sqlite3.Row]:
    """Itera sobre um cursor convertendo para dict implicitamente."""

    for row in cursor:
        yield row

