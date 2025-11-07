"""Script executável para inicializar o banco de dados."""

import sys
from pathlib import Path

# Adiciona o diretório do backend ao path
sys.path.insert(0, str(Path(__file__).parent))

from database.init_db import init_database

if __name__ == "__main__":
    init_database()

