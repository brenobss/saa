"""Funções relacionadas ao agrupamento de perfis estudantis."""

from __future__ import annotations

import numpy as np


DEFAULT_CENTROIDES = np.array(
    [
        [3, 0, 1],   # Pouco Engajado
        [8, 6, 2],   # Altamente Prático
        [20, 2, 3],  # Estudioso Dedicado
    ]
)

PERFIS = {
    0: "Pouco Engajado",
    1: "Altamente Prático",
    2: "Estudioso Dedicado",
}


def identificar_perfil(horas_estudo: float, projetos: int, disciplinas: int) -> str:
    """Retorna o perfil mais próximo usando distância Euclidiana."""

    estudante = np.array([[horas_estudo, projetos, disciplinas]])
    distancias = np.linalg.norm(DEFAULT_CENTROIDES - estudante, axis=1)
    cluster = int(np.argmin(distancias))
    return PERFIS[cluster]

