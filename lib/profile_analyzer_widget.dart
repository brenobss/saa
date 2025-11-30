import 'package:flutter/material.dart';
import 'dart:math';

class ProfileAnalyzerWidget extends StatelessWidget {
  final double horasEstudo;
  final int projetos;
  final int disciplinas;
  final double impactoAtual;

  const ProfileAnalyzerWidget({
    super.key,
    required this.horasEstudo,
    required this.projetos,
    required this.disciplinas,
    required this.impactoAtual,
  });

  // Centroides reais da pesquisa (K-Means)
  static const List<Map<String, dynamic>> perfis = [
    {
      'nome': 'Pouco Engajado',
      'emoji': '😴',
      'centroide': [3.0, 0.0, 1.0],
      'cor': Colors.red,
      'risco': 'ALTO',
      'percentual': '21,9%',
      'caracteristicas': [
        'Baixo tempo de estudo',
        'Sem projetos ativos',
        'Poucas disciplinas práticas',
        'Necessita intervenção urgente',
      ],
    },
    {
      'nome': 'Altamente Prático',
      'emoji': '🚀',
      'centroide': [8.0, 6.0, 2.0],
      'cor': Colors.blue,
      'risco': 'MÉDIO',
      'percentual': '40,6%',
      'caracteristicas': [
        'Aprende fazendo',
        'Muitos projetos práticos',
        'Equilíbrio estudo-prática',
        'Maior grupo da turma',
      ],
    },
    {
      'nome': 'Estudioso Dedicado',
      'emoji': '📚',
      'centroide': [20.0, 2.0, 3.0],
      'cor': Colors.green,
      'risco': 'BAIXO',
      'percentual': '37,5%',
      'caracteristicas': [
        'Muitas horas de estudo',
        'Foco teórico intenso',
        'Disciplinas práticas moderadas',
        'Alto desempenho previsto',
      ],
    },
  ];

  double _calcularDistancia(List<double> centroide) {
    // Normalizar para escala 0-1
    double horasNorm = horasEstudo / 40.0;
    double projetosNorm = projetos / 10.0;
    double discNorm = disciplinas / 5.0;

    num soma =
        pow(horasNorm - centroide[0] / 40.0, 2) +
        pow(projetosNorm - centroide[1] / 10.0, 2) +
        pow(discNorm - centroide[2] / 5.0, 2);

    return sqrt(soma);
  }

  Map<String, dynamic> _identificarPerfil() {
    double menorDistancia = double.infinity;
    int perfilMaisProximo = 0;
    List<double> todasDistancias = [];

    for (int i = 0; i < perfis.length; i++) {
      double dist = _calcularDistancia(perfis[i]['centroide'] as List<double>);
      todasDistancias.add(dist);

      if (dist < menorDistancia) {
        menorDistancia = dist;
        perfilMaisProximo = i;
      }
    }

    return {
      'perfil_atual': perfis[perfilMaisProximo],
      'indice': perfilMaisProximo,
      'distancia': menorDistancia,
      'todas_distancias': todasDistancias,
      'confianca': _calcularConfianca(menorDistancia),
    };
  }

  double _calcularConfianca(double distancia) {
    // Quanto menor a distância, maior a confiança
    // Distância 0 = 100% confiança, Distância > 0.5 = 0% confiança
    return max(0, min(100, (1 - distancia * 2) * 100));
  }

  Map<String, dynamic> _calcularMudancaNecessaria(int perfilDestino) {
    final perfilAtual = _identificarPerfil();
    final destino = perfis[perfilDestino];
    final centroideDestino = destino['centroide'] as List<double>;

    return {
      'delta_horas': centroideDestino[0] - horasEstudo,
      'delta_projetos': centroideDestino[1].toInt() - projetos,
      'delta_disciplinas': centroideDestino[2].toInt() - disciplinas,
      'impacto_estimado': _estimarNovoImpacto(
        centroideDestino[0],
        centroideDestino[1].toInt(),
        centroideDestino[2].toInt(),
      ),
    };
  }

  double _estimarNovoImpacto(double horas, int proj, int disc) {
    // Fórmula da regressão linear: 0.56 + 0.04*horas - 0.04*proj + 1.51*disc
    return 0.56 + (0.04 * horas) - (0.04 * proj) + (1.51 * disc);
  }

