import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:uuid/uuid.dart'; // Descomente se quiser usar UUID para IDs de produção

class HistoricoService {
  static const _chaveListaCaixasInfo = 'todas_caixas_info';
  static const _chaveBaseHistorico = 'historico_';
  static const _chaveBaseProducao = 'producao_';

  // MODIFICADO: Retorna List<Map<String, dynamic>>
  Future<List<Map<String, dynamic>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    // Decodifica para Map<String, dynamic> e trata possíveis erros de JSON
    return dados.map((e) {
      try {
        return Map<String, dynamic>.from(json.decode(e) as Map);
      } catch (err) {
        print("HistoricoService: Erro ao decodificar item do histórico: $e, Erro: $err");
        // Retorna um mapa de erro para que a UI possa lidar com isso ou filtrar
        return <String, dynamic>{
          'id': 'error_${DateTime.now().millisecondsSinceEpoch}', // ID único para o erro
          'descricao': 'Falha ao carregar esta anotação.',
          'data': '',
          'hora': '',
          'timestamp': DateTime.now().toIso8601String(), // Timestamp para ordenação
          'isError': true,
          'originalData': e // Para depuração
        };
      }
    }).toList();
  }

  // MODIFICADO: Adiciona 'id' e 'timestamp'
  Future<void> adicionarHistorico(String caixaId, String descricao) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    final now = DateTime.now();
    final String uniqueId = now.millisecondsSinceEpoch.toString(); // ID único simples

    final entrada = {
      'id': uniqueId, // NOVO CAMPO
      'descricao': descricao.trim(),
      'data':
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'hora':
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'timestamp': now.toIso8601String(), // NOVO CAMPO para ordenação precisa
    };
    dados.add(json.encode(entrada));
    await prefs.setStringList(chaveHistorico, dados);
    print("HistoricoService: Anotação adicionada com ID $uniqueId para caixa $caixaId.");
  }

  // NOVO MÉTODO: Para atualizar um item específico do histórico
  Future<bool> atualizarItemHistorico(
      String caixaId,
      String itemId,
      String novaDescricao,
      String timestampModificacao,
      String dataModificacao,
      String horaModificacao
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    List<String> dadosJson = prefs.getStringList(chaveHistorico) ?? [];

    if (dadosJson.isEmpty) {
      print("HistoricoService: Tentativa de atualizar histórico vazio para caixa $caixaId.");
      return false;
    }

    int itemIndex = -1;
    List<Map<String, dynamic>> historicoDecodificado = [];

    // Decodifica todos os itens e encontra o índice do item a ser atualizado
    for (int i = 0; i < dadosJson.length; i++) {
      try {
        Map<String, dynamic> itemMap = json.decode(dadosJson[i]) as Map<String, dynamic>;
        historicoDecodificado.add(itemMap);
        if (itemMap['id'] == itemId) {
          itemIndex = i; // Guarda o índice na lista decodificada
        }
      } catch (e) {
        print("HistoricoService: Erro ao decodificar item do histórico durante a busca para atualização: ${dadosJson[i]}, Erro: $e");
        // Se houver erro na decodificação, adiciona o JSON original para não perder dados.
        // Isso pode ser problemático se o JSON estiver realmente corrompido.
        // Uma abordagem mais segura seria pular ou marcar o item corrompido.
        // Por ora, vamos manter a lógica de tentar adicionar algo para não quebrar o loop.
        historicoDecodificado.add({'error_decoding_update': dadosJson[i]});
      }
    }

    if (itemIndex != -1) {
      // Atualiza o item encontrado na lista decodificada
      historicoDecodificado[itemIndex]['descricao'] = novaDescricao.trim();
      historicoDecodificado[itemIndex]['timestamp_modificacao'] = timestampModificacao;
      historicoDecodificado[itemIndex]['data_modificacao'] = dataModificacao;
      historicoDecodificado[itemIndex]['hora_modificacao'] = horaModificacao;

      // Codifica todos os itens de volta para JSON
      final novosDadosJson = historicoDecodificado
          .map((item) => json.encode(item))
          .toList();
      await prefs.setStringList(chaveHistorico, novosDadosJson);
      print("HistoricoService: Item $itemId da caixa $caixaId atualizado.");
      return true;
    } else {
      print("HistoricoService: Item $itemId não encontrado na caixa $caixaId para atualização.");
      return false;
    }
  }

  // MODIFICADO: Remove por ID e retorna bool
  Future<bool> removerItemHistoricoPorId(String caixaId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    List<String> dadosJson = prefs.getStringList(chaveHistorico) ?? [];

    if (dadosJson.isEmpty) {
      print("HistoricoService: Tentativa de remover de histórico vazio para caixa $caixaId.");
      return false;
    }

    List<String> novosDadosJson = [];
    bool removido = false;

    for (String itemJson in dadosJson) {
      try {
        Map<String, dynamic> itemMap = json.decode(itemJson) as Map<String, dynamic>;
        if (itemMap['id'] == itemId) {
          removido = true;
          print("HistoricoService: Item $itemId da caixa $caixaId marcado para remoção.");
        } else {
          novosDadosJson.add(itemJson);
        }
      } catch (e) {
        print("HistoricoService: Erro ao decodificar item durante remoção por ID: $itemJson, Erro: $e");
        // Mantém o item se houver erro na decodificação para não perder dados acidentalmente.
        novosDadosJson.add(itemJson);
      }
    }

    if (removido) {
      await prefs.setStringList(chaveHistorico, novosDadosJson);
      print("HistoricoService: Lista de histórico da caixa $caixaId salva após remoção.");
      return true;
    } else {
      print("HistoricoService: Item $itemId não encontrado para remoção na caixa $caixaId.");
      return false;
    }
  }

  // O método removerHistorico(String caixaId, int index) pode ser removido
  // se você garantir que sempre usará a remoção por ID.
  // Se ainda precisar dele por algum motivo, mantenha-o. Caso contrário:
  // Removido: Future<void> removerHistorico(String caixaId, int index) async { ... }


  Future<String> gerarNovoId() async {
    // ... (seu código existente, parece correto) ...
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
    // ... (seu código existente, parece correto) ...
    final prefs = await SharedPreferences.getInstance();
    final caixasExistentesJson =
        prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    final caixasExistentes = caixasExistentesJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    if (!caixasExistentes.any((caixa) => caixa['id'] == id)) {
      final novaCaixa = {
        'id': id,
        'local': local.trim(),
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
    // Adicionando ordenação aqui para consistência
    caixasList.sort((a, b) {
      String localA = (a['local'] as String? ?? '').toLowerCase();
      String localB = (b['local'] as String? ?? '').toLowerCase();
      int localCompare = localA.compareTo(localB);
      if (localCompare != 0) return localCompare;

      String idAStr = (a['id'] as String? ?? 'cx-0').replaceAll('cx-', '');
      String idBStr = (b['id'] as String? ?? 'cx-0').replaceAll('cx-', '');
      int idANum = int.tryParse(idAStr) ?? 0;
      int idBNum = int.tryParse(idBStr) ?? 0;
      return idANum.compareTo(idBNum);
    });
    return caixasList;
  }

  Future<List<String>> getLocaisUnicos() async {
    // ... (seu código existente, parece correto) ...
    try {
      final List<Map<String, dynamic>> todasAsCaixas = await getTodasCaixasComLocal();
      if (todasAsCaixas.isEmpty) {
        return [];
      }
      final Set<String> locais = {};
      for (var caixaInfo in todasAsCaixas) {
        final String? local = caixaInfo['local'] as String?;
        if (local != null && local.trim().isNotEmpty) {
          locais.add(local.trim());
        }
      }
      return locais.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (e) {
      print("Erro ao buscar locais únicos no HistoricoService (SharedPreferences): $e");
      return [];
    }
  }

  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    // ... (seu código existente, parece correto) ...
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal.trim();
      final novasCaixasJson =
      caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
      return true;
    }
    return false;
  }

  Future<void> removerCaixa(String caixaId) async {
    // ... (seu código existente, parece correto) ...
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
    // ... (seu código existente, parece correto) ...
    final caixas = await getTodasCaixasComLocal();
    final caixa =
    caixas.firstWhere((c) => c['id'] == caixaId, orElse: () => <String, dynamic>{});
    return caixa.containsKey('observacaoFixa')
        ? caixa['observacaoFixa'] as String?
        : null;
  }

  Future<void> salvarObservacaoFixa(String caixaId, String? observacao) async {
    // ... (seu código existente, parece correto) ...
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
    // ... (seu código existente, parece correto) ...
    final caixasComLocal = await getTodasCaixasComLocal();
    return caixasComLocal
        .map((caixa) => caixa['id'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toList();
  }

  Future<bool> adicionarRegistroProducao(
      Map<String, dynamic> dadosProducao) async {
    // ... (seu código existente, parece correto, mas garanta que producaoId é sempre gerado ao adicionar) ...
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
          print("HistoricoService: Erro ao decodificar JSON ao procurar ID para atualização de produção: $e. Item: ${producoesDaCaixaJson[i]}");
        }
      }
    }

    Map<String, dynamic> dadosParaSalvar = Map.from(dadosProducao);

    if (isUpdating && existingIndex != -1) {
      producoesDaCaixaJson[existingIndex] = jsonEncode(dadosParaSalvar);
      print("HistoricoService: Produção ATUALIZADA para $caixaId com ID $idRecebido.");
    } else {
      // Sempre gera um novo ID se não estiver atualizando ou se o ID não for encontrado
      dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
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
    // ... (seu código existente, parece correto) ...
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
    // ... (seu código existente, parece correto) ...
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
        print("HistoricoService: Erro ao decodificar JSON durante a remoção de produção: $e. Item: $jsonString");
        producoesAtualizadasJson.add(jsonString);
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
    // ... (seu código existente, parece correto) ...
    final List<Map<String, dynamic>> todasAsCaixas = await getTodasCaixasComLocal();
    final List<Map<String, dynamic>> todosOsRegistrosComLocal = [];

    for (var caixaInfo in todasAsCaixas) {
      final String? caixaId = caixaInfo['id'] as String?;
      final String? localDaCaixa = caixaInfo['local'] as String?;

      if (caixaId != null && caixaId.isNotEmpty) {
        final List<Map<String, dynamic>> registrosDaCaixa = await getRegistrosProducaoDaCaixa(caixaId);
        for (var registro in registrosDaCaixa) {
          final Map<String, dynamic> registroComLocal = Map.from(registro);
          registroComLocal['localCaixa'] = localDaCaixa ?? 'Local Desconhecido'; // Nome do campo consistente
          registroComLocal['originCaixaId'] = caixaId; // Adicionado para referência
          todosOsRegistrosComLocal.add(registroComLocal);
        }
      }
    }
    return todosOsRegistrosComLocal;
  }
}
