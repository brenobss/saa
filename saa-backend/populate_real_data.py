"""
Script para popular o banco de dados com os dados REAIS da pesquisa
Dados do Apêndice C do trabalho de Métodos Quantitativos
"""

import sqlite3
import sys
from pathlib import Path

# Dados reais do Apêndice C
DADOS_REAIS = [
    {"ordem": 25, "horas": 8, "projetos": 2, "impacto": 3, "disciplinas": 2},
    {"ordem": 2, "horas": 3, "projetos": 5, "impacto": 4, "disciplinas": 2},
    {"ordem": 22, "horas": 4, "projetos": 60, "impacto": 3, "disciplinas": 1},
    {"ordem": 35, "horas": 4, "projetos": 2, "impacto": 5, "disciplinas": 1},
    {"ordem": 30, "horas": 2, "projetos": 44, "impacto": 7, "disciplinas": 2},
    {"ordem": 36, "horas": 14, "projetos": 1, "impacto": 5, "disciplinas": 2},
    {"ordem": 1, "horas": 4, "projetos": 0, "impacto": 1, "disciplinas": 3},
    {"ordem": 28, "horas": 3, "projetos": 0, "impacto": 0, "disciplinas": 0},
    {"ordem": 7, "horas": 40, "projetos": 30, "impacto": 1, "disciplinas": 3},
    {"ordem": 13, "horas": 6, "projetos": 0, "impacto": 1, "disciplinas": 1},
    {"ordem": 18, "horas": 8, "projetos": 0, "impacto": 0, "disciplinas": 0},
    {"ordem": 29, "horas": 12, "projetos": 0, "impacto": 0, "disciplinas": 3},
    {"ordem": 32, "horas": 2, "projetos": 7, "impacto": 1, "disciplinas": 1},
    {"ordem": 16, "horas": 4, "projetos": 2, "impacto": 3, "disciplinas": 2},
    {"ordem": 33, "horas": 20, "projetos": 5, "impacto": 5, "disciplinas": 5},
    {"ordem": 19, "horas": 0, "projetos": 8, "impacto": 2, "disciplinas": 0},
    {"ordem": 34, "horas": 4, "projetos": 0, "impacto": 0, "disciplinas": 0},
    {"ordem": 40, "horas": 8, "projetos": 2, "impacto": 3, "disciplinas": 1},
    {"ordem": 39, "horas": 0, "projetos": 3, "impacto": 2, "disciplinas": 0},
    {"ordem": 9, "horas": 20, "projetos": 1, "impacto": 5, "disciplinas": 3},
    {"ordem": 38, "horas": 10, "projetos": 1, "impacto": 1, "disciplinas": 0},
    {"ordem": 14, "horas": 6, "projetos": 0, "impacto": 1, "disciplinas": 6},
    {"ordem": 11, "horas": 3, "projetos": 5, "impacto": 1, "disciplinas": 0},
    {"ordem": 23, "horas": 6, "projetos": 0, "impacto": 1, "disciplinas": 1},
    {"ordem": 5, "horas": 6, "projetos": 5, "impacto": 4, "disciplinas": 3},
    {"ordem": 31, "horas": 30, "projetos": 5, "impacto": 1, "disciplinas": 0},
    {"ordem": 3, "horas": 3, "projetos": 0, "impacto": 1, "disciplinas": 1},
    {"ordem": 17, "horas": 2, "projetos": 1, "impacto": 2, "disciplinas": 2},
    {"ordem": 12, "horas": 3, "projetos": 0, "impacto": 5, "disciplinas": 4},
    {"ordem": 20, "horas": 3, "projetos": 0, "impacto": 4, "disciplinas": 2},
    {"ordem": 10, "horas": 3, "projetos": 5, "impacto": 5, "disciplinas": 3},
    {"ordem": 24, "horas": 2, "projetos": 0, "impacto": 1, "disciplinas": 1},
]


def calcular_impacto_formula(horas, projetos, disciplinas):
    """
    Calcula o impacto usando a fórmula de regressão
    Fórmula da Tabela 6: Impacto = 0.56 + (0.04*horas) + (-0.04*projetos) + (1.51*disciplinas)
    """
    return round(0.56 + (0.04 * horas) + (-0.04 * projetos) + (1.51 * disciplinas), 2)


def calcular_risco(impacto):
    """Classifica o risco baseado no impacto"""
    if impacto < 2.0:
        return "ALTO"
    elif impacto < 3.5:
        return "MÉDIO"
    else:
        return "BAIXO"


def identificar_perfil(horas, projetos, disciplinas):
    """
    Identifica o perfil do estudante baseado nos clusters da pesquisa
    Cluster 0 (Pouco Engajado): baixo estudo, baixa participação
    Cluster 1 (Altamente Prático): alta participação em projetos
    Cluster 2 (Estudioso Dedicado): muitas horas de estudo
    """
    import numpy as np
    
    # Centroides dos 3 perfis (do seu trabalho)
    centroides = np.array([
        [3, 0, 1],   # Pouco Engajado
        [8, 6, 2],   # Altamente Prático
        [20, 2, 3]   # Estudioso Dedicado
    ])
    
    estudante = np.array([horas, projetos, disciplinas])
    distancias = np.linalg.norm(centroides - estudante, axis=1)
    cluster = np.argmin(distancias)
    
    perfis = {
        0: "Pouco Engajado",
        1: "Altamente Prático",
        2: "Estudioso Dedicado"
    }
    
    return perfis[cluster]


