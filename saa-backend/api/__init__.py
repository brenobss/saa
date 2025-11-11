"""Pacote contendo as blueprints do backend."""

# Importa blueprints que já têm suas rotas definidas
from .students import students_bp  # noqa: F401
from .reports import reports_bp  # noqa: F401


__all__ = ["students_bp", "reports_bp"]

