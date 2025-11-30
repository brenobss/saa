from flask import Flask, jsonify, request
from flask_cors import CORS

from models.regression import calcular_impacto, calcular_risco
from api import reports_bp, students_bp


def create_app() -> Flask:
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(students_bp)
    app.register_blueprint(reports_bp)

    @app.route("/api/health", methods=["GET"])
    def healthcheck():
        return jsonify({"status": "ok"})

    @app.route("/api", methods=["GET"])
    def api_root():
        # Rota simples para evitar 404 ao acessar o prefixo /api sem recurso
        return jsonify({"status": "ok", "message": "SAA API - raiz"})

    @app.route("/", methods=["GET"])
    def root():
        # Rota raiz para facilitar verificações via navegador
        return jsonify({"status": "ok", "message": "SAA backend is running"})

    @app.route("/api/simular", methods=["POST"])
    def simular_cenario():
        payload = request.get_json(force=True, silent=True) or {}

        horas_estudo = float(payload.get("horas_estudo", 0))
        projetos = int(payload.get("projetos", 0))
        disciplinas = int(payload.get("disciplinas", 0))

        impacto = calcular_impacto(horas_estudo, projetos, disciplinas)
        risco = calcular_risco(impacto)

        return jsonify({
            "impacto_previsto": impacto,
            "risco": risco,
        })

    return app


if __name__ == "__main__":
    # Executa o servidor em modo estável (sem debugger/reloader),
    # para evitar problemas de sandbox/namespace no ambiente.
    create_app().run(
        host="0.0.0.0",
        port=5000,
        debug=False,
        use_reloader=False,
    )

