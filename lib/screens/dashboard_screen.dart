import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:saa/screens/reports_screen.dart';
import 'package:saa/screens/scenario_comparison_screen,dart';
import 'package:saa/screens/simulation_screen.dart';
import 'package:saa/profile_analyzer_widget.dart';
import 'package:saa/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final String matricula;

  const DashboardScreen({super.key, required this.matricula});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDashboard();
  }

  Future<void> _carregarDashboard() async {
    setState(() => isLoading = true);

    final data = await ApiService.getDashboard(widget.matricula);

    setState(() {
      dashboardData = data;
      isLoading = false;
    });

    if (data == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar dados do dashboard'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Extrai valores com fallback seguro
  double get horasEstudo {
    try {
      return (dashboardData?['metricas']?['horas_semana'] ?? 7.6).toDouble();
    } catch (e) {
      return 7.6; // valor padrão da pesquisa
    }
  }

  int get projetos {
    try {
      return (dashboardData?['metricas']?['projetos'] ?? 6).toInt();
    } catch (e) {
      return 6;
    }
  }

  int get disciplinas {
    try {
      return (dashboardData?['metricas']?['disciplinas'] ?? 2).toInt();
    } catch (e) {
      return 2;
    }
  }

  double get impacto {
    try {
      return (dashboardData?['metricas']?['impacto'] ?? 2.4).toDouble();
    } catch (e) {
      return 2.4;
    }
  }

  String get risco {
    try {
      return dashboardData?['metricas']?['risco'] ?? 'Médio';
    } catch (e) {
      return 'Médio';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.school, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'SAA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregarDashboard,
            tooltip: 'Atualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
        ),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Visão geral do seu desempenho acadêmico',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      // Cards de Métricas
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildMetricCard(
                            'Horas/Semana',
                            '${horasEstudo.toStringAsFixed(1)}h',
                            'Acima da mediana (4h)',
                            Icons.schedule,
                            Colors.green,
                          ),
                          _buildMetricCard(
                            'Projetos Ativos',
                            '$projetos',
                            projetos >= 6
                                ? 'Acima da média'
                                : 'Abaixo da média',
                            Icons.work,
                            Colors.blue,
                          ),
                          _buildMetricCard(
                            'Impacto',
                            impacto.toStringAsFixed(1),
                            impacto >= 3.5
                                ? 'Acima da meta'
                                : 'Abaixo da meta (4.0)',
                            Icons.trending_up,
                            Colors.purple,
                          ),
                          _buildMetricCard(
                            'Risco',
                            risco,
                            risco == 'Baixo'
                                ? 'Ótimo!'
                                : risco == 'Médio'
                                ? 'Requer atenção'
                                : 'Atenção urgente',
                            Icons.warning,
                            _getRiscoColor(risco),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ========== WIDGET DE ANÁLISE DE PERFIL (NOVO) ==========
                      ProfileAnalyzerWidget(
                        horasEstudo: horasEstudo,
                        projetos: projetos,
                        disciplinas: disciplinas,
                        impactoAtual: impacto,
                      ),
                      const SizedBox(height: 24),

                      // Gráfico de Evolução
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Evolução Semanal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: true),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (value, meta) {
                                            return Text('S${value.toInt()}');
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: true),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          FlSpot(1, horasEstudo * 0.8),
                                          FlSpot(2, horasEstudo * 0.9),
                                          FlSpot(3, horasEstudo * 0.7),
                                          FlSpot(4, horasEstudo),
                                        ],
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: FlDotData(show: true),
                                      ),
                                      LineChartBarData(
                                        spots: [
                                          FlSpot(1, impacto * 0.7),
                                          FlSpot(2, impacto * 0.85),
                                          FlSpot(3, impacto * 0.65),
                                          FlSpot(4, impacto),
                                        ],
                                        isCurved: true,
                                        color: Colors.purple,
                                        barWidth: 3,
                                        dotData: FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Alertas (se risco for Alto ou Médio)
                      if (risco != 'Baixo')
                        Card(
                          elevation: 4,
                          color: Colors.orange[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.warning,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Alerta: Risco $risco',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        impacto < 2.0
                                            ? 'Seu impacto está ${((4.0 - impacto) / 4.0 * 100).toStringAsFixed(0)}% abaixo da meta.'
                                            : 'Considere usar o simulador para melhorar seu desempenho.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Botões de navegação
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ScenarioComparisonScreen(
                                          matricula: widget.matricula,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.compare_arrows),
                              label: const Text('Comparar\nCenários'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => const SimulationScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Simulador'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assessment),
                          label: const Text('Relatórios Analíticos'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiscoColor(String risco) {
    switch (risco.toLowerCase()) {
      case 'baixo':
        return Colors.green;
      case 'médio':
      case 'medio':
        return Colors.orange;
      case 'alto':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
