// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Mude para o IP da sua máquina se testar em dispositivo físico
  static const String baseUrl = 'http://127.0.0.1:5000/api';

  // ============= AUTENTICAÇÃO =============

  static Future<Map<String, dynamic>?> login(
    String matricula,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estudantes/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'matricula': matricula, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro no login: $e');
      return null;
    }
  }

  // ============= DASHBOARD =============

  static Future<Map<String, dynamic>?> getDashboard(String matricula) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estudantes/$matricula/dashboard'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar dashboard: $e');
      return null;
    }
  }

  // ============= SIMULAÇÃO =============

  static Future<Map<String, dynamic>?> simularCenario({
    required double horasEstudo,
    required int projetos,
    required int disciplinas,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/simular'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'horas_estudo': horasEstudo,
          'projetos': projetos,
          'disciplinas': disciplinas,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro ao simular cenário: $e');
      return null;
    }
  }

  // ============= ATUALIZAR DADOS =============

  static Future<bool> atualizarDados({
    required String matricula,
    required double horasEstudo,
    required int projetos,
    required int disciplinas,
    required double impacto,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estudantes/$matricula/atualizar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'horas_estudo': horasEstudo,
          'participacao_projetos': projetos,
          'disciplinas_praticas': disciplinas,
          'impacto_percebido': impacto,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao atualizar dados: $e');
      return false;
    }
  }

  // ============= ALERTAS =============

  static Future<List<dynamic>> getAlertas(
    String matricula, {
    bool apenasNaoLidos = true,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/estudantes/$matricula/alertas?lidos=${!apenasNaoLidos}',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['alertas'] ?? [];
      }
      return [];
    } catch (e) {
      print('Erro ao buscar alertas: $e');
      return [];
    }
  }

  static Future<bool> marcarAlertaLido(String matricula, int alertaId) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$baseUrl/estudantes/$matricula/alertas/$alertaId/marcar-lido',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao marcar alerta como lido: $e');
      return false;
    }
  }

  // ============= RELATÓRIOS (COORDENADOR) =============

  static Future<Map<String, dynamic>?> getRelatorioTurma() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/relatorios/resumo'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar relatório: $e');
      return null;
    }
  }

  static Future<List<dynamic>> getEstudantesEmRisco() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/relatorios/estudantes-risco'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['estudantes'] ?? [];
      }
      return [];
    } catch (e) {
      print('Erro ao buscar estudantes em risco: $e');
      return [];
    }
  }

  // ============= HEALTH CHECK =============

  static Future<bool> verificarConexao() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend não está respondendo: $e');
      return false;
    }
  }
}


// ============= EXEMPLO DE USO NO WIDGET =============

/*

// No Dashboard Screen:
class DashboardScreen extends StatefulWidget {
  final String matricula;
  
  const DashboardScreen({required this.matricula, Key? key}) : super(key: key);
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    carregarDashboard();
  }
  
  Future<void> carregarDashboard() async {
    setState(() => isLoading = true);
    
    final data = await ApiService.getDashboard(widget.matricula);
    
    setState(() {
      dashboardData = data;
      isLoading = false;
    });
    
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao carregar dados')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (dashboardData == null) {
      return const Center(child: Text('Erro ao carregar'));
    }
    
    final metricas = dashboardData!['metricas'];
    
    return Scaffold(
      body: Column(
        children: [
          Text('Horas/Semana: ${metricas['horas_semana']}'),
          Text('Risco: ${metricas['risco']}'),
          // ... resto do layout
        ],
      ),
    );
  }
}


// No Simulation Screen:
ElevatedButton(
  onPressed: () async {
    final resultado = await ApiService.simularCenario(
      horasEstudo: horasEstudo,
      projetos: projetosSemana.toInt(),
      disciplinas: disciplinas,
    );
    
    if (resultado != null) {
      setState(() {
        impactoPrevisto = resultado['impacto_previsto'];
        riscoPrevisto = resultado['risco'];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impacto previsto: ${impactoPrevisto.toStringAsFixed(2)}'),
        ),
      );
    }
  },
  child: const Text('Simular'),
)

*/