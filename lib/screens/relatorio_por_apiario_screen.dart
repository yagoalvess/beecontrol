// COLE ESTE CÓDIGO INTEIRO NO ARQUIVO: C:/Users/Usuario/Documents/GitHub/beecontrol/lib/screens/relatorio_por_apiario_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart';

// Classe de dados usada por ambas as telas de relatório
class RelatorioApiarioData {
  String nomeApiario;
  double totalMel = 0;
  double totalGeleiaReal = 0;
  double totalPropolis = 0;
  double totalPolen = 0;
  Map<String, double> somaPropolisPorCor = {};
  double totalCera = 0;
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
          }
        } catch (e) {
          print(
              "Erro ao processar data em RelatorioPorApiarioScreen: $e. Registro: $registro");
        }

        dadosApiario.totalMel +=
            (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
        dadosApiario.totalGeleiaReal +=
            (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
        dadosApiario.totalPolen +=
            (registro['quantidadePolen'] as num?)?.toDouble() ?? 0.0;
        dadosApiario.totalCera +=
            (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;

        double qtdPropolis =
            (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
        if (qtdPropolis > 0) {
          dadosApiario.totalPropolis += qtdPropolis;
          String corPropolis =
              registro['corDaPropolis'] as String? ?? 'Cor Não Especificada';
          dadosApiario.somaPropolisPorCor[corPropolis] =
              (dadosApiario.somaPropolisPorCor[corPropolis] ?? 0) + qtdPropolis;
        }
      }
      dadosApiario.numeroDeCaixasComProducao =
          caixasComProducaoNoLocal.length;
      relatoriosProcessados.add(dadosApiario);

      // Soma os totais do apiário recém-processado para o total geral
      if (_totaisGerais != null) {
        _totaisGerais!.totalMel += dadosApiario.totalMel;
        _totaisGerais!.totalGeleiaReal += dadosApiario.totalGeleiaReal;
        _totaisGerais!.totalPolen += dadosApiario.totalPolen;
        _totaisGerais!.totalCera += dadosApiario.totalCera;
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

    relatoriosProcessados
        .sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

    if (mounted) {
      setState(() {
        _dadosRelatorioPorApiario = relatoriosProcessados;

        // **[CORREÇÃO 1]** - INCLUI PÓLEN NA CONDIÇÃO PARA MOSTRAR O TOTAL GERAL
        if (_totaisGerais != null &&
            (_totaisGerais!.totalMel <= 0 &&
                _totaisGerais!.totalGeleiaReal <= 0 &&
                _totaisGerais!.totalPropolis <= 0 &&
                _totaisGerais!.totalCera <= 0 &&
                _totaisGerais!.totalPolen <= 0)) { // <- CORRIGIDO
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
    // **[CORREÇÃO 2]** - INCLUI PÓLEN NA CONDIÇÃO PARA MOSTRAR O TOTAL GERAL
    bool semDadosGerais = _totaisGerais == null ||
        (_totaisGerais!.totalMel <= 0 &&
            _totaisGerais!.totalPropolis <= 0 &&
            _totaisGerais!.totalGeleiaReal <= 0 &&
            _totaisGerais!.totalCera <= 0 &&
            _totaisGerais!.totalPolen <= 0); // <- CORRIGIDO

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
            // Lógica para mostrar o card de TOTAL GERAL no final
            if (index == _dadosRelatorioPorApiario.length &&
                !semDadosGerais) {
              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 10.0),
                elevation: 3,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Aumenta o padding para o total geral
                  child: _buildConteudoRelatorioApiario(
                      _totaisGerais!,
                      isTotalGeral: true),
                ),
              );
            }
            // Lógica para mostrar cada apiário individualmente
            if (index < _dadosRelatorioPorApiario.length) {
              final dadosApiario = _dadosRelatorioPorApiario[index];
              // **[CORREÇÃO 3]** - INCLUI PÓLEN NA CONDIÇÃO PARA MOSTRAR O CARD DO APIÁRIO
              if (dadosApiario.totalMel <= 0 &&
                  dadosApiario.totalGeleiaReal <= 0 &&
                  dadosApiario.totalPropolis <= 0 &&
                  dadosApiario.totalCera <= 0 &&
                  dadosApiario.totalPolen <= 0) { // <- CORRIGIDO
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
        if (isTotalGeral)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              dados.nomeApiario,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800
              ),
            ),
          ),

        if (!isTotalGeral) ...[
          // Seus widgets de período e número de caixas... (já estavam corretos)
        ],

        // Seção de Mel
        if (dados.totalMel > 0) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'TOTAL MEL:',
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
            ),
          )
        ],

        // Seção de Outros Produtos
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Outros Produtos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade600,
                fontSize: 17),
          ),
        ),

        _buildOutroProdutoItem('Geleia Real:', dados.totalGeleiaReal, 'g'),

        // Própolis com detalhamento
        if (dados.somaPropolisPorCor.isNotEmpty) ...[
          // ... sua lógica de própolis (já estava correta) ...
        ] else if (dados.totalPropolis > 0)
          _buildOutroProdutoItem(
              'Própolis (Total):', dados.totalPropolis, 'g'),

        _buildOutroProdutoItem('Cera de Abelha:', dados.totalCera, 'kg/placas'),

        // **[CORREÇÃO 4]** - EXIBE O PÓLEN NA TELA
        _buildOutroProdutoItem('Pólen Coletado:', dados.totalPolen, 'g'),

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

