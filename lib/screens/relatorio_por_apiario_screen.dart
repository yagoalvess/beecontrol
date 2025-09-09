// lib/screens/relatorio_por_apiario_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart';

// Classe de dados usada por ambas as telas de relatório
class RelatorioApiarioData {
  String nomeApiario;
  Map<String, double> somaPorCorMel = {};
  double totalMel = 0;
  double totalGeleiaReal = 0;
  double totalPropolis = 0;
  double totalCera = 0;
  double totalApitoxina = 0;
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
  // ... (O restante do seu _RelatorioPorApiarioScreenState permanece o mesmo)
  // CERTIFIQUE-SE DE COPIAR O CONTEÚDO COMPLETO DE _RelatorioPorApiarioScreenState AQUI
  // DA RESPOSTA ANTERIOR ONDE ELE FOI FORNECIDO (COM O APPBAR REMOVIDO).

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
          print("Erro ao processar data em RelatorioPorApiarioScreen: $e. Registro: $registro");
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
      dadosApiario.numeroDeCaixasComProducao =
          caixasComProducaoNoLocal.length;
      relatoriosProcessados.add(dadosApiario);
    });

    relatoriosProcessados.sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

    if (mounted) {
      setState(() {
        _dadosRelatorioPorApiario = relatoriosProcessados;
        if (todosOsRegistrosComLocal.isEmpty) _totaisGerais = null;
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
    return Scaffold(
      // appBar: AppBar( // AppBar REMOVIDO
      //   title: const Text('Relatório por Apiário'),
      //   backgroundColor: const Color(0xFFFFC107),
      //   foregroundColor: Colors.black87,
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
              Icon(Icons.location_city_outlined,
                  size: 60.0, color: Colors.grey.shade400),
              const SizedBox(height: 16.0),
              Text(
                  'Nenhum dado de produção encontrado para gerar relatórios por apiário.',
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
              (_totaisGerais != null && _totaisGerais!.totalMel > 0 ? 1 : 0),
          itemBuilder: (context, index) {
            // ... (lógica do itemBuilder, igual à versão anterior)
            if (index == _dadosRelatorioPorApiario.length &&
                _totaisGerais != null &&
                _totaisGerais!.totalMel > 0) {
              // Último item: Card de Totais Gerais
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
            // Itens normais: ExpansionTile para cada apiário
            if (index < _dadosRelatorioPorApiario.length) {
              final dadosApiario = _dadosRelatorioPorApiario[index];
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
    // ... (lógica do _buildConteudoRelatorioApiario, igual à versão anterior)
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
        if (dados.somaPorCorMel.isNotEmpty) ...[
          Text('Total por Cor/Tipo:',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6.0),
          ...dados.somaPorCorMel.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('  • ${entry.key}:',
                      style: const TextStyle(fontSize: 14.5)),
                  Text('${entry.value.toStringAsFixed(2)} kg/L',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          const Divider(height: 16, thickness: 0.8),
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
          ),
        ] else
          Text('Nenhum registro de mel para este apiário.',
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600)),
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
        _buildOutroProdutoItem('Geleia Real:', dados.totalGeleiaReal, 'g'),
        _buildOutroProdutoItem('Própolis:', dados.totalPropolis, 'g/mL'),
        _buildOutroProdutoItem('Cera de Abelha:', dados.totalCera, 'kg/placas'),
        _buildOutroProdutoItem('Apitoxina:', dados.totalApitoxina, 'g/coletor'),
        if(isTotalGeral && (dados.totalGeleiaReal > 0 || dados.totalPropolis > 0 || dados.totalCera > 0 || dados.totalApitoxina > 0))
          const SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildOutroProdutoItem(String nome, double total, String unidade) {
    if (total <= 0) return const SizedBox.shrink();
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
