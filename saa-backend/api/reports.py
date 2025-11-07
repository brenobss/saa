"""Rotas para geração de relatórios."""

from __future__ import annotations

from flask import jsonify

from . import reports_bp


@reports_bp.get("/resumo")
def obter_resumo():
    # TODO: substituir por agregações reais do banco
    return jsonify({
        "total_estudantes": 32,
        "risco_alto": 5,
        "risco_medio": 12,
        "risco_baixo": 15,
    })

