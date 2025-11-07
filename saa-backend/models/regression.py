"""Implementa a regressão linear baseada na Tabela 6 do estudo."""

INTERCEPTACAO = 0.56
COEF_HORAS = 0.04
COEF_PROJETOS = -0.04
COEF_DISCIPLINAS = 1.51


def calcular_impacto(horas_estudo: float, projetos: int, disciplinas: int) -> float:
    """Calcula o impacto previsto conforme o modelo linear."""

    impacto = (
        INTERCEPTACAO
        + (COEF_HORAS * horas_estudo)
        + (COEF_PROJETOS * projetos)
        + (COEF_DISCIPLINAS * disciplinas)
    )

    return round(impacto, 2)


def calcular_risco(impacto: float) -> str:
    """Classifica o risco acadêmico a partir do impacto previsto."""

    if impacto < 2.0:
        return "ALTO"
    if impacto < 3.5:
        return "MÉDIO"
    return "BAIXO"

