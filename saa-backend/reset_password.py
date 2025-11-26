"""Script para resetar a senha de um estudante no banco SQLite do backend.

Uso:
    python reset_password.py <matricula> <nova_senha>

Exemplo:
    python reset_password.py 2024001 123456

O script usa bcrypt para gerar o hash no mesmo formato que a API espera.
"""
from pathlib import Path
import sys
import sqlite3
import bcrypt


def usage_and_exit():
    print("Uso: python reset_password.py <matricula> <nova_senha>")
    sys.exit(1)


def main():
    if len(sys.argv) != 3:
        usage_and_exit()

    matricula = sys.argv[1]
    nova_senha = sys.argv[2]

    repo_root = Path(__file__).resolve().parent
    db_path = repo_root / "data" / "saa.db"

    if not db_path.exists():
        print(f"Erro: banco de dados não encontrado em {db_path}")
        sys.exit(1)

    # Gerar hash com bcrypt
    senha_hash = bcrypt.hashpw(nova_senha.encode(), bcrypt.gensalt()).decode()

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("SELECT id FROM estudantes WHERE matricula = ?", (matricula,))
    row = cursor.fetchone()
    if not row:
        print(f"Estudante com matrícula {matricula} não encontrado.")
        conn.close()
        sys.exit(1)

    cursor.execute("UPDATE estudantes SET senha_hash = ? WHERE matricula = ?", (senha_hash, matricula))
    conn.commit()
    conn.close()

    print(f"Senha atualizada com sucesso para matrícula {matricula}.")


if __name__ == '__main__':
    main()
