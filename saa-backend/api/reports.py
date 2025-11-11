"""Rotas para geração de relatórios."""

from __future__ import annotations

from flask import Blueprint, jsonify
import sqlite3
from pathlib import Path

reports_bp = Blueprint("reports", __name__, url_prefix="/api/relatorios")

DB_PATH = Path(__file__).parent.parent / "data" / "saa.db"


def get_db_connection():
    """Cria conexão com o banco de dados"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


@reports_bp.get("/resumo")
def obter_resumo():
    """Retorna resumo geral de riscos com dados reais do banco"""
    try:
        from models.regression import calcular_risco, calcular_impacto
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Total de estudantes
        cursor.execute("SELECT COUNT(*) as total FROM estudantes")
        total_result = cursor.fetchone()
        total = total_result['total'] if total_result else 0
        
        # Calcular riscos para cada estudante
        cursor.execute("""
            SELECT e.id, MAX(d.data_registro) as ultima_data
            FROM estudantes e
            LEFT JOIN dados_academicos d ON e.id = d.estudante_id
            GROUP BY e.id
        """)
        
        estudantes = cursor.fetchall()
        riscos = {"ALTO": 0, "MÉDIO": 0, "BAIXO": 0}
        
        for estudante in estudantes:
            cursor.execute("""
                SELECT horas_estudo, participacao_projetos, disciplinas_praticas
                FROM dados_academicos
                WHERE estudante_id = ? AND data_registro = ?
                LIMIT 1
            """, (estudante['id'], estudante['ultima_data']))
            
            dados = cursor.fetchone()
            
            if dados:
                horas = dados['horas_estudo'] or 0
                projetos = dados['participacao_projetos'] or 0
                disciplinas = dados['disciplinas_praticas'] or 0
                
                impacto = calcular_impacto(horas, projetos, disciplinas)
                risco = calcular_risco(impacto)
                
                if risco in riscos:
                    riscos[risco] += 1
        
        conn.close()
        
        return jsonify({
            "total_estudantes": total,
            "risco_alto": riscos.get("ALTO", 0),
            "risco_medio": riscos.get("MÉDIO", 0),
            "risco_baixo": riscos.get("BAIXO", 0),
        })
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500

