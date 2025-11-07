"""Script para visualizar dados do banco de dados de forma amigável."""

from database.db import get_connection


def visualizar_estudantes():
    """Mostra todos os estudantes cadastrados."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT e.matricula, e.nome, e.email, e.perfil,
               d.horas_estudo, d.participacao_projetos, d.disciplinas_praticas, d.impacto_percebido
        FROM estudantes e
        JOIN dados_academicos d ON e.id = d.estudante_id
        ORDER BY e.matricula
    """)

    print("\n" + "=" * 100)
    print("ESTUDANTES CADASTRADOS")
    print("=" * 100)
    print(f"{'Matrícula':<12} {'Nome':<25} {'Perfil':<20} {'Horas':<8} {'Proj.':<6} {'Disc.':<6} {'Impacto':<8}")
    print("-" * 100)

    for row in cursor.fetchall():
        matricula, nome, email, perfil, horas, projetos, disciplinas, impacto = row
        print(f"{matricula:<12} {nome:<25} {perfil:<20} {horas:<8.1f} {projetos:<6} {disciplinas:<6} {impacto:<8.2f}")

    conn.close()


def visualizar_alertas():
    """Mostra os alertas gerados."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT e.matricula, e.nome, a.tipo, a.mensagem, a.lido
        FROM alertas a
        JOIN estudantes e ON a.estudante_id = e.id
        ORDER BY a.created_at DESC
    """)

    print("\n" + "=" * 100)
    print("ALERTAS")
    print("=" * 100)
    print(f"{'Matrícula':<12} {'Nome':<25} {'Tipo':<15} {'Lido':<6} {'Mensagem'}")
    print("-" * 100)

    for row in cursor.fetchall():
        matricula, nome, tipo, mensagem, lido = row
        lido_str = "Sim" if lido else "Não"
        print(f"{matricula:<12} {nome:<25} {tipo:<15} {lido_str:<6} {mensagem}")

    conn.close()


def estatisticas():
    """Mostra estatísticas gerais."""
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT COUNT(*) FROM estudantes")
    total_estudantes = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM alertas")
    total_alertas = cursor.fetchone()[0]

    cursor.execute("""
        SELECT perfil, COUNT(*) 
        FROM estudantes 
        GROUP BY perfil
    """)
    perfis = cursor.fetchall()

    cursor.execute("""
        SELECT 
            AVG(horas_estudo) as media_horas,
            AVG(participacao_projetos) as media_projetos,
            AVG(disciplinas_praticas) as media_disciplinas,
            AVG(impacto_percebido) as media_impacto
        FROM dados_academicos
    """)
    medias = cursor.fetchone()

    print("\n" + "=" * 100)
    print("ESTATÍSTICAS GERAIS")
    print("=" * 100)
    print(f"Total de estudantes: {total_estudantes}")
    print(f"Total de alertas: {total_alertas}")
    print("\nDistribuição por perfil:")
    for perfil, count in perfis:
        print(f"  - {perfil}: {count} estudantes")
    
    if medias:
        print(f"\nMédias gerais:")
        print(f"  - Horas de estudo: {medias[0]:.2f}h")
        print(f"  - Projetos: {medias[1]:.2f}")
        print(f"  - Disciplinas práticas: {medias[2]:.2f}")
        print(f"  - Impacto percebido: {medias[3]:.2f}")

    conn.close()


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        comando = sys.argv[1]
        if comando == "estudantes":
            visualizar_estudantes()
        elif comando == "alertas":
            visualizar_alertas()
        elif comando == "stats":
            estatisticas()
        else:
            print("Comandos disponíveis: estudantes, alertas, stats")
    else:
        visualizar_estudantes()
        estatisticas()
        visualizar_alertas()

