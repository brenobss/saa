"""Pacote contendo as blueprints do backend."""

from flask import Blueprint

students_bp = Blueprint("students", __name__, url_prefix="/api/estudantes")
reports_bp = Blueprint("reports", __name__, url_prefix="/api/relatorios")


# Importa rotas para realizar o binding ao blueprint.
from . import reports, students  # noqa: E402


__all__ = ["students_bp", "reports_bp"]

