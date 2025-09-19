// lib/screens/relatorio_por_apiario_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart';

// Classe de dados usada por ambas as telas de relatório
class RelatorioApiarioData {
  String nomeApiario;
  // REMOVIDO: Map<String, double> somaPorCorMel = {};
  double totalMel = 0;
  double totalGeleiaReal = 0;
  double totalPropolis = 0;
  // NOVO: Para armazenar própolis por cor
  Map<String, double> somaPropolisPorCor = {};
  double totalCera = 0;
  // Apitoxina removida da exibição dos relatórios
  DateTime? dataProducaoMaisAntiga;
  DateTime? dataProducaoMaisRecente;
  int numeroDeCaixasComProducao = 0;

  RelatorioApiarioData({required this.nomeApiario});
}

class RelatorioPorApiarioScreen extends StatefulWidget {
  const RelatorioPorApiarioScreen({super.key});

  @override
  State<RelatorioPorApiarioScreen> createState() =>
      _RelatorioPorApiarioScreenState();
}

class _RelatorioPorApiarioScreenState
    extends State<RelatorioPorApiarioScreen> {
  final HistoricoService _historicoService = HistoricoService();
  bool _isLoading = true;

  List<RelatorioApiarioData> _dadosRelatorioPorApiario = [];
  RelatorioApiarioData? _totaisGerais;

  @override
  void initState() {
    super.initState();
    _carregarEProcessarDadosPorApiario();
  }

  Future<void> _carregarEProcessarDadosPorApiario() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final todosOsRegistrosComLocal =
    await _historicoService.getTodosOsRegistrosDeProducaoComLocal();

    if (!mounted) return;

    if (todosOsRegistrosComLocal.isEmpty) {
      setState(() {
        _dadosRelatorioPorApiario = [];
        _totaisGerais = null;
        _isLoading = false;
      });
      return;
    }

    Map<String, List<Map<String, dynamic>>> registrosAgrupadosPorLocal = {};
    for (var registro in todosOsRegistrosComLocal) {
      String local =
          registro['localApiario'] as String? ?? 'Local Não Especificado';
      registrosAgrupadosPorLocal.putIfAbsent(local, () => []).add(registro);
    }

    List<RelatorioApiarioData> relatoriosProcessados = [];
    _totaisGerais =
        RelatorioApiarioData(nomeApiario: "TOTAL GERAL DE TODOS OS APIÁRIOS");

    registrosAgrupadosPorLocal.forEach((local, registrosDoLocal) {
      RelatorioApiarioData dadosApiario =
      RelatorioApiarioData(nomeApiario: local);
      Set<String> caixasComProducaoNoLocal = {};

      for (var registro in registrosDoLocal) {
        String? caixaIdOrigem = registro['originCaixaId'] as String?;
        if (caixaIdOrigem != null) {
          caixasComProducaoNoLocal.add(caixaIdOrigem);
        }

        try {
          if (registro['dataProducao'] != null) {
            DateTime dataAtual =
            DateTime.parse(registro['dataProducao'] as String);
            if (dadosApiario.dataProducaoMaisAntiga == null ||
                dataAtual.isBefore(dadosApiario.dataProducaoMaisAntiga!)) {
              dadosApiario.dataProducaoMaisAntiga = dataAtual;
            }
            if (dadosApiario.dataProducaoMaisRecente == null ||
                dataAtual.isAfter(dadosApiario.dataProducaoMaisRecente!)) {
              dadosApiario.dataProducaoMaisRecente = dataAtual;
            }
            if (_totaisGerais != null) { // Adicionada verificação de nulo
              if (_totaisGerais!.dataProducaoMaisAntiga == null ||
                  dataAtual.isBefore(_totaisGerais!.dataProducaoMaisAntiga!)) {
                _totaisGerais!.dataProducaoMaisAntiga = dataAtual;
              }
              if (_totaisGerais!.dataProducaoMaisRecente == null ||
                  dataAtual.isAfter(_totaisGerais!.dataProducaoMaisRecente!)) {
                _totaisGerais!.dataProducaoMaisRecente = dataAtual;
              }
            }
          }
        } catch (e) {
          print(
              "Erro ao processar data em RelatorioPorApiarioScreen: $e. Registro: $registro");
        }

        // Processamento de Mel (apenas total)
        dadosApiario.totalMel +=
            (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
        if (_totaisGerais != null) {
          _totaisGerais!.totalMel +=
              (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
        }


        dadosApiario.totalGeleiaReal +=
            (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
        if (_totaisGerais != null) {
          _totaisGerais!.totalGeleiaReal +=
              (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
        }


        // Processamento de Própolis com Cor
        double qtdPropolis =
            (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
        if (qtdPropolis > 0) {
          dadosApiario.totalPropolis += qtdPropolis;
          String corPropolis =
              registro['corDaPropolis'] as String? ?? 'Cor Não Especificada';
          dadosApiario.somaPropolisPorCor[corPropolis] =
              (dadosApiario.somaPropolisPorCor[corPropolis] ?? 0) + qtdPropolis;

          if (_totaisGerais != null) {
            _totaisGerais!.totalPropolis += qtdPropolis;
            _totaisGerais!.somaPropolisPorCor[corPropolis] =
                (_totaisGerais!.somaPropolisPorCor[corPropolis] ?? 0) +
                    qtdPropolis;
          }
        }

        dadosApiario.totalCera +=
            (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
        if (_totaisGerais != null) {
          _totaisGerais!.totalCera +=
              (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
        }
      }
      dadosApiario.numeroDeCaixasComProducao =
          caixasComProducaoNoLocal.length;
      relatoriosProcessados.add(dadosApiario);
    });

    relatoriosProcessados
        .sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

    if (mounted) {
      setState(() {
        _dadosRelatorioPorApiario = relatoriosProcessados;
        // Ajustar condição para verificar outros produtos se mel for zero
        if (_totaisGerais != null &&
            (_totaisGerais!.totalMel <= 0 &&
                _totaisGerais!.totalGeleiaReal <= 0 &&
                _totaisGerais!.totalPropolis <= 0 &&
                _totaisGerais!.totalCera <= 0)) {
          _totaisGerais = null;
        }
        _isLoading = false;
      });
    }
  }

  String _formatarData(DateTime? data) {
    if (data == null) return "N/D";
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    bool semDadosGerais = _totaisGerais == null ||
        (_totaisGerais!.totalMel <= 0 &&
            _totaisGerais!.totalPropolis <= 0 &&
            _totaisGerais!.totalGeleiaReal <= 0 &&
            _totaisGerais!.totalCera <= 0);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dadosRelatorioPorApiario.isEmpty && semDadosGerais
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 60.0,
                  color: Colors.grey.shade400),
              const SizedBox(height: 16.0),
              Text(
                  'Nenhum dado de produção encontrado para gerar relatórios.',
                  style: TextStyle(
                      fontSize: 18.0, color: Colors.grey.shade600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _carregarEProcessarDadosPorApiario,
        child: ListView.builder(
          itemCount: _dadosRelatorioPorApiario.length +
              (semDadosGerais ? 0 : 1),
          itemBuilder: (context, index) {
            if (index == _dadosRelatorioPorApiario.length &&
                !semDadosGerais) {
              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 10.0),
                elevation: 3,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildConteudoRelatorioApiario(
                      _totaisGerais!,
                      isTotalGeral: true),
                ),
              );
            }
            if (index < _dadosRelatorioPorApiario.length) {
              final dadosApiario = _dadosRelatorioPorApiario[index];
              if (dadosApiario.totalMel <= 0 &&
                  dadosApiario.totalGeleiaReal <= 0 &&
                  dadosApiario.totalPropolis <= 0 &&
                  dadosApiario.totalCera <= 0) {
                return const SizedBox.shrink();
              }
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
                        color: Theme.of(context).primaryColorDark),
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
                      child: _buildConteudoRelatorioApiario(
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

  Widget _buildConteudoRelatorioApiario(RelatorioApiarioData dados,
      {bool isTotalGeral = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isTotalGeral) ...[
          Text(
            'Período de Produção (Apiário):',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
        if (dados.totalMel > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  isTotalGeral
                      ? 'TOTAL GERAL DE MEL:'
                      : 'TOTAL MEL (APIÁRIO):',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${dados.totalMel.toStringAsFixed(2)} kg/L',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                      fontSize: 15)),
            ],
          )
        else
          Text('Nenhum registro de mel.',
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600)),
        const SizedBox(height: 16.0),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            isTotalGeral
                ? 'Totais Gerais - Outros Produtos'
                : 'Outros Produtos (Apiário)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade600,
                fontSize: isTotalGeral ? 18 : 17),
          ),
        ),
        _buildOutroProdutoItem('Geleia Real:', dados.totalGeleiaReal, 'g'),

        // Própolis com detalhamento de cor
        if (dados.somaPropolisPorCor.isNotEmpty) ...[
          Text('Própolis:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5)),
          const SizedBox(height: 4.0),
          ...dados.somaPropolisPorCor.entries.map((entry) {
            return Padding(
              padding:
              const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('  • ${entry.key}:',
                      style: const TextStyle(fontSize: 14.0)),
                  Text('${entry.value.toStringAsFixed(2)} g/mL',
                      style: const TextStyle(
                          fontSize: 14.0, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(), // Certifique-se que .toList() está aqui
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Própolis:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Colors.teal.shade700)),
                Text('${dados.totalPropolis.toStringAsFixed(2)} g/mL',
                    style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
        ] else if (dados.totalPropolis > 0)
        // Se não tem detalhe por cor, mas tem total. Envolva em um widget para evitar erro.
          _buildOutroProdutoItem(
              'Própolis (Total):', dados.totalPropolis, 'g/mL')
        else if (!isTotalGeral)
          // Mostrar "Nenhum registro" apenas para apiários individuais se própolis for zero. Envolva em um widget.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('Nenhum registro de própolis.',
                  style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600)),
            ),
        // A vírgula aqui pode ser o problema se o bloco if/else if/else acima for o último item
        // antes do próximo _buildOutroProdutoItem. Remova-a se for o caso.

        _buildOutroProdutoItem('Cera de Abelha:', dados.totalCera, 'kg/placas'),
        if (isTotalGeral &&
            (dados.totalGeleiaReal > 0 ||
                dados.totalPropolis > 0 ||
                dados.totalCera > 0))
          const SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildOutroProdutoItem(String nome, double total, String unidade) {
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(nome,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.5)),
          Text('${total.toStringAsFixed(2)} $unidade',
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