def limpar_banco(conn):
    """Limpa todas as tabelas"""
    print("🗑️  Limpando dados antigos...")
    cursor = conn.cursor()
    cursor.execute("DELETE FROM alertas")
    cursor.execute("DELETE FROM simulacoes")
    cursor.execute("DELETE FROM dados_academicos")
    cursor.execute("DELETE FROM estudantes")
    conn.commit()
    print("✅ Dados antigos removidos")


def popular_dados_reais(conn):
    """Popula o banco com os 32 dados reais da pesquisa"""
    cursor = conn.cursor()
    
    print(f"\n📊 Populando com {len(DADOS_REAIS)} estudantes da pesquisa...")
    
    alertas_criados = 0
    distribuicao_perfis = {"Pouco Engajado": 0, "Altamente Prático": 0, "Estudioso Dedicado": 0}
    distribuicao_risco = {"ALTO": 0, "MÉDIO": 0, "BAIXO": 0}
    
    for idx, dados in enumerate(DADOS_REAIS, 1):
        # Dados da pesquisa
        ordem = dados["ordem"]
        horas = dados["horas"]
        projetos = dados["projetos"]
        impacto_real = dados["impacto"]
        disciplinas = dados["disciplinas"]
        
        # Calcula métricas
        perfil = identificar_perfil(horas, projetos, disciplinas)
        impacto_previsto = calcular_impacto_formula(horas, projetos, disciplinas)
        risco = calcular_risco(impacto_previsto)
        
        # Estatísticas
        distribuicao_perfis[perfil] += 1
        distribuicao_risco[risco] += 1
        
        # Cria matrícula baseada na ordem original
        matricula = f"2024{ordem:03d}"
        nome = f"Estudante {ordem}"
        email = f"estudante{ordem}@ufba.br"
        
        # Insere estudante
        cursor.execute("""
            INSERT INTO estudantes (matricula, nome, email, senha_hash, perfil)
            VALUES (?, ?, ?, ?, ?)
        """, (matricula, nome, email, "hash_padrao", perfil))
        
        estudante_id = cursor.lastrowid
        
        # Insere dados acadêmicos
        cursor.execute("""
            INSERT INTO dados_academicos 
            (estudante_id, horas_estudo, participacao_projetos, disciplinas_praticas, 
             impacto_percebido, data_registro)
            VALUES (?, ?, ?, ?, ?, DATE('now'))
        """, (estudante_id, horas, projetos, disciplinas, impacto_real))
        
        # Cria alerta se risco ALTO
        if risco == "ALTO":
            mensagem = f"⚠️ Estudante em risco ALTO! Impacto previsto: {impacto_previsto:.2f}"
            cursor.execute("""
                INSERT INTO alertas (estudante_id, tipo, mensagem, lido)
                VALUES (?, ?, ?, 0)
            """, (estudante_id, "RISCO_ALTO", mensagem))
            alertas_criados += 1
        
        # Progresso
        if idx % 10 == 0:
            print(f"   ✓ {idx}/{len(DADOS_REAIS)} estudantes processados...")
    
    conn.commit()
    
    print(f"\n✅ {len(DADOS_REAIS)} estudantes criados!")
    print(f"✅ {alertas_criados} alertas gerados para estudantes em risco")
    
    print("\n📊 DISTRIBUIÇÃO DE PERFIS:")
    for perfil, count in distribuicao_perfis.items():
        percentual = (count / len(DADOS_REAIS)) * 100
        print(f"   • {perfil}: {count} ({percentual:.1f}%)")
    
    print("\n⚠️  DISTRIBUIÇÃO DE RISCO:")
    for risco, count in distribuicao_risco.items():
        percentual = (count / len(DADOS_REAIS)) * 100
        print(f"   • {risco}: {count} ({percentual:.1f}%)")
    
    # Estatísticas gerais
    horas_media = sum(d["horas"] for d in DADOS_REAIS) / len(DADOS_REAIS)
    projetos_media = sum(d["projetos"] for d in DADOS_REAIS) / len(DADOS_REAIS)
    impacto_medio = sum(d["impacto"] for d in DADOS_REAIS) / len(DADOS_REAIS)
    
    print("\n📈 ESTATÍSTICAS GERAIS:")
    print(f"   • Média de horas de estudo: {horas_media:.2f}h/semana")
    print(f"   • Média de participação em projetos: {projetos_media:.2f}/semana")
    print(f"   • Média de impacto percebido: {impacto_medio:.2f}")


def main():
    # Caminho do banco de dados
    db_path = Path(__file__).parent / "data" / "saa.db"
    
    if not db_path.exists():
        print("❌ Erro: Banco de dados não encontrado!")
        print(f"   Esperado em: {db_path}")
        print("\n💡 Execute primeiro: python init_db.py")
        sys.exit(1)
    
    print("="*60)
    print("🎓 SISTEMA DE APOIO ACADÊMICO (SAA)")
    print("   Populando com DADOS REAIS da pesquisa")
    print("="*60)
    
    try:
        conn = sqlite3.connect(db_path)
        
        # Limpa dados antigos
        limpar_banco(conn)
        
        # Popula com dados reais
        popular_dados_reais(conn)
        
        conn.close()
        
        print("\n" + "="*60)
        print("✅ BANCO DE DADOS POPULADO COM SUCESSO!")
        print("="*60)
        print("\n💡 Próximos passos:")
        print("   1. Execute: python view_db.py")
        print("   2. Execute: python app.py")
        print("   3. Teste: http://127.0.0.1:5000/api/health")
        
    except Exception as e:
        print(f"\n❌ Erro ao popular banco: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()