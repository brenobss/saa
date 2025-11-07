"""Script para inicializar o banco de dados e popular com dados de exemplo."""

from __future__ import annotations

from datetime import date
from pathlib import Path

from werkzeug.security import generate_password_hash

from .db import get_connection

# Caminho do schema SQL
SCHEMA_PATH = Path(__file__).parent / "schema.sql"


def init_database() -> None:
    """Aplica o schema SQL e popula com dados de exemplo."""

    conn = get_connection()
    cursor = conn.cursor()

    # 1. Aplicar schema
    print("📋 Aplicando schema do banco de dados...")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema_sql = f.read()
        cursor.executescript(schema_sql)

    # 2. Limpar dados existentes (para permitir re-execução)
    print("🧹 Limpando dados existentes...")
    cursor.execute("DELETE FROM alertas")
    cursor.execute("DELETE FROM simulacoes")
    cursor.execute("DELETE FROM dados_academicos")
    cursor.execute("DELETE FROM estudantes")

    # 3. Dados de exemplo (32 estudantes com perfis variados)
    print("👥 Criando estudantes de exemplo...")
    estudantes_dados = [
        # Pouco Engajado (perfil 0)
        ("2021001", "Ana Silva", "ana.silva@email.com", 2.5, 0, 1, 1.8),
        ("2021002", "Bruno Costa", "bruno.costa@email.com", 3.0, 0, 1, 2.0),
        ("2021003", "Carlos Santos", "carlos.santos@email.com", 2.0, 1, 1, 1.9),
        ("2021004", "Diana Oliveira", "diana.oliveira@email.com", 3.5, 0, 1, 2.1),
        ("2021005", "Eduardo Lima", "eduardo.lima@email.com", 2.8, 0, 1, 1.95),
        # Altamente Prático (perfil 1)
        ("2021006", "Fernanda Alves", "fernanda.alves@email.com", 8.0, 5, 2, 3.2),
        ("2021007", "Gabriel Rocha", "gabriel.rocha@email.com", 7.5, 6, 2, 3.4),
        ("2021008", "Helena Martins", "helena.martins@email.com", 8.5, 5, 2, 3.3),
        ("2021009", "Igor Ferreira", "igor.ferreira@email.com", 7.0, 7, 2, 3.5),
        ("2021010", "Julia Barbosa", "julia.barbosa@email.com", 8.2, 6, 2, 3.4),
        ("2021011", "Kaio Souza", "kaio.souza@email.com", 9.0, 5, 2, 3.6),
        ("2021012", "Larissa Ribeiro", "larissa.ribeiro@email.com", 7.8, 6, 2, 3.3),
        # Estudioso Dedicado (perfil 2)
        ("2021013", "Marcos Pereira", "marcos.pereira@email.com", 20.0, 2, 3, 4.5),
        ("2021014", "Natália Gomes", "natalia.gomes@email.com", 18.0, 2, 3, 4.3),
        ("2021015", "Otávio Carvalho", "otavio.carvalho@email.com", 22.0, 1, 3, 4.7),
        ("2021016", "Patrícia Mendes", "patricia.mendes@email.com", 19.0, 3, 3, 4.6),
        ("2021017", "Rafael Araújo", "rafael.araujo@email.com", 21.0, 2, 3, 4.8),
        ("2021018", "Sandra Teixeira", "sandra.teixeira@email.com", 20.5, 1, 3, 4.5),
        ("2021019", "Thiago Correia", "thiago.correia@email.com", 19.5, 2, 3, 4.4),
        ("2021020", "Úrsula Dias", "ursula.dias@email.com", 18.5, 3, 3, 4.6),
        # Perfis mistos/intermediários
        ("2021021", "Vitor Monteiro", "vitor.monteiro@email.com", 5.0, 3, 2, 2.8),
        ("2021022", "Wagner Nunes", "wagner.nunes@email.com", 6.0, 4, 2, 3.0),
        ("2021023", "Ximena Lopes", "ximena.lopes@email.com", 4.5, 2, 1, 2.5),
        ("2021024", "Yago Freitas", "yago.freitas@email.com", 10.0, 4, 2, 3.7),
        ("2021025", "Zara Moreira", "zara.moreira@email.com", 12.0, 3, 2, 3.9),
        ("2021026", "Alice Campos", "alice.campos@email.com", 15.0, 2, 3, 4.2),
        ("2021027", "Beto Duarte", "beto.duarte@email.com", 14.0, 3, 2, 4.0),
        ("2021028", "Cecília Ramos", "cecilia.ramos@email.com", 11.0, 5, 2, 3.8),
        ("2021029", "Diego Cardoso", "diego.cardoso@email.com", 13.0, 4, 3, 4.1),
        ("2021030", "Elisa Moura", "elisa.moura@email.com", 16.0, 2, 3, 4.3),
        ("2021031", "Fábio Pinheiro", "fabio.pinheiro@email.com", 9.5, 4, 2, 3.6),
        ("2021032", "Giovana Torres", "giovana.torres@email.com", 17.0, 3, 3, 4.4),
    ]

    # Inserir estudantes e dados acadêmicos
    from models.clustering import identificar_perfil
    from models.regression import calcular_risco

    for matricula, nome, email, horas, projetos, disciplinas, impacto_percebido in estudantes_dados:
        # Hash da senha (padrão: "senha123" para todos os exemplos)
        senha_hash = generate_password_hash("senha123")

        # Identificar perfil
        perfil = identificar_perfil(horas, projetos, disciplinas)

        # Inserir estudante
        cursor.execute(
            """
            INSERT INTO estudantes (matricula, nome, email, senha_hash, perfil)
            VALUES (?, ?, ?, ?, ?)
            """,
            (matricula, nome, email, senha_hash, perfil),
        )

        estudante_id = cursor.lastrowid

        # Inserir dados acadêmicos
        cursor.execute(
            """
            INSERT INTO dados_academicos 
            (estudante_id, horas_estudo, participacao_projetos, disciplinas_praticas, impacto_percebido, data_registro)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (estudante_id, horas, projetos, disciplinas, impacto_percebido, date.today()),
        )

        # Criar alertas para estudantes de risco alto
        risco = calcular_risco(impacto_percebido)
        if risco == "ALTO":
            cursor.execute(
                """
                INSERT INTO alertas (estudante_id, tipo, mensagem)
                VALUES (?, ?, ?)
                """,
                (
                    estudante_id,
                    "RISCO_ALTO",
                    f"Seu impacto acadêmico está baixo ({impacto_percebido}). Considere aumentar horas de estudo ou participar de mais projetos.",
                ),
            )

    conn.commit()
    print(f"✅ {len(estudantes_dados)} estudantes criados com sucesso!")

    # 4. Estatísticas
    cursor.execute("SELECT COUNT(*) FROM estudantes")
    total_estudantes = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM dados_academicos")
    total_dados = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM alertas")
    total_alertas = cursor.fetchone()[0]

    print("\n📊 Estatísticas do banco:")
    print(f"   - Estudantes: {total_estudantes}")
    print(f"   - Dados acadêmicos: {total_dados}")
    print(f"   - Alertas: {total_alertas}")

    conn.close()
    print("\n🎉 Banco de dados inicializado com sucesso!")


if __name__ == "__main__":
    init_database()

