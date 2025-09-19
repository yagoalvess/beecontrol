// lib/utils/csv_exporter.dart
import 'package:intl/intl.dart';
// Importe a definição da sua classe RelatorioApiarioData
// Assumindo que está em relatorio_por_apiario_screen.dart
import 'package:abelhas/screens/relatorio_por_apiario_screen.dart' show RelatorioApiarioData;


String formatField(String? value) {
  if (value == null) return '""'; // Campo vazio
  String escapedValue = value.replaceAll('"', '""'); // Escapa aspas duplas internas
  return '"$escapedValue"'; // Envolve o campo em aspas duplas
}

String gerarCsvRelatorioProducao(
    List<RelatorioApiarioData> dadosPorApiario,
    RelatorioApiarioData? totaisGerais) {
  StringBuffer sb = StringBuffer();
  final DateFormat csvDateFormat = DateFormat('yyyy-MM-dd');

  // Cabeçalho
  List<String> header = [
    'Tipo de Linha',        // Ex: Apiario, Total Geral
    'Nome do Apiário/Local',
    'Data Início Produção',
    'Data Fim Produção',
    'Nº Caixas com Produção',
    'Produto',
    'Detalhe/Cor do Produto',
    'Quantidade',
    'Unidade',
    'Observação' // Adicionando um campo de observação genérico
  ];
  sb.writeln(header.map(formatField).join(','));

  // Função auxiliar para adicionar linhas de produtos
  void addProductRows(RelatorioApiarioData data, String lineType) {
    String dataAntigaStr = data.dataProducaoMaisAntiga != null
        ? csvDateFormat.format(data.dataProducaoMaisAntiga!)
        : 'N/D';
    String dataRecenteStr = data.dataProducaoMaisRecente != null
        ? csvDateFormat.format(data.dataProducaoMaisRecente!)
        : 'N/D';
    String numCaixasStr = lineType == 'Apiario' ? data.numeroDeCaixasComProducao.toString() : 'N/A';

    data.somaPorCorMel.forEach((cor, qtd) {
      List<String> row = [
        lineType,
        data.nomeApiario,
        dataAntigaStr,
        dataRecenteStr,
        numCaixasStr,
        'Mel',
        cor,
        qtd.toStringAsFixed(2),
        'kg/L',
        '' // Observação vazia
      ];
      sb.writeln(row.map(formatField).join(','));
    });

    if (data.totalGeleiaReal > 0) {
      List<String> row = [
        lineType,
        data.nomeApiario,
        dataAntigaStr,
        dataRecenteStr,
        numCaixasStr,
        'Geleia Real',
        '', // Sem detalhe de cor
        data.totalGeleiaReal.toStringAsFixed(2),
        'g',
        ''
      ];
      sb.writeln(row.map(formatField).join(','));
    }
    if (data.totalPropolis > 0) {
      List<String> row = [
        lineType,
        data.nomeApiario,
        dataAntigaStr,
        dataRecenteStr,
        numCaixasStr,
        'Própolis',
        '',
        data.totalPropolis.toStringAsFixed(2),
        'g/mL',
        ''
      ];
      sb.writeln(row.map(formatField).join(','));
    }
    if (data.totalCera > 0) {
      List<String> row = [
        lineType,
        data.nomeApiario,
        dataAntigaStr,
        dataRecenteStr,
        numCaixasStr,
        'Cera de Abelha',
        '',
        data.totalCera.toStringAsFixed(2),
        'kg/placas',
        ''
      ];
      sb.writeln(row.map(formatField).join(','));
    }
    if (data.totalApitoxina > 0) {
      List<String> row = [
        lineType,
        data.nomeApiario,
        dataAntigaStr,
        dataRecenteStr,
        numCaixasStr,
        'Apitoxina',
        '',
        data.totalApitoxina.toStringAsFixed(2),
        'g/coletor',
        ''
      ];
      sb.writeln(row.map(formatField).join(','));
    }
  }

  // Dados por Apiário
  for (var apiarioData in dadosPorApiario) {
    addProductRows(apiarioData, 'Apiario');
  }

  // Linha em branco para separar
  if (dadosPorApiario.isNotEmpty && totaisGerais != null && totaisGerais.totalMel > 0) {
    sb.writeln([''].map(formatField).join(',')); // Linha em branco simples
  }


  // Totais Gerais
  if (totaisGerais != null && totaisGerais.totalMel > 0) { // Somente adiciona totais se houver produção
    addProductRows(totaisGerais, 'Total Geral');
  } else if (totaisGerais != null && dadosPorApiario.any((d) => d.totalMel > 0) && totaisGerais.totalMel <=0) {
    // Caso especial: há dados de apiário, mas o total geral (por algum motivo) está zerado, mas queremos mostrar "Total Geral"
    List<String> row = [
      'Total Geral',
      totaisGerais.nomeApiario,
      totaisGerais.dataProducaoMaisAntiga != null ? csvDateFormat.format(totaisGerais.dataProducaoMaisAntiga!) : 'N/D',
      totaisGerais.dataProducaoMaisRecente != null ? csvDateFormat.format(totaisGerais.dataProducaoMaisRecente!) : 'N/D',
      'N/A',
      'Nenhuma Produção Totalizada',
      '',
      '0.00',
      '',
      ''
    ];
    sb.writeln(row.map(formatField).join(','));
  }


  return sb.toString();
}

