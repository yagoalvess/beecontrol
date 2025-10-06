// COLE ESTE CÓDIGO INTEIRO NO ARQUIVO:
// C:/Users/Usuario/Documents/GitHub/beecontrol/lib/screens/relatorio_grafico_apiario_screen.dart

import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart';

class RelatorioGraficoApiariosScreen extends StatefulWidget {
  const RelatorioGraficoApiariosScreen({super.key});

  @override
  _RelatorioGraficoApiariosScreenState createState() =>
      _RelatorioGraficoApiariosScreenState();
}

class _RelatorioGraficoApiariosScreenState
    extends State<RelatorioGraficoApiariosScreen> {
  final HistoricoService _historicoService = HistoricoService();
  bool _isLoading = true;
  List<RelatorioApiarioData> _dadosRelatorioPorApiario = [];
  RelatorioApiarioData? _totaisGerais;

  // A lista de cores genéricas foi removida, pois agora as cores são específicas.

  @override
  void initState() {
    super.initState();
    _carregarEProcessarDados();
  }

  Future<void> _carregarEProcessarDados() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final todosRegistrosProducao = await _historicoService.getTodosOsRegistrosDeProducaoComLocal();
      if (!mounted) return;

      Map<String, List<Map<String, dynamic>>> registrosAgrupadosPorLocal = {};
      for (var registro in todosRegistrosProducao) {
        String local = registro['localApiario'] as String? ?? 'Local Não Especificado';
        registrosAgrupadosPorLocal.putIfAbsent(local, () => []).add(registro);
      }

      List<RelatorioApiarioData> relatoriosProcessados = [];
      _totaisGerais = RelatorioApiarioData(nomeApiario: "TOTAL GERAL DE TODOS OS APIÁRIOS");

      registrosAgrupadosPorLocal.forEach((local, registrosDoLocal) {
        RelatorioApiarioData dadosApiario = RelatorioApiarioData(nomeApiario: local);
        Set<String> caixasComProducaoNoLocal = {};

        for (var registro in registrosDoLocal) {
          String? caixaIdOrigem = registro['originCaixaId'] as String?;
          if (caixaIdOrigem != null) {
            caixasComProducaoNoLocal.add(caixaIdOrigem);
          }

          try {
            if (registro['dataProducao'] != null) {
              DateTime dataAtual = DateTime.parse(registro['dataProducao'] as String);
              if (dadosApiario.dataProducaoMaisAntiga == null || dataAtual.isBefore(dadosApiario.dataProducaoMaisAntiga!)) {
                dadosApiario.dataProducaoMaisAntiga = dataAtual;
              }
              if (dadosApiario.dataProducaoMaisRecente == null || dataAtual.isAfter(dadosApiario.dataProducaoMaisRecente!)) {
                dadosApiario.dataProducaoMaisRecente = dataAtual;
              }
            }
          } catch (e) {
            // ignora erro de data
          }

          dadosApiario.totalMel += (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
          dadosApiario.totalCera += (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
          dadosApiario.totalPolen += (registro['quantidadePolen'] as num?)?.toDouble() ?? 0.0;

          double qtdPropolis = (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
          if (qtdPropolis > 0) {
            dadosApiario.totalPropolis += qtdPropolis;
            String corPropolis = registro['corDaPropolis'] as String? ?? 'Sem Cor';
            dadosApiario.somaPropolisPorCor[corPropolis] = (dadosApiario.somaPropolisPorCor[corPropolis] ?? 0) + qtdPropolis;
          }
        }
        dadosApiario.numeroDeCaixasComProducao = caixasComProducaoNoLocal.length;
        relatoriosProcessados.add(dadosApiario);

        if (_totaisGerais != null) {
          _totaisGerais!.totalMel += dadosApiario.totalMel;
          _totaisGerais!.totalCera += dadosApiario.totalCera;
          _totaisGerais!.totalPolen += dadosApiario.totalPolen;
          _totaisGerais!.totalPropolis += dadosApiario.totalPropolis;
          dadosApiario.somaPropolisPorCor.forEach((cor, valor) {
            _totaisGerais!.somaPropolisPorCor[cor] = (_totaisGerais!.somaPropolisPorCor[cor] ?? 0) + valor;
          });

          if (dadosApiario.dataProducaoMaisAntiga != null) {
            if (_totaisGerais!.dataProducaoMaisAntiga == null || dadosApiario.dataProducaoMaisAntiga!.isBefore(_totaisGerais!.dataProducaoMaisAntiga!)) {
              _totaisGerais!.dataProducaoMaisAntiga = dadosApiario.dataProducaoMaisAntiga;
            }
          }
          if (dadosApiario.dataProducaoMaisRecente != null) {
            if (_totaisGerais!.dataProducaoMaisRecente == null || dadosApiario.dataProducaoMaisRecente!.isAfter(_totaisGerais!.dataProducaoMaisRecente!)) {
              _totaisGerais!.dataProducaoMaisRecente = dadosApiario.dataProducaoMaisRecente;
            }
          }
        }
      });

      relatoriosProcessados.sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

      if (mounted) {
        if (_totaisGerais != null &&
            (_totaisGerais!.totalMel <= 0 &&
                _totaisGerais!.totalPropolis <= 0 &&
                _totaisGerais!.totalCera <= 0 &&
                _totaisGerais!.totalPolen <= 0)) {
          _totaisGerais = null;
        }
        setState(() {
          _dadosRelatorioPorApiario = relatoriosProcessados;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar dados para gráficos: $e')));
      }
      print("REL_GRAFICO_APIARIO: ERRO: $e\n$stackTrace");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return "N/D";
    return DateFormat('dd/MM/yyyy').format(data);
  }

  // ===================================================================
  // **[CORREÇÃO 1]** - Função auxiliar para pegar a cor da Própolis
  // ===================================================================
  Color _getCorParaPropolis(String corNome) {
    switch (corNome.toLowerCase()) {
      case 'verde':
        return Colors.green.shade400;
      case 'marrom':
        return Colors.brown.shade400;
      default:
        return Colors.grey.shade500; // Cor padrão para "Outra", "Sem Cor", etc.
    }
  }

  Widget _buildGraficoBarrasPropolisPorCor(Map<String, double> dadosSomaPropolisPorCor) {
    if (dadosSomaPropolisPorCor.isEmpty) {
      return const SizedBox.shrink();
    }
    List<BarChartGroupData> barGroups = [];
    int x = 0;
    double maxY = 0;

    dadosSomaPropolisPorCor.forEach((cor, total) {
      if (total > maxY) maxY = total;
      barGroups.add(BarChartGroupData(
        x: x++,
        barRods: [
          BarChartRodData(
            toY: total,
            color: _getCorParaPropolis(cor), // Usa a função para definir a cor
            width: 16,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      ));
    });
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Produção de Própolis por Cor (g):', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  // ** ERRO CORRIGIDO AQUI **
                  tooltipBgColor: Colors.blueGrey, // Propriedade correta
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String cor = dadosSomaPropolisPorCor.keys.elementAt(group.x);
                    return BarTooltipItem(
                      '$cor\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < dadosSomaPropolisPorCor.keys.length) {
                        String label = dadosSomaPropolisPorCor.keys.elementAt(index);
                        if (label.length > 10) label = '${label.substring(0, 8)}...';
                        return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == maxY || value % (maxY / (maxY > 20 ? 4 : 2)).ceilToDouble() == 0) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================================================================
  // **[CORREÇÃO 2]** - Função auxiliar para pegar a cor de Outros Produtos
  // ===================================================================
  Color _getCorParaOutroProduto(String nomeProduto) {
    if (nomeProduto.toLowerCase().contains('pólen')) {
      return Colors.amber.shade600; // Amarelo/Dourado para o Pólen
    }
    if (nomeProduto.toLowerCase().contains('cera')) {
      return Colors.yellow.shade300; // Amarelo claro para a Cera
    }
    return Colors.teal.shade300; // Cor padrão (fallback)
  }

  Widget _buildGraficoBarrasOutrosProdutos(RelatorioApiarioData dados) {
    Map<String, double> outrosProdutosData = {
      if (dados.totalCera > 0) 'Cera (kg)': dados.totalCera,
      if (dados.totalPolen > 0) 'Pólen (g)': dados.totalPolen,
    };

    if (outrosProdutosData.isEmpty) {
      return const SizedBox.shrink();
    }

    List<BarChartGroupData> barGroups = [];
    int x = 0;
    double maxY = 0;

    outrosProdutosData.forEach((nome, total) {
      if (total > maxY) maxY = total;
      barGroups.add(BarChartGroupData(
        x: x++,
        barRods: [
          BarChartRodData(
            toY: total,
            color: _getCorParaOutroProduto(nome), // Usa a função para definir a cor
            width: 22,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          ),
        ],
      ));
    });
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Outros Produtos:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  // ** ERRO CORRIGIDO AQUI **
                  tooltipBgColor: Colors.blueGrey, // Propriedade correta
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String nome = outrosProdutosData.keys.elementAt(group.x);
                    return BarTooltipItem(
                      '$nome\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toStringAsFixed(2),
                          style: const TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < outrosProdutosData.keys.length) {
                        String label = outrosProdutosData.keys.elementAt(index);
                        RegExpMatch? match = RegExp(r'\(([^)]+)\)$').firstMatch(label);
                        if (match != null) label = label.substring(0, match.start).trim();
                        if (label.length > 10) label = '${label.substring(0, 8)}...';
                        return SideTitleWidget(axisSide: meta.axisSide, space: 4, child: Text(label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 10)));
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == maxY || value % (maxY / (maxY > 20 ? 4 : 2)).ceilToDouble() == 0) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para verificar se há dados para exibir (não alterada)
    bool semDados = _dadosRelatorioPorApiario.every((d) => d.totalMel <= 0 && d.totalCera <= 0 && d.totalPolen <= 0 && d.totalPropolis <= 0) && _totaisGerais == null;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : semDados
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pie_chart_outline, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Nenhuma produção encontrada para exibir nos gráficos.', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregarEProcessarDados,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          children: [
            // Lógica de ordenação (apiários primeiro, total geral por último)
            ..._dadosRelatorioPorApiario
                .where((dados) => dados.totalMel > 0 || dados.totalCera > 0 || dados.totalPolen > 0 || dados.totalPropolis > 0)
                .map((dados) => _buildCardRelatorio(dados))
                .toList(),
            if (_totaisGerais != null) _buildCardRelatorio(_totaisGerais!, isTotalGeral: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCardRelatorio(RelatorioApiarioData dados, {bool isTotalGeral = false}) {
    if (isTotalGeral) {
      // Card de Total Geral (não expansível)
      return Card(
        elevation: 4.0,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        color: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dados.nomeApiario, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
              const Divider(height: 24),
              Text('Mel Produzido: ${dados.totalMel.toStringAsFixed(2)} Kg', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              _buildGraficoBarrasPropolisPorCor(dados.somaPropolisPorCor),
              _buildGraficoBarrasOutrosProdutos(dados),
              if (dados.totalMel <= 0 && dados.totalPropolis <= 0 && dados.totalCera <= 0 && dados.totalPolen <= 0)
                Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child: Text("Nenhuma produção registrada no período.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)))),
              const Divider(height: 32, thickness: 1),
              if (dados.dataProducaoMaisAntiga != null && dados.dataProducaoMaisRecente != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Período Geral: ${_formatarData(dados.dataProducaoMaisAntiga)} a ${_formatarData(dados.dataProducaoMaisRecente)}', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // Cards de Apiários Individuais (expansíveis)
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        iconColor: Theme.of(context).primaryColor,
        collapsedIconColor: Colors.grey.shade700,
        title: Text(
          dados.nomeApiario,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorDark),
        ),
        subtitle: Text(
            'Caixas com produção: ${dados.numeroDeCaixasComProducao} | Período: ${_formatarData(dados.dataProducaoMaisAntiga)} a ${_formatarData(dados.dataProducaoMaisRecente)}',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (dados.totalMel > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL MEL (APIÁRIO):', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('${dados.totalMel.toStringAsFixed(2)} kg/L', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 15)),
                      ],
                    ),
                  ),
                _buildGraficoBarrasPropolisPorCor(dados.somaPropolisPorCor),
                _buildGraficoBarrasOutrosProdutos(dados),
                if (dados.totalPropolis <= 0 && dados.totalCera <= 0 && dados.totalPolen <= 0 && dados.totalMel <= 0)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child: Text("Nenhuma produção registrada para este apiário.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600)))),
              ],
            ),
          )
        ],
      ),
    );
  }
}
