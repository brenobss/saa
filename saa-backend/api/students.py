"""
API de Estudantes - Integrado com banco de dados real
"""

from flask import Blueprint, jsonify, request
import sqlite3
from pathlib import Path
import bcrypt

# Importações de modelos
try:
    from models.regression import calcular_impacto, calcular_risco
    from models.clustering import identificar_perfil
except ImportError as e:
    print(f"⚠️ Erro ao importar modelos: {e}")
    # Funções fallback simples
    def calcular_impacto(h, p, d):
        return round(0.56 + (0.04 * h) + (-0.04 * p) + (1.51 * d), 2)
    
    def calcular_risco(impacto):
        return "ALTO" if impacto < 2.0 else ("MÉDIO" if impacto < 3.5 else "BAIXO")
    
    def identificar_perfil(h, p, d):
        return "Altamente Prático"  # Padrão


students_bp = Blueprint('students', __name__, url_prefix='/api/estudantes')

DB_PATH = Path(__file__).parent.parent / "data" / "saa.db"


def get_db_connection():
    """Cria conexão com o banco de dados"""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def hash_password(password: str) -> str:
    """Hash uma senha usando bcrypt"""
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, password_hash: str) -> bool:
    """Verifica se uma senha corresponde ao hash"""
    try:
        return bcrypt.checkpw(password.encode(), password_hash.encode())
    except:
        return False


@students_bp.route('/login', methods=['POST'])
def login():
    """
    Autentica um estudante
    POST /api/estudantes/login
    Body: {"matricula": "2024001", "senha": "123456"}
    """
    try:
        data = request.get_json()
        matricula = data.get('matricula')
        senha = data.get('senha')
        
        if not matricula or not senha:
            return jsonify({"sucesso": False, "erro": "Matrícula e senha obrigatórias"}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM estudantes WHERE matricula = ?", (matricula,))
        estudante = cursor.fetchone()
        conn.close()
        
        if not estudante:
            return jsonify({"sucesso": False, "erro": "Estudante não encontrado"}), 401
        
        # Verificar senha
        if not verify_password(senha, estudante['senha_hash']):
            return jsonify({"sucesso": False, "erro": "Senha incorreta"}), 401
        
        # Login bem-sucedido
        return jsonify({
            "sucesso": True,
            "matricula": estudante['matricula'],
            "nome": estudante['nome'],
            "email": estudante['email'],
            "perfil": estudante['perfil']
        }), 200
        
    except Exception as e:
        return jsonify({"sucesso": False, "erro": str(e)}), 500


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
        
        estudante = cursor.fetchone()
        
        if not estudante:
            conn.close()
            return jsonify({"erro": "Estudante não encontrado"}), 404
        
        # Calcula métricas
        horas = estudante['horas_estudo'] or 0
        projetos = estudante['participacao_projetos'] or 0
        disciplinas = estudante['disciplinas_praticas'] or 0
        impacto_real = estudante['impacto_percebido'] or 0
        
        impacto_previsto = calcular_impacto(horas, projetos, disciplinas)
        risco = calcular_risco(impacto_previsto)
        perfil = estudante['perfil'] or identificar_perfil(horas, projetos, disciplinas)
        
        # Busca média da turma
        cursor.execute("""
            SELECT AVG(horas_estudo) as media_horas
            FROM dados_academicos
        """)
        
        media_turma = cursor.fetchone()
        media_horas = media_turma['media_horas'] or 0
        
        percentual_horas = 0
        if media_horas > 0:
            percentual_horas = ((horas - media_horas) / media_horas * 100)
        
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
            }
        }
        
        return jsonify(response)
        
    except Exception as e:
        return jsonify({"erro": str(e)}), 500


@students_bp.route('/<matricula>/atualizar', methods=['POST'])
def atualizar_dados(matricula):
    """
    Atualiza dados acadêmicos do estudante
    POST /api/estudantes/2024001/atualizar
    Body: {
        "horas_estudo": 10.5,
        "participacao_projetos": 3,
        "disciplinas_praticas": 2,
        "impacto_percebido": 4.2
    }
    """
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Buscar ID do estudante
        cursor.execute("SELECT id FROM estudantes WHERE matricula = ?", (matricula,))
        estudante = cursor.fetchone()
        
        if not estudante:
            conn.close()
            return jsonify({"sucesso": False, "erro": "Estudante não encontrado"}), 404
        
        # Inserir novo registro
        cursor.execute("""
            INSERT INTO dados_academicos 
            (estudante_id, horas_estudo, participacao_projetos, disciplinas_praticas, impacto_percebido, data_registro)
            VALUES (?, ?, ?, ?, ?, DATE('now'))
        """, (
            estudante['id'],
            data.get('horas_estudo', 0),
            data.get('participacao_projetos', 0),
            data.get('disciplinas_praticas', 0),
            data.get('impacto_percebido', 0)
        ))
        
        conn.commit()
        conn.close()
        
        return jsonify({"sucesso": True, "mensagem": "Dados atualizados com sucesso"}), 200
        
    except Exception as e:
        return jsonify({"sucesso": False, "erro": str(e)}), 500