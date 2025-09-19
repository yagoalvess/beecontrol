// lib/screens/RelatoriosConsolidadosScreen.dart
import 'dart:io';
import 'dart:typed_data'; // Para Uint8List
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:abelhas/screens/relatorio_grafico_apiario_screen.dart';
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart';
import 'package:abelhas/services/historico_service.dart';
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart'
    show RelatorioApiarioData;

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

  List<RelatorioApiarioData> _dadosParaExportar = [];
  RelatorioApiarioData? _totaisGeraisParaExportar;
  bool _isDadosCarregadosParaExportar = false;
  final HistoricoService _historicoService = HistoricoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDadosParaExportacao();
  }

  Future<void> _carregarDadosParaExportacao() async {
    // print("RelatoriosConsolidados: Carregando dados para exportação..."); // Pode remover os prints de debug
    if (!mounted) return;
    // Evita múltiplas chamadas de setState se já estiver carregando
    if (mounted && !_isDadosCarregadosParaExportar && !_isLoading) { // Adicionado !_isLoading
      setState(() { _isLoading = true; }); // Variável _isLoading não declarada, adicionarei
    }


    final todosOsRegistros =
    await _historicoService.getTodosOsRegistrosDeProducaoComLocal();

    if (!mounted) return;

    if (todosOsRegistros.isEmpty) {
      if(mounted) { // Garante que o widget ainda está montado
        setState(() {
          _dadosParaExportar = [];
          _totaisGeraisParaExportar = null;
          _isDadosCarregadosParaExportar = true;
          _isLoading = false; // Define isLoading como false aqui também
        });
      }
      // print("RelatoriosConsolidados: Nenhum dado para exportar.");
      return;
    }

    Map<String, List<Map<String, dynamic>>> registrosAgrupadosPorLocal = {};
    for (var registro in todosOsRegistros) {
      String local =
          registro['localApiario'] as String? ?? 'Local Não Especificado';
      registrosAgrupadosPorLocal.putIfAbsent(local, () => []).add(registro);
    }

    List<RelatorioApiarioData> relatoriosProcessados = [];
    RelatorioApiarioData totaisGeraisProcessados =
    RelatorioApiarioData(nomeApiario: "TOTAL GERAL DE TODOS OS APIÁRIOS");

    registrosAgrupadosPorLocal.forEach((local, registrosDoLocal) {
      RelatorioApiarioData dadosApiario =
      RelatorioApiarioData(nomeApiario: local);
      Set<String> caixasComProducaoNoLocal = {};
      for (var registro in registrosDoLocal) {
        String? caixaIdOrigem = registro['originCaixaId'] as String?;
        if (caixaIdOrigem != null) caixasComProducaoNoLocal.add(caixaIdOrigem);
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
            if (totaisGeraisProcessados.dataProducaoMaisAntiga == null ||
                dataAtual.isBefore(totaisGeraisProcessados.dataProducaoMaisAntiga!)) {
              totaisGeraisProcessados.dataProducaoMaisAntiga = dataAtual;
            }
            if (totaisGeraisProcessados.dataProducaoMaisRecente == null ||
                dataAtual.isAfter(totaisGeraisProcessados.dataProducaoMaisRecente!)) {
              totaisGeraisProcessados.dataProducaoMaisRecente = dataAtual;
            }
          }
        } catch (e) {
          // print("Erro ao processar data em RelatoriosConsolidadosScreen (export): $e. Registro: $registro");
        }

        dadosApiario.totalMel +=
            (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
        totaisGeraisProcessados.totalMel +=
            (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;

        dadosApiario.totalGeleiaReal +=
            (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
        totaisGeraisProcessados.totalGeleiaReal +=
            (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;

        double qtdPropolis =
            (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
        if (qtdPropolis > 0) {
          dadosApiario.totalPropolis += qtdPropolis;
          totaisGeraisProcessados.totalPropolis += qtdPropolis;
          String corPropolis =
              registro['corDaPropolis'] as String? ?? 'Cor Não Especificada';
          dadosApiario.somaPropolisPorCor[corPropolis] =
              (dadosApiario.somaPropolisPorCor[corPropolis] ?? 0) + qtdPropolis;
          totaisGeraisProcessados.somaPropolisPorCor[corPropolis] =
              (totaisGeraisProcessados.somaPropolisPorCor[corPropolis] ?? 0) +
                  qtdPropolis;
        }

        dadosApiario.totalCera +=
            (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
        totaisGeraisProcessados.totalCera +=
            (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
      }
      dadosApiario.numeroDeCaixasComProducao =
          caixasComProducaoNoLocal.length;
      relatoriosProcessados.add(dadosApiario);
    });
    relatoriosProcessados
        .sort((a, b) => a.nomeApiario.compareTo(b.nomeApiario));

    if (!mounted) return;
    setState(() {
      _dadosParaExportar = relatoriosProcessados;
      if (totaisGeraisProcessados.totalMel <= 0 &&
          totaisGeraisProcessados.totalGeleiaReal <= 0 &&
          totaisGeraisProcessados.totalPropolis <= 0 &&
          totaisGeraisProcessados.totalCera <= 0) {
        _totaisGeraisParaExportar = null;
      } else {
        _totaisGeraisParaExportar = totaisGeraisProcessados;
      }
      _isDadosCarregadosParaExportar = true;
      _isLoading = false; // Define isLoading como false ao final do carregamento
    });
    // print("RelatoriosConsolidados: Dados para exportação carregados. Apiários: ${_dadosParaExportar.length}, Total Geral Mel: ${_totaisGeraisParaExportar?.totalMel}");
  }

  // Adicionando a variável _isLoading que faltava
  bool _isLoading = false;


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // NOVO WIDGET AUXILIAR para construir linhas de produto de forma consistente
  pw.Widget _buildLinhaProdutoPdf(String label, String value, pw.TextStyle valueStyle, {pw.TextStyle? labelStyle}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle ?? const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.SizedBox(width: 10),
          pw.Expanded(child: pw.Text(value, style: valueStyle, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }


  Future<void> _exportarDadosComoPDF() async {
    if (!_isDadosCarregadosParaExportar && !_isLoading) { // Verifica se não está carregando
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aguarde, os dados estão sendo carregados...')),
      );
      await _carregarDadosParaExportacao(); // Chama o carregamento
      // Não precisa de outra verificação aqui, pois o botão de exportar
      // só estará ativo se _isDadosCarregadosParaExportar for true
      if (!_isDadosCarregadosParaExportar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível carregar os dados para exportação.')),
        );
        return;
      }
    } else if (_isLoading) { // Se já está carregando, apenas informa o usuário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Aguarde, os dados ainda estão sendo carregados...')),
      );
      return;
    }


    if (_dadosParaExportar.isEmpty && _totaisGeraisParaExportar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Gerando PDF..."),
              ],
            ),
          ),
        );
      },
    );

    final pdf = pw.Document();
    final DateFormat pdfDateFormat = DateFormat('dd/MM/yyyy');
    final String dataGeracao = pdfDateFormat.format(DateTime.now());

    final pw.TextStyle estiloTituloPrincipal =
    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle estiloTituloSecao =
    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800);
    final pw.TextStyle estiloSubtituloApiario =
    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700);
    final pw.TextStyle estiloTextoNormal = const pw.TextStyle(fontSize: 10);
    final pw.TextStyle estiloTextoDado =
    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle estiloTotalLabel =
    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final pw.TextStyle estiloTotalValor =
    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800);
    final pw.TextStyle estiloTotalGeralLabel =
    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple700);
    final pw.TextStyle estiloTotalGeralValor =
    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900);

    List<pw.Widget> pdfWidgets = [];

    pdfWidgets.add(pw.Header(
      level: 0,
      child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Relatório de Produção Consolidado', style: estiloTituloPrincipal),
            pw.Text('Gerado em: $dataGeracao', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          ]),
    ));
    pdfWidgets.add(pw.Divider(thickness: 1.5, color: PdfColors.grey400));
    pdfWidgets.add(pw.SizedBox(height: 15));

    if (_dadosParaExportar.isNotEmpty) {
      pdfWidgets.add(pw.Header(
          level: 1,
          text: 'Produção Detalhada por Apiário',
          textStyle: estiloTituloSecao));
      pdfWidgets.add(pw.SizedBox(height: 8));

      for (var apiarioData in _dadosParaExportar) {
        if (apiarioData.totalMel <= 0 &&
            apiarioData.totalGeleiaReal <= 0 &&
            apiarioData.totalPropolis <= 0 &&
            apiarioData.totalCera <= 0) {
          continue;
        }

        pdfWidgets.add(pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(bottom: 15),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 1),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(apiarioData.nomeApiario, style: estiloSubtituloApiario),
              pw.SizedBox(height: 3),
              if (apiarioData.dataProducaoMaisAntiga != null || apiarioData.dataProducaoMaisRecente != null)
                pw.Text(
                    'Período: ${apiarioData.dataProducaoMaisAntiga != null ? pdfDateFormat.format(apiarioData.dataProducaoMaisAntiga!) : "N/D"} a ${apiarioData.dataProducaoMaisRecente != null ? pdfDateFormat.format(apiarioData.dataProducaoMaisRecente!) : "N/D"}',
                    style: estiloTextoNormal.copyWith(color: PdfColors.grey700)),
              if (apiarioData.numeroDeCaixasComProducao > 0)
                pw.Text('Caixas com produção: ${apiarioData.numeroDeCaixasComProducao}', style: estiloTextoNormal.copyWith(color: PdfColors.grey700)),
              pw.Divider(height: 10, color: PdfColors.grey300),
              pw.SizedBox(height: 5),

              if (apiarioData.totalMel > 0)
                _buildLinhaProdutoPdf('Mel (Total)', '${apiarioData.totalMel.toStringAsFixed(2)} kg/L', estiloTextoDado.copyWith(color: PdfColors.amber700)),

              if (apiarioData.totalGeleiaReal > 0)
                _buildLinhaProdutoPdf('Geleia Real', '${apiarioData.totalGeleiaReal.toStringAsFixed(2)} g', estiloTextoDado.copyWith(color: PdfColors.pink600)),

              if (apiarioData.somaPropolisPorCor.isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Própolis Detalhada:', style: estiloTextoNormal.copyWith(fontWeight: pw.FontWeight.bold, color: PdfColors.brown600)),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                  columnWidths: const {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Cor/Tipo', style: estiloTextoDado.copyWith(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Qtd (g/mL)', style: estiloTextoDado.copyWith(fontSize: 9))),
                    ]),
                    ...apiarioData.somaPropolisPorCor.entries.map((entry) => pw.TableRow(children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(entry.key, style: estiloTextoNormal.copyWith(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(entry.value.toStringAsFixed(2), style: estiloTextoNormal.copyWith(fontSize: 9))),
                    ])),
                  ],
                ),
                pw.SizedBox(height: 3),
                _buildLinhaProdutoPdf('Total Própolis Apiário', '${apiarioData.totalPropolis.toStringAsFixed(2)} g/mL', estiloTotalValor.copyWith(color: PdfColors.brown700), labelStyle: estiloTotalLabel),
              ] else if (apiarioData.totalPropolis > 0)
                _buildLinhaProdutoPdf('Própolis (Total)', '${apiarioData.totalPropolis.toStringAsFixed(2)} g/mL', estiloTextoDado.copyWith(color: PdfColors.brown700)),

              if (apiarioData.totalCera > 0)
                _buildLinhaProdutoPdf('Cera', '${apiarioData.totalCera.toStringAsFixed(2)} kg/placas', estiloTextoDado.copyWith(color: PdfColors.blueGrey500)),
            ],
          ),
        ));
      }
    }
    pdfWidgets.add(pw.SizedBox(height: 10));

    if (_totaisGeraisParaExportar != null) {
      pdfWidgets.add(pw.Header(
          level: 1,
          text: 'Resumo Geral da Produção',
          textStyle: estiloTituloSecao.copyWith(color: PdfColors.deepPurple700)
      ));
      pdfWidgets.add(pw.SizedBox(height: 8));

      pdfWidgets.add(pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey400, width: 1),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_totaisGeraisParaExportar!.dataProducaoMaisAntiga != null || _totaisGeraisParaExportar!.dataProducaoMaisRecente != null) ...[
              pw.Text(
                  'Período Geral Consolidado: ${_totaisGeraisParaExportar!.dataProducaoMaisAntiga != null ? pdfDateFormat.format(_totaisGeraisParaExportar!.dataProducaoMaisAntiga!) : "N/D"} a ${_totaisGeraisParaExportar!.dataProducaoMaisRecente != null ? pdfDateFormat.format(_totaisGeraisParaExportar!.dataProducaoMaisRecente!) : "N/D"}',
                  style: estiloTextoNormal.copyWith(color: PdfColors.grey800, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
            ],

            if (_totaisGeraisParaExportar!.totalMel > 0)
              _buildLinhaProdutoPdf('TOTAL GERAL MEL', '${_totaisGeraisParaExportar!.totalMel.toStringAsFixed(2)} kg/L', estiloTotalGeralValor.copyWith(color: PdfColors.amber800), labelStyle: estiloTotalGeralLabel),

            if (_totaisGeraisParaExportar!.totalGeleiaReal > 0)
              _buildLinhaProdutoPdf('Total Geral Geleia Real', '${_totaisGeraisParaExportar!.totalGeleiaReal.toStringAsFixed(2)} g', estiloTotalGeralValor.copyWith(color: PdfColors.pink700), labelStyle: estiloTotalGeralLabel),

            if (_totaisGeraisParaExportar!.somaPropolisPorCor.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('Própolis Detalhada (Total Geral):', style: estiloTotalGeralLabel.copyWith(fontSize: 12, color: PdfColors.brown700)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cor/Tipo', style: estiloTextoDado.copyWith(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Qtd (g/mL)', style: estiloTextoDado.copyWith(fontSize: 10))),
                  ]),
                  ..._totaisGeraisParaExportar!.somaPropolisPorCor.entries.map((entry) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(entry.key, style: estiloTextoNormal.copyWith(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(entry.value.toStringAsFixed(2), style: estiloTextoNormal.copyWith(fontSize: 10))),
                  ])),
                ],
              ),
              pw.SizedBox(height: 5),
              _buildLinhaProdutoPdf('TOTAL GERAL PRÓPOLIS', '${_totaisGeraisParaExportar!.totalPropolis.toStringAsFixed(2)} g/mL', estiloTotalGeralValor.copyWith(color: PdfColors.brown800), labelStyle: estiloTotalGeralLabel),
            ] else if (_totaisGeraisParaExportar!.totalPropolis > 0)
              _buildLinhaProdutoPdf('Total Geral Própolis', '${_totaisGeraisParaExportar!.totalPropolis.toStringAsFixed(2)} g/mL', estiloTotalGeralValor.copyWith(color: PdfColors.brown800), labelStyle: estiloTotalGeralLabel),

            if (_totaisGeraisParaExportar!.totalCera > 0)
              _buildLinhaProdutoPdf('Total Geral Cera', '${_totaisGeraisParaExportar!.totalCera.toStringAsFixed(2)} kg/placas', estiloTotalGeralValor.copyWith(color: PdfColors.blueGrey700), labelStyle: estiloTotalGeralLabel),
          ],
        ),
      ));
    }

    bool noMeaningfulDataForPdf = pdfWidgets.length <= 3 &&
        _dadosParaExportar.every((d) =>
        d.totalMel <= 0 &&
            d.totalGeleiaReal <= 0 &&
            d.totalPropolis <= 0 &&
            d.totalCera <= 0) &&
        (_totaisGeraisParaExportar == null ||
            (_totaisGeraisParaExportar!.totalMel <= 0 &&
                _totaisGeraisParaExportar!.totalGeleiaReal <= 0 &&
                _totaisGeraisParaExportar!.totalPropolis <= 0 &&
                _totaisGeraisParaExportar!.totalCera <= 0));

    if (noMeaningfulDataForPdf) {
      pdfWidgets.clear();
      pdfWidgets.add(pw.Expanded(
        child: pw.Center(
            child: pw.Text("Nenhum dado de produção para exibir no relatório.", style: estiloTextoNormal.copyWith(fontStyle: pw.FontStyle.italic))),
      ));
    }

    pdf.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return pdfWidgets;
          },
          footer: (pw.Context context) {
            if (noMeaningfulDataForPdf) return pw.SizedBox.shrink();
            return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: pw.Text(
                    'Página ${context.pageNumber} de ${context.pagesCount}',
                    style: pw.Theme.of(context)
                        .defaultTextStyle
                        .copyWith(color: PdfColors.grey, fontSize: 9)));
          }),
    );

    try {
      final Uint8List pdfBytes = await pdf.save();
      if (mounted) Navigator.of(context).pop();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name:
        'Relatorio_Producao_Consolidado_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      print('Erro ao exportar PDF: $e');
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Produção'),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
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
          RelatorioGraficoApiarioScreen(),
          RelatorioPorApiarioScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_isDadosCarregadosParaExportar && !_isLoading) // Botão só ativo se dados carregados E não estiver carregando
            ? _exportarDadosComoPDF
            : null, // Desabilita o botão se os dados não estão prontos ou está carregando
        tooltip: 'Exportar PDF',
        backgroundColor: (_isDadosCarregadosParaExportar && !_isLoading)
            ? Theme.of(context).primaryColor
            : Colors.grey, // Cor diferente para botão desabilitado
        child: _isLoading
            ? const SizedBox( // Mostra um spinner pequeno no FAB enquanto carrega
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3.0),
        )
            : const Icon(Icons.picture_as_pdf, color: Colors.white),
      ),
    );
  }
}

