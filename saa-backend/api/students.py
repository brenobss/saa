"""Rotas relacionadas aos estudantes."""

from __future__ import annotations

from flask import jsonify, request

from . import students_bp


@students_bp.get("/<matricula>/dashboard")
def obter_dashboard(matricula: str):
    # TODO: integrar com banco e cálculos reais
    return jsonify({
        "matricula": matricula,
        "impacto_atual": 3.2,
        "risco": "MÉDIO",
    })


@students_bp.post("/")
def criar_estudante():
    # TODO: implementar criação real no banco
    payload = request.get_json(force=True, silent=True) or {}
    return jsonify({"status": "criado", "payload": payload}), 201

