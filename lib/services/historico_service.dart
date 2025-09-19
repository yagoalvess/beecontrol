import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart'; // Descomente se quiser usar UUID para IDs de produção

class HistoricoService {
  static const _chaveListaCaixasInfo = 'todas_caixas_info';
  static const _chaveBaseHistorico = 'historico_';
  static const _chaveBaseProducao = 'producao_';

  Future<List<Map<String, String>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    return dados.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  Future<void> adicionarHistorico(String caixaId, String descricao) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    final now = DateTime.now();
    final entrada = {
      'descricao': descricao,
      'data':
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'hora':
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    };
    dados.add(json.encode(entrada));
    await prefs.setStringList(chaveHistorico, dados);
  }

  Future<void> removerHistorico(String caixaId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    if (index >= 0 && index < dados.length) {
      dados.removeAt(index);
      await prefs.setStringList(chaveHistorico, dados);
    }
  }

  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixasComLocal();
    int maxNumeroId = 0;
    for (var caixa in caixas) {
      final id = caixa['id'] as String?;
      if (id != null && id.startsWith('cx-')) {
        try {
          final numStr = id.substring(3);
          final num = int.tryParse(numStr);
          if (num != null && num > maxNumeroId) {
            maxNumeroId = num;
          }
        } catch (e) {
          // Ignora IDs malformados
        }
      }
    }
    int numero = maxNumeroId + 1;
    return 'cx-${numero.toString().padLeft(2, '0')}';
  }

  Future<void> criarCaixa(String id, String local) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasExistentesJson =
        prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    final caixasExistentes = caixasExistentesJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    if (!caixasExistentes.any((caixa) => caixa['id'] == id)) {
      final novaCaixa = {
        'id': id,
        'local': local.trim(), // Garante que o local seja salvo sem espaços extras
        'observacaoFixa': null,
      };
      caixasExistentesJson.add(json.encode(novaCaixa));
      await prefs.setStringList(_chaveListaCaixasInfo, caixasExistentesJson);
      print('HistoricoService: Caixa $id criada no local "${local.trim()}".');
    } else {
      print('HistoricoService: Caixa com ID $id já existe. Nenhuma nova caixa foi criada.');
    }
  }

  Future<List<Map<String, dynamic>>> getTodasCaixasComLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dadosJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixasList = [];
    for (String e in dadosJson) {
      try {
        caixasList.add(Map<String, dynamic>.from(json.decode(e) as Map));
      } catch (error) {
        print("HistoricoService: Erro ao decodificar JSON em getTodasCaixasComLocal: $error. Item: $e");
      }
    }
    return caixasList;
  }

  // **** NOVO MÉTODO ADICIONADO AQUI ****
  Future<List<String>> getLocaisUnicos() async {
    try {
      final List<Map<String, dynamic>> todasAsCaixas = await getTodasCaixasComLocal();
      if (todasAsCaixas.isEmpty) {
        return [];
      }

      final Set<String> locais = {}; // Usa um Set para garantir unicidade
      for (var caixaInfo in todasAsCaixas) {
        final String? local = caixaInfo['local'] as String?;
        if (local != null && local.trim().isNotEmpty) {
          locais.add(local.trim());
        }
      }
      // Converte o Set para uma List e a ordena alfabeticamente
      return locais.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (e) {
      print("Erro ao buscar locais únicos no HistoricoService (SharedPreferences): $e");
      return []; // Retorna lista vazia em caso de erro
    }
  }
  // **** FIM DO NOVO MÉTODO ****

  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal.trim(); // Salva o local trimado
      final novasCaixasJson =
      caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
      return true;
    }
    return false;
  }

  Future<void> removerCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    caixas.removeWhere((caixa) => caixa['id'] == caixaId);
    final novasCaixasJson =
    caixas.map((caixa) => json.encode(caixa)).toList();
    await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
    await prefs.remove('$_chaveBaseHistorico$caixaId');
    await prefs.remove('$_chaveBaseProducao$caixaId');
    print("HistoricoService: Caixa $caixaId e seus dados associados foram removidos.");
  }

  Future<String?> getObservacaoFixa(String caixaId) async {
    final caixas = await getTodasCaixasComLocal();
    final caixa =
    caixas.firstWhere((c) => c['id'] == caixaId, orElse: () => <String, dynamic>{});
    return caixa.containsKey('observacaoFixa')
        ? caixa['observacaoFixa'] as String?
        : null;
  }

  Future<void> salvarObservacaoFixa(String caixaId, String? observacao) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['observacaoFixa'] = observacao;
      final novasCaixasJson =
      caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
    }
  }

  Future<List<String>> getTodosOsIdsDeCaixas() async {
    final caixasComLocal = await getTodasCaixasComLocal();
    return caixasComLocal
        .map((caixa) => caixa['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toList();
  }

  Future<bool> adicionarRegistroProducao(
      Map<String, dynamic> dadosProducao) async {
    final prefs = await SharedPreferences.getInstance();
    String? caixaId = dadosProducao['caixaId'] as String?;

    if (caixaId == null || caixaId.isEmpty) {
      print("HistoricoService: ERRO ao adicionar registro de produção - caixaId está nulo ou vazio.");
      return false;
    }

    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesDaCaixaJson =
        prefs.getStringList(chaveProducaoCaixa) ?? [];
    String? idRecebido = dadosProducao['producaoId']?.toString();
    bool isUpdating = false;
    int existingIndex = -1;

    if (idRecebido != null && idRecebido.isNotEmpty) {
      for (int i = 0; i < producoesDaCaixaJson.length; i++) {
        try {
          var decodedItem =
          jsonDecode(producoesDaCaixaJson[i]) as Map<String, dynamic>;
          if (decodedItem['producaoId'] == idRecebido) {
            existingIndex = i;
            isUpdating = true;
            break;
          }
        } catch (e) {
          print("HistoricoService: Erro ao decodificar JSON ao procurar ID para atualização: $e. Item: ${producoesDaCaixaJson[i]}");
        }
      }
    }

    Map<String, dynamic> dadosParaSalvar = Map.from(dadosProducao);

    if (isUpdating && existingIndex != -1) {
      producoesDaCaixaJson[existingIndex] = jsonEncode(dadosParaSalvar);
      print("HistoricoService: Produção ATUALIZADA para $caixaId com ID $idRecebido.");
    } else {
      if (idRecebido != null && idRecebido.isNotEmpty && !isUpdating) {
        print("HistoricoService: ID $idRecebido fornecido mas não encontrado. Gerando novo ID.");
        dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
      } else if (idRecebido == null || idRecebido.isEmpty) {
        dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      if (dadosParaSalvar['producaoId'] == null || (dadosParaSalvar['producaoId'] as String).isEmpty) {
        dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      producoesDaCaixaJson.add(jsonEncode(dadosParaSalvar));
      print("HistoricoService: Produção ADICIONADA para $caixaId com ID ${dadosParaSalvar['producaoId']}.");
    }

    bool sucesso = await prefs.setStringList(chaveProducaoCaixa, producoesDaCaixaJson);
    if (!sucesso) {
      print("HistoricoService: FALHA ao ${isUpdating ? 'atualizar' : 'adicionar'} produção para $caixaId.");
    }
    return sucesso;
  }

  Future<List<Map<String, dynamic>>> getRegistrosProducaoDaCaixa(
      String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    final List<String>? producoesJson = prefs.getStringList(chaveProducaoCaixa);

    if (producoesJson == null || producoesJson.isEmpty) {
      return [];
    }

    final List<Map<String, dynamic>> producoes = [];
    for (String jsonString in producoesJson) {
      try {
        producoes.add(jsonDecode(jsonString) as Map<String, dynamic>);
      } catch (e) {
        print("HistoricoService: Erro ao decodificar JSON em getRegistrosProducaoDaCaixa: $e. Item: $jsonString");
      }
    }

    try {
      producoes.sort((a, b) {
        DateTime? dateA = DateTime.tryParse(a['dataProducao'] as String? ?? '');
        DateTime? dateB = DateTime.tryParse(b['dataProducao'] as String? ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
    } catch (e) {
      print("HistoricoService: Erro ao ordenar registros de produção: $e");
    }
    return producoes;
  }

  Future<bool> removerRegistroProducao(
      String caixaId, String producaoId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesDaCaixaJson =
        prefs.getStringList(chaveProducaoCaixa) ?? [];

    if (producoesDaCaixaJson.isEmpty) {
      print("HistoricoService: Tentativa de remover produção de uma lista vazia para $caixaId.");
      return false;
    }

    List<String> producoesAtualizadasJson = [];
    bool removido = false;

    for (String jsonString in producoesDaCaixaJson) {
      try {
        var decodedItem = jsonDecode(jsonString) as Map<String, dynamic>;
        if (decodedItem['producaoId'] == producaoId) {
          removido = true;
        } else {
          producoesAtualizadasJson.add(jsonString);
        }
      } catch (e) {
        print("HistoricoService: Erro ao decodificar JSON durante a remoção: $e. Item: $jsonString");
        producoesAtualizadasJson.add(jsonString); // Mantém o item se não puder decodificar
      }
    }

    if (removido) {
      bool sucesso = await prefs.setStringList(
          chaveProducaoCaixa, producoesAtualizadasJson);
      if (sucesso) {
        print("HistoricoService: Registro de produção $producaoId removido para $caixaId.");
      } else {
        print("HistoricoService: Falha ao salvar lista após remover produção $producaoId para $caixaId.");
      }
      return sucesso;
    } else {
      print("HistoricoService: Registro de produção $producaoId NÃO encontrado para remoção em $caixaId.");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getTodosOsRegistrosDeProducaoComLocal() async {
    List<Map<String, dynamic>> todosOsRegistrosCombinados = [];
    final List<Map<String, dynamic>> todasAsCaixasInfo = await getTodasCaixasComLocal();

    if (todasAsCaixasInfo.isEmpty) {
      return [];
    }

    Map<String, String> mapaCaixaIdParaLocal = {};
    for (var caixaInfo in todasAsCaixasInfo) {
      final String? caixaId = caixaInfo['id'] as String?;
      final String? local = caixaInfo['local'] as String?;
      if (caixaId != null) {
        mapaCaixaIdParaLocal[caixaId] = local?.trim() ?? 'Local Não Definido';
      }
    }

    for (var caixaInfo in todasAsCaixasInfo) {
      final String? caixaId = caixaInfo['id'] as String?;
      if (caixaId == null || caixaId.isEmpty) {
        continue;
      }

      final List<Map<String, dynamic>> registrosDaCaixa = await getRegistrosProducaoDaCaixa(caixaId);
      for (var registroProducao in registrosDaCaixa) {
        Map<String, dynamic> registroComLocal = Map.from(registroProducao);
        registroComLocal['localApiario'] = mapaCaixaIdParaLocal[caixaId] ?? 'Local Desconhecido';
        registroComLocal['originCaixaId'] = caixaId;
        todosOsRegistrosCombinados.add(registroComLocal);
      }
    }
    return todosOsRegistrosCombinados;
  }
}
