// lib/screens/relatorio_grafico_apiario_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart';

// Importa APENAS a classe RelatorioApiarioData do outro arquivo de relatório.
// Isso evita que a classe RelatorioPorApiarioScreen seja importada acidentalmente daqui,
// o que poderia causar o erro de "imported from both".
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart' show RelatorioApiarioData;


class RelatorioGraficoApiarioScreen extends StatefulWidget {
  const RelatorioGraficoApiarioScreen({super.key});

  @override
  State<RelatorioGraficoApiarioScreen> createState() =>
      _RelatorioGraficoApiarioScreenState();
}

class _RelatorioGraficoApiarioScreenState
    extends State<RelatorioGraficoApiarioScreen> {
  final HistoricoService _historicoService = HistoricoService();
  bool _isLoading = true;

  // Usa a classe RelatorioApiarioData importada
  List<RelatorioApiarioData> _dadosRelatorioPorApiario = [];
  RelatorioApiarioData? _totaisGerais;

  final List<Color> _coresGraficoBarras = [
    Colors.blue.shade700, Colors.green.shade700, Colors.orange.shade700,
    Colors.red.shade700, Colors.purple.shade700, Colors.teal.shade700,
    Colors.pink.shade600, Colors.amber.shade700, Colors.cyan.shade600,
    Colors.lime.shade700,
  ];

  @override
  void initState() {
    super.initState();
    print("REL_GRAFICO_APIARIO: initState chamado");
    _carregarEProcessarDados();
  }

  Future<void> _carregarEProcessarDados() async {
    // ... (O restante do seu método _carregarEProcessarDados permanece o mesmo que na versão anterior com os prints)
    // CERTIFIQUE-SE DE COPIAR O CONTEÚDO COMPLETO DE _carregarEProcessarDados AQUI
    // DA RESPOSTA ONDE ELE FOI FORNECIDO COM OS PRINTS DE DEBUG.
    // Exemplo do início:
    if (!mounted) {
      print("REL_GRAFICO_APIARIO: Widget não montado no início de _carregarEProcessarDados.");
      return;
    }
    print("REL_GRAFICO_APIARIO: Iniciando _carregarEProcessarDados...");
    setState(() {
      _isLoading = true;
    });

    try {
      print("REL_GRAFICO_APIARIO: Buscando todos os registros de produção com local...");
      final todosOsRegistrosComLocal =
      await _historicoService.getTodosOsRegistrosDeProducaoComLocal();
      print("REL_GRAFICO_APIARIO: ${todosOsRegistrosComLocal.length} registros encontrados.");

      if (todosOsRegistrosComLocal.isEmpty) {
        print("REL_GRAFICO_APIARIO: Nenhum registro encontrado. Limpando dados.");
        if (mounted) {
          setState(() {
            _dadosRelatorioPorApiario = [];
            _totaisGerais = null;
          });
        }
      } else {
        // ... (continuação da lógica de processamento) ...
        print("REL_GRAFICO_APIARIO: Agrupando registros por local...");
        Map<String, List<Map<String, dynamic>>> registrosAgrupadosPorLocal = {};
        for (var registro in todosOsRegistrosComLocal) {
          String local =
              registro['localApiario'] as String? ?? 'Local Não Especificado';
          registrosAgrupadosPorLocal.putIfAbsent(local, () => []).add(registro);
        }
        print("REL_GRAFICO_APIARIO: ${registrosAgrupadosPorLocal.length} locais distintos encontrados.");

        List<RelatorioApiarioData> relatoriosProcessados = [];
        _totaisGerais = RelatorioApiarioData(nomeApiario: "TOTAL GERAL DE TODOS OS APIÁRIOS");
        print("REL_GRAFICO_APIARIO: Iniciando processamento por local...");

        registrosAgrupadosPorLocal.forEach((local, registrosDoLocal) {
          print("REL_GRAFICO_APIARIO: Processando local: $local (${registrosDoLocal.length} registros)");
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
                if (dadosApiario.dataProducaoMaisAntiga == null ||
                    dataAtual.isBefore(dadosApiario.dataProducaoMaisAntiga!)) {
                  dadosApiario.dataProducaoMaisAntiga = dataAtual;
                }
                if (dadosApiario.dataProducaoMaisRecente == null ||
                    dataAtual.isAfter(dadosApiario.dataProducaoMaisRecente!)) {
                  dadosApiario.dataProducaoMaisRecente = dataAtual;
                }
                if (_totaisGerais!.dataProducaoMaisAntiga == null ||
                    dataAtual.isBefore(_totaisGerais!.dataProducaoMaisAntiga!)) {
                  _totaisGerais!.dataProducaoMaisAntiga = dataAtual;
                }
                if (_totaisGerais!.dataProducaoMaisRecente == null ||
                    dataAtual.isAfter(_totaisGerais!.dataProducaoMaisRecente!)) {
                  _totaisGerais!.dataProducaoMaisRecente = dataAtual;
                }
              }
            } catch (e) {
              print('REL_GRAFICO_APIARIO: Erro ao processar data de produção para o registro $registro: $e');
            }

            double qtdMel = (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
            if (qtdMel > 0) {
              dadosApiario.totalMel += qtdMel;
              _totaisGerais!.totalMel += qtdMel;
              String cor = registro['corDoMel'] as String? ?? 'Não Especificada';
              dadosApiario.somaPorCorMel[cor] =
                  (dadosApiario.somaPorCorMel[cor] ?? 0) + qtdMel;
              _totaisGerais!.somaPorCorMel[cor] =
                  (_totaisGerais!.somaPorCorMel[cor] ?? 0) + qtdMel;
            }

            dadosApiario.totalGeleiaReal +=
                (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
            _totaisGerais!.totalGeleiaReal +=
                (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
            dadosApiario.totalPropolis +=
                (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
            _totaisGerais!.totalPropolis +=
                (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
            dadosApiario.totalCera +=
                (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
            _totaisGerais!.totalCera +=
                (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
            dadosApiario.totalApitoxina +=
                (registro['quantidadeApitoxina'] as num?)?.toDouble() ?? 0.0;
            _totaisGerais!.totalApitoxina +=
                (registro['quantidadeApitoxina'] as num?)?.toDouble() ?? 0.0;
          }
          dadosApiario.numeroDeCaixasComProducao = caixasComProducaoNoLocal.length;
          relatoriosProcessados.add(dadosApiario);
          print("REL_GRAFICO_APIARIO: Local $local processado. Total Mel: ${dadosApiario.totalMel}");
        });

        print("REL_GRAFICO_APIARIO: Ordenando relatórios processados...");
        relatoriosProcessados.sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

        if (mounted) {
          print("REL_GRAFICO_APIARIO: Montando estado com dados processados.");
          setState(() {
            _dadosRelatorioPorApiario = relatoriosProcessados;
            // Não precisa mais verificar todosOsRegistrosComLocal.isEmpty aqui se já o fez acima
          });
        }
      } // Fim do else

      print("REL_GRAFICO_APIARIO: Processamento de dados concluído no try.");

    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados para gráficos: $e')),
        );
      }
      print("REL_GRAFICO_APIARIO: ERRO CAPTURADO em _carregarEProcessarDados: $e");
      print("REL_GRAFICO_APIARIO: StackTrace: $stackTrace");
    } finally {
      print("REL_GRAFICO_APIARIO: Bloco finally alcançado.");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print("REL_GRAFICO_APIARIO: _isLoading definido como false. Fim de _carregarEProcessarDados.");
      } else {
        print("REL_GRAFICO_APIARIO: Widget não montado no bloco finally.");
      }
    }
  }


  String _formatarData(DateTime? data) {
    if (data == null) return "N/D";
    return DateFormat('dd/MM/yyyy').format(data);
  }

  // Seus métodos _buildGraficoBarrasMelPorCor e _buildGraficoBarrasOutrosProdutos permanecem aqui
  Widget _buildGraficoBarrasMelPorCor(Map<String, double> dadosSomaPorCor) {
    // ... (código do método _buildGraficoBarrasMelPorCor)
    if (dadosSomaPorCor.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Nenhum registro de mel para este apiário.',
            style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600)),
      );
    }

    List<BarChartGroupData> barGroups = [];
    int x = 0;
    int colorIndex = 0;
    double maxY = 0;

    dadosSomaPorCor.forEach((cor, total) {
      if (total > maxY) maxY = total;
      barGroups.add(
        BarChartGroupData(
          x: x++,
          barRods: [
            BarChartRodData(
              toY: total,
              color: _coresGraficoBarras[colorIndex++ % _coresGraficoBarras.length],
              width: 16,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ),
      );
    });
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Produção de Mel por Cor/Tipo (kg/L):',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
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
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String cor = dadosSomaPorCor.keys.elementAt(group.x);
                    return BarTooltipItem(
                      '$cor\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                      if (index >= 0 && index < dadosSomaPorCor.keys.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            dadosSomaPorCor.keys.elementAt(index).length > 10
                                ? '${dadosSomaPorCor.keys.elementAt(index).substring(0,8)}...'
                                : dadosSomaPorCor.keys.elementAt(index),
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 10),
                          ),
                        );
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
                      if (value == 0 || value == maxY || value % (maxY / (maxY > 20 ? 4:2)).ceilToDouble() == 0 ) {
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
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 0.8,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraficoBarrasOutrosProdutos(RelatorioApiarioData dados) {
    // ... (código do método _buildGraficoBarrasOutrosProdutos)
    Map<String, double> outrosProdutosData = {
      if (dados.totalGeleiaReal > 0) 'Geleia R. (g)': dados.totalGeleiaReal,
      if (dados.totalPropolis > 0) 'Própolis (g/mL)': dados.totalPropolis,
      if (dados.totalCera > 0) 'Cera (kg/pl)': dados.totalCera,
      if (dados.totalApitoxina > 0) 'Apitoxina (g)': dados.totalApitoxina,
    };

    if (outrosProdutosData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Nenhum outro produto registrado para este apiário.',
            style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600)),
      );
    }

    List<BarChartGroupData> barGroups = [];
    int x = 0;
    int colorIndex = 0;
    double maxY = 0;

    outrosProdutosData.forEach((nome, total) {
      if (total > maxY) maxY = total;
      barGroups.add(
        BarChartGroupData(
          x: x++,
          barRods: [
            BarChartRodData(
              toY: total,
              color: _coresGraficoBarras[colorIndex++ % _coresGraficoBarras.length],
              width: 22,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
          ],
        ),
      );
    });
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY == 0) maxY = 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text('Outros Produtos:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
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
                  tooltipBgColor: Colors.teal,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String nome = outrosProdutosData.keys.elementAt(group.x);
                    return BarTooltipItem(
                      '$nome\n',
                      const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
                        if (match != null) {
                          label = label.substring(0, match.start).trim();
                        }
                        if (label.length > 10) label = '${label.substring(0,8)}...';

                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(label,
                              style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        );
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
                      if (value == 0 || value == maxY || value % (maxY / (maxY > 20 ? 4:2)).ceilToDouble() == 0 ) {
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
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.shade300,
                    strokeWidth: 0.8,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    print("REL_GRAFICO_APIARIO: Build chamado. isLoading: $_isLoading, Dados Apiario: ${_dadosRelatorioPorApiario.length}, Totais Gerais Mel: ${_totaisGerais?.totalMel}");
    return Scaffold(
      // appBar: AppBar( // AppBar REMOVIDO para funcionar dentro da TabBarView
      //   title: const Text('Relatório Gráfico por Apiário'),
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dadosRelatorioPorApiario.isEmpty && (_totaisGerais == null || _totaisGerais!.totalMel <= 0)
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart_outlined,
                  size: 60.0, color: Colors.grey.shade400),
              const SizedBox(height: 16.0),
              Text(
                  'Nenhum dado de produção encontrado para gerar relatórios gráficos.',
                  style: TextStyle(
                      fontSize: 18.0, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregarEProcessarDados,
        child: ListView.builder(
          itemCount: _dadosRelatorioPorApiario.length +
              (_totaisGerais != null && _totaisGerais!.totalMel > 0
                  ? 1
                  : 0),
          itemBuilder: (context, index) {
            // ... (lógica do itemBuilder, igual à versão anterior)
            if (index == _dadosRelatorioPorApiario.length &&
                _totaisGerais != null &&
                _totaisGerais!.totalMel > 0) {
              print("REL_GRAFICO_APIARIO: Construindo card de Totais Gerais.");
              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 10.0),
                elevation: 3,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildConteudoRelatorioGrafico(
                      _totaisGerais!,
                      isTotalGeral: true),
                ),
              );
            }
            if (index < _dadosRelatorioPorApiario.length) {
              final dadosApiario = _dadosRelatorioPorApiario[index];
              print("REL_GRAFICO_APIARIO: Construindo ExpansionTile para ${dadosApiario.nomeApiario}");
              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 10.0),
                elevation: 2,
                child: ExpansionTile(
                  iconColor: Theme.of(context).primaryColor,
                  collapsedIconColor: Colors.grey.shade700,
                  title: Text(
                    dadosApiario.nomeApiario,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                        Theme.of(context).primaryColorDark),
                  ),
                  subtitle: Text(
                      'Caixas com produção: ${dadosApiario.numeroDeCaixasComProducao} | Período: ${_formatarData(dadosApiario.dataProducaoMaisAntiga)} a ${_formatarData(dadosApiario.dataProducaoMaisRecente)}',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0)
                          .copyWith(top: 0),
                      child: _buildConteudoRelatorioGrafico(
                          dadosApiario),
                    )
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildConteudoRelatorioGrafico(RelatorioApiarioData dados,
      {bool isTotalGeral = false}) {
    // ... (lógica do _buildConteudoRelatorioGrafico, igual à versão anterior)
    print("REL_GRAFICO_APIARIO: Construindo conteúdo para ${dados.nomeApiario}. Total Mel: ${dados.totalMel}");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isTotalGeral) ...[
          Text(
            'Período de Produção (Apiário):',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                fontWeight: FontWeight.bold, color: Colors.green.shade700),
          ),
          Text(
            'De: ${_formatarData(dados.dataProducaoMaisAntiga)}   Até: ${_formatarData(dados.dataProducaoMaisRecente)}',
          ),
          if (dados.numeroDeCaixasComProducao > 0)
            Text(
                'Número de caixas com produção: ${dados.numeroDeCaixasComProducao}'),
          const SizedBox(height: 16.0),
          const Divider(),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            isTotalGeral ? 'Total Geral de Mel' : 'Produção de Mel (Apiário)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
                fontSize: isTotalGeral ? 18 : 17),
          ),
        ),
        _buildGraficoBarrasMelPorCor(dados.somaPorCorMel),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
                isTotalGeral
                    ? 'TOTAL GERAL DE MEL:'
                    : 'TOTAL MEL (APIÁRIO):',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 8),
            Text('${dados.totalMel.toStringAsFixed(2)} kg/L',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 16.0),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            isTotalGeral ? 'Totais Gerais - Outros Produtos' : 'Outros Produtos (Apiário)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade600,
                fontSize: isTotalGeral ? 18 : 17),
          ),
        ),
        _buildGraficoBarrasOutrosProdutos(dados),
      ],
    );
  }
}
