// lib/screens/relatorios_consolidados_screen.dart
import 'package:flutter/material.dart';
// Importação direta e correta para cada tela de relatório
import 'package:abelhas/screens/relatorio_grafico_apiario_screen.dart'; // Verifique se este arquivo existe e o nome da classe está correto
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart';   // Verifique se este arquivo existe e o nome da classe está correto

class RelatoriosConsolidadosScreen extends StatefulWidget {
  const RelatoriosConsolidadosScreen({super.key});

  @override
  State<RelatoriosConsolidadosScreen> createState() =>
      _RelatoriosConsolidadosScreenState();
}

class _RelatoriosConsolidadosScreenState
    extends State<RelatoriosConsolidadosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Produção'),
        backgroundColor: const Color(0xFFFFC107), // Cor da AppBar da HomeScreen
        foregroundColor: Colors.black87,        // Cor do texto da AppBar da HomeScreen
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black87,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Gráfico por Apiário'),
            Tab(icon: Icon(Icons.list_alt), text: 'Detalhado por Apiário'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          // Certifique-se que o nome da classe aqui está EXATAMENTE como definido no arquivo dela
          RelatorioGraficoApiarioScreen(),

          // Certifique-se que o nome da classe aqui está EXATAMENTE como definido no arquivo dela
          RelatorioPorApiarioScreen(),
        ],
      ),
    );
  }
}
