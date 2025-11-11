"""
API de Estudantes - Integrado com banco SQLite
"""

from flask import Blueprint, jsonify, request
import sqlite3
from pathlib import Path
from models.regression import calcular_impacto, calcular_risco
from models.clustering import identificar_perfil

students_bp = Blueprint('students', __name__, url_prefix='/api/estudantes')

DB_PATH = Path(__file__).parent.parent / "data" / "saa.db"


def get_db_connection():
    """Cria conexão com o banco de dados"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row  # Retorna dicts ao invés de tuplas
    return conn


@students_bp.route('/<matricula>/dashboard', methods=['GET'])
def get_dashboard(matricula):
    """
    Retorna dados do dashboard para um estudante específico
    
    GET /api/estudantes/2024025/dashboard
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Busca dados do estudante
        cursor.execute("""
            SELECT e.*, d.horas_estudo, d.participacao_projetos, 
                   d.disciplinas_praticas, d.impacto_percebido, d.data_registro
            FROM estudantes e
            LEFT JOIN dados_academicos d ON e.id = d.estudante_id
            WHERE e.matricula = ?
            ORDER BY d.data_registro DESC
            LIMIT 1
        """, (matricula,))
        
        estudante = cursor.execute.fetchone()
        
        if not estudante:
            return jsonify({"erro": "Estudante não encontrado"}), 404
        
        # Calcula métricas
        horas = estudante['horas_estudo'] or 0
        projetos = estudante['participacao_projetos'] or 0
        disciplinas = estudante['disciplinas_praticas'] or 0
        impacto_real = estudante['impacto_percebido'] or 0
        
        impacto_previsto = calcular_impacto(horas, projetos, disciplinas)
        risco = calcular_risco(impacto_previsto)
        perfil = estudante['perfil'] or identificar_perfil(horas, projetos, disciplinas)
        
        # Busca evolução semanal (últimas 4 semanas)
        cursor.execute("""
            SELECT horas_estudo, impacto_percebido, data_registro
            FROM dados_academicos
            WHERE estudante_id = (SELECT id FROM estudantes WHERE matricula = ?)
            ORDER BY data_registro DESC
            LIMIT 4
        """, (matricula,))
        
        evolucao = [dict(row) for row in cursor.fetchall()]
        evolucao.reverse()  # Mais antigo primeiro
        
        # Busca alertas não lidos
        cursor.execute("""
            SELECT tipo, mensagem, created_at
            FROM alertas
            WHERE estudante_id = (SELECT id FROM estudantes WHERE matricula = ?)
              AND lido = 0
            ORDER BY created_at DESC
        """, (matricula,))
        
        alertas = [dict(row) for row in cursor.fetchall()]
        
        # Calcula comparação com média da turma
        cursor.execute("""
            SELECT AVG(horas_estudo) as media_horas,
                   AVG(participacao_projetos) as media_projetos,
                   AVG(impacto_percebido) as media_impacto
            FROM dados_academicos
        """)
        
        media_turma = dict(cursor.fetchone())
        
        # Calcula percentual vs média
        percentual_horas = ((horas - media_turma['media_horas']) / media_turma['media_horas'] * 100) if media_turma['media_horas'] > 0 else 0
        
        conn.close()
        
        # Monta resposta
        response = {
            "estudante": {
                "matricula": estudante['matricula'],
                "nome": estudante['nome'],
                "email": estudante['email'],
                "perfil": perfil
            },
            "metricas": {
                "horas_semana": round(horas, 1),
                "projetos_ativos": projetos,
                "impacto": round(impacto_real, 1),
                "risco": risco,
                "percentual_vs_media": round(percentual_horas, 0)
            },
            "evolucao_semanal": evolucao,
            "alertas": alertas,
            "comparacao_turma": {
                "media_horas": round(media_turma['media_horas'], 1),
                "media_projetos": round(media_turma['media_projetos'], 1),
                "media_impacto": round(media_turma['media_impacto'], 1)
            }
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@students_bp.route('/<matricula>/atualizar', methods=['POST'])
def atualizar_dados(matricula):
    """
    Atualiza dados acadêmicos de um estudante
    
    POST /api/estudantes/2024025/atualizar
    Body: {
        "horas_estudo": 10,
        "participacao_projetos": 3,
        "disciplinas_praticas": 2,
        "impacto_percebido": 4
    }
    """
    try:
        dados = request.get_json()
        
        horas = float(dados.get('horas_estudo', 0))
        projetos = int(dados.get('participacao_projetos', 0))
        disciplinas = int(dados.get('disciplinas_praticas', 0))
        impacto = float(dados.get('impacto_percebido', 0))
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Busca ID do estudante
        cursor.execute("SELECT id FROM estudantes WHERE matricula = ?", (matricula,))
        result = cursor.fetchone()
        
        if not result:
            return jsonify({"erro": "Estudante não encontrado"}), 404
        
        estudante_id = result['id']
        
        # Insere novos dados acadêmicos
        cursor.execute("""
            INSERT INTO dados_academicos 
            (estudante_id, horas_estudo, participacao_projetos, disciplinas_praticas, 
             impacto_percebido, data_registro)
            VALUES (?, ?, ?, ?, ?, DATE('now'))
        """, (estudante_id, horas, projetos, disciplinas, impacto))
        
        # Atualiza perfil do estudante
        perfil = identificar_perfil(horas, projetos, disciplinas)
        cursor.execute("""
            UPDATE estudantes SET perfil = ? WHERE id = ?
        """, (perfil, estudante_id))
        
        # Verifica se precisa criar alerta
        impacto_previsto = calcular_impacto(horas, projetos, disciplinas)
        risco = calcular_risco(impacto_previsto)
        
        if risco == "ALTO":
            # Verifica se já existe alerta não lido
            cursor.execute("""
                SELECT COUNT(*) as count FROM alertas 
                WHERE estudante_id = ? AND tipo = 'RISCO_ALTO' AND lido = 0
            """, (estudante_id,))
            
            if cursor.fetchone()['count'] == 0:
                mensagem = f"⚠️ Atenção! Seu impacto está em {impacto_previsto:.1f}. Considere aumentar sua participação em projetos."
                cursor.execute("""
                    INSERT INTO alertas (estudante_id, tipo, mensagem, lido)
                    VALUES (?, 'RISCO_ALTO', ?, 0)
                """, (estudante_id, mensagem))
        
        conn.commit()
        conn.close()
        
        return jsonify({
            "sucesso": True,
            "mensagem": "Dados atualizados com sucesso",
            "perfil": perfil,
            "risco": risco
        })
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@students_bp.route('/<matricula>/simulacoes', methods=['GET'])
def get_simulacoes(matricula):
    """
    Retorna histórico de simulações de um estudante
    
    GET /api/estudantes/2024025/simulacoes
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT s.horas_simuladas, s.projetos_simulados, s.disciplinas_simuladas,
                   s.impacto_previsto, s.risco_previsto, s.data_simulacao
            FROM simulacoes s
            JOIN estudantes e ON s.estudante_id = e.id
            WHERE e.matricula = ?
            ORDER BY s.data_simulacao DESC
            LIMIT 10
        """, (matricula,))
        
        simulacoes = [dict(row) for row in cursor.fetchall()]
        conn.close()
        
        return jsonify({
            "matricula": matricula,
            "total": len(simulacoes),
            "simulacoes": simulacoes
        })
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@students_bp.route('/<matricula>/alertas', methods=['GET'])
def get_alertas(matricula):
    """
    Retorna alertas de um estudante
    
    GET /api/estudantes/2024025/alertas?lidos=false
    """
    try:
        apenas_nao_lidos = request.args.get('lidos', 'false').lower() == 'false'
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        query = """
            SELECT a.id, a.tipo, a.mensagem, a.lido, a.created_at
            FROM alertas a
            JOIN estudantes e ON a.estudante_id = e.id
            WHERE e.matricula = ?
        """
        
        if apenas_nao_lidos:
            query += " AND a.lido = 0"
        
        query += " ORDER BY a.created_at DESC"
        
        cursor.execute(query, (matricula,))
        
        alertas = [dict(row) for row in cursor.fetchall()]
        conn.close()
        
        return jsonify({
            "matricula": matricula,
            "total": len(alertas),
            "alertas": alertas
        })
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@students_bp.route('/<matricula>/alertas/<int:alerta_id>/marcar-lido', methods=['PUT'])
def marcar_alerta_lido(matricula, alerta_id):
    """
    Marca um alerta como lido
    
    PUT /api/estudantes/2024025/alertas/1/marcar-lido
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE alertas
            SET lido = 1
            WHERE id = ? 
              AND estudante_id = (SELECT id FROM estudantes WHERE matricula = ?)
        """, (alerta_id, matricula))
        
        conn.commit()
        
        if cursor.rowcount == 0:
            conn.close()
            return jsonify({"erro": "Alerta não encontrado"}), 404
        
        conn.close()
        
        return jsonify({
            "sucesso": True,
            "mensagem": "Alerta marcado como lido"
        })
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500