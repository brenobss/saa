import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double horasEstudo = 10;
  double projetos = 2;
  int disciplinas = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulador de Cenários')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simulador de Cenários',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Simule diferentes estratégias de estudo',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Controles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configurar Cenário',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Slider Horas
                    Text('Horas de Estudo/Semana: ${horasEstudo.toInt()}h'),
                    Slider(
                      value: horasEstudo,
                      min: 0,
                      max: 40,
                      divisions: 40,
                      onChanged: (value) {
                        setState(() {
                          horasEstudo = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Slider Projetos
                    Text('Projetos/Semana: ${projetos.toInt()}'),
                    Slider(
                      value: projetos,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      onChanged: (value) {
                        setState(() {
                          projetos = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Disciplinas
                    const Text('Disciplinas Práticas'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: disciplinas,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items:
                          [1, 2, 3, 4].map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(
                                '$value disciplina${value > 1 ? 's' : ''}',
                              ),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          disciplinas = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botão Simular
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Simular'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Resultados
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultados Previstos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 100,
                          barGroups: [
                            _makeBarGroup(0, 2.4, 65),
                            _makeBarGroup(1, 3.2, 45),
                            _makeBarGroup(2, 4.1, 25),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const titles = ['Atual', '10h', '15h+proj'];
                                  return Text(
                                    titles[value.toInt()],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cards de métricas previstas
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.green[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Impacto Previsto',
                            style: TextStyle(fontSize: 12),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '4.1',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '↑ 70%',
                            style: TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.blue[50],
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('Redução Risco', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 8),
                          Text(
                            '40%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Médio→Baixo',
                            style: TextStyle(fontSize: 10, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double impacto, double risco) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: impacto * 10, color: Colors.blue, width: 15),
        BarChartRodData(toY: risco.toDouble(), color: Colors.orange, width: 15),
      ],
    );
  }
}