  @override
  Widget build(BuildContext context) {
    final analise = _identificarPerfil();
    final perfilAtual = analise['perfil_atual'] as Map<String, dynamic>;
    final confianca = analise['confianca'] as double;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Análise do Seu Perfil',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Baseado em K-Means Clustering (Pesquisa IC-UFBA)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 32),

            // Perfil Atual
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (perfilAtual['cor'] as Color).withOpacity(0.1),
                    (perfilAtual['cor'] as Color).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: perfilAtual['cor'] as Color,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        perfilAtual['emoji'],
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Seu Perfil Atual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              perfilAtual['nome'],
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: perfilAtual['cor'],
                              ),
                            ),
                            Text(
                              '${perfilAtual['percentual']} da turma',
                              style: TextStyle(
                                fontSize: 11,
                                color: (perfilAtual['cor'] as Color)
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de Confiança
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Confiança da Classificação',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          Text(
                            '${confianca.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: perfilAtual['cor'],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: confianca / 100,
                          backgroundColor: Colors.grey.shade200,
                          color: perfilAtual['cor'],
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Características
                  ...List.generate(
                    (perfilAtual['caracteristicas'] as List).length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: perfilAtual['cor'],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              perfilAtual['caracteristicas'][index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Badge de Risco
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getRiscoCor(
                        perfilAtual['risco'],
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: _getRiscoCor(perfilAtual['risco']),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Risco ${perfilAtual['risco']}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getRiscoCor(perfilAtual['risco']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Seus Dados
            const Text(
              'Suas Métricas Atuais',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricBadge(
                  '${horasEstudo.toInt()}h',
                  'Estudo/sem',
                  Icons.schedule,
                  Colors.blue,
                ),
                _buildMetricBadge(
                  '$projetos',
                  'Projetos',
                  Icons.work,
                  Colors.purple,
                ),
                _buildMetricBadge(
                  '$disciplinas',
                  'Disciplinas',
                  Icons.book,
                  Colors.orange,
                ),
                _buildMetricBadge(
                  impactoAtual.toStringAsFixed(1),
                  'Impacto',
                  Icons.trending_up,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Comparação com Outros Perfis
            const Text(
              'Como Mudar de Perfil?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Veja o que é necessário para migrar para outros perfis',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Cards de Mudança de Perfil
            ...List.generate(perfis.length, (index) {
              if (index == analise['indice']) return const SizedBox.shrink();

              // Não mostra transição para "Pouco Engajado"
              if (perfis[index]['nome'] == 'Pouco Engajado')
                return const SizedBox.shrink();

              final perfilDestino = perfis[index];
              final mudanca = _calcularMudancaNecessaria(index);

              return _buildTransitionCard(
                perfilDestino: perfilDestino,
                mudanca: mudanca,
                impactoAtual: impactoAtual,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTransitionCard({
    required Map<String, dynamic> perfilDestino,
    required Map<String, dynamic> mudanca,
    required double impactoAtual,
  }) {
    final deltaHoras = mudanca['delta_horas'] as double;
    final deltaProjetos = mudanca['delta_projetos'] as int;
    final deltaDisciplinas = mudanca['delta_disciplinas'] as int;
    final novoImpacto = mudanca['impacto_estimado'] as double;
    final variacaoImpacto = ((novoImpacto - impactoAtual) / impactoAtual * 100)
        .toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Text(
                perfilDestino['emoji'],
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Migrar para: ${perfilDestino['nome']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: perfilDestino['cor'],
                      ),
                    ),
                    Text(
                      'Risco ${perfilDestino['risco']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _getRiscoCor(perfilDestino['risco']),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Mudanças Necessárias
          const Text(
            'Mudanças Necessárias:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (deltaHoras.abs() > 0.5)
            _buildChangeItem(
              deltaHoras > 0 ? Icons.add : Icons.remove,
              '${deltaHoras.abs().toInt()}h de estudo/semana',
              deltaHoras > 0 ? Colors.blue : Colors.orange,
              deltaHoras > 0,
            ),
          if (deltaProjetos != 0)
            _buildChangeItem(
              deltaProjetos > 0 ? Icons.add : Icons.remove,
              '${deltaProjetos.abs()} projeto${deltaProjetos.abs() > 1 ? 's' : ''}',
              deltaProjetos > 0 ? Colors.blue : Colors.orange,
              deltaProjetos > 0,
            ),
          if (deltaDisciplinas != 0)
            _buildChangeItem(
              deltaDisciplinas > 0 ? Icons.add : Icons.remove,
              '${deltaDisciplinas.abs()} disciplina${deltaDisciplinas.abs() > 1 ? 's' : ''} prática${deltaDisciplinas.abs() > 1 ? 's' : ''}',
              deltaDisciplinas > 0 ? Colors.blue : Colors.orange,
              deltaDisciplinas > 0,
            ),

          const SizedBox(height: 12),

          // Resultado Previsto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: perfilDestino['cor'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Impacto Previsto:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      impactoAtual.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      novoImpacto.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: perfilDestino['cor'],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (novoImpacto > impactoAtual
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${novoImpacto > impactoAtual ? '+' : ''}$variacaoImpacto%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              novoImpacto > impactoAtual
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(
    IconData icon,
    String text,
    Color color,
    bool isIncrease,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${isIncrease ? 'Aumentar' : 'Reduzir'} $text',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiscoCor(String risco) {
    switch (risco.toUpperCase()) {
      case 'BAIXO':
        return Colors.green;
      case 'MÉDIO':
      case 'MEDIO':
        return Colors.orange;
      case 'ALTO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
