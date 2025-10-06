// ARQUIVO ATUALIZADO E CORRIGIDO (v3): C:/Users/Usuario/Documents/GitHub/beecontrol/lib/services/historico_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoService {
  static const _chaveListaCaixasInfo = 'todas_caixas_info';
  static const _chaveBaseHistorico = 'historico_';
  static const _chaveBaseProducao = 'producao_';
  static const _chaveTodosOsLocais = 'todos_os_locais_persistentes';

  // Métodos de Histórico (sem alteração)
  Future<List<Map<String, dynamic>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    return dados.map((e) {
      try {
        return Map<String, dynamic>.from(json.decode(e) as Map);
      } catch (err) {
        return <String, dynamic>{'id': 'error_${DateTime.now().millisecondsSinceEpoch}', 'descricao': 'Falha ao carregar esta anotação.', 'isError': true};
      }
    }).toList();
  }

  Future<void> adicionarHistorico(String caixaId, String descricao) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    final now = DateTime.now();
    final String uniqueId = now.millisecondsSinceEpoch.toString();
    final entrada = {
      'id': uniqueId,
      'descricao': descricao.trim(),
      'data': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'hora': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'timestamp': now.toIso8601String(),
    };
    dados.add(json.encode(entrada));
    await prefs.setStringList(chaveHistorico, dados);
  }

  Future<bool> atualizarItemHistorico(String caixaId, String itemId, String novaDescricao, String timestampModificacao, String dataModificacao, String horaModificacao) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    List<String> dadosJson = prefs.getStringList(chaveHistorico) ?? [];
    int itemIndex = -1;
    List<Map<String, dynamic>> historicoDecodificado = [];
    for (int i = 0; i < dadosJson.length; i++) {
      try {
        Map<String, dynamic> itemMap = json.decode(dadosJson[i]) as Map<String, dynamic>;
        historicoDecodificado.add(itemMap);
        if (itemMap['id'] == itemId) itemIndex = i;
      } catch (e) {
        historicoDecodificado.add({'error_decoding_update': dadosJson[i]});
      }
    }
    if (itemIndex != -1) {
      historicoDecodificado[itemIndex]['descricao'] = novaDescricao.trim();
      historicoDecodificado[itemIndex]['timestamp_modificacao'] = timestampModificacao;
      historicoDecodificado[itemIndex]['data_modificacao'] = dataModificacao;
      historicoDecodificado[itemIndex]['hora_modificacao'] = horaModificacao;
      final novosDadosJson = historicoDecodificado.map((item) => json.encode(item)).toList();
      await prefs.setStringList(chaveHistorico, novosDadosJson);
      return true;
    }
    return false;
  }

  Future<bool> removerItemHistoricoPorId(String caixaId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    List<String> dadosJson = prefs.getStringList(chaveHistorico) ?? [];
    if (dadosJson.isEmpty) return false;
    int initialLength = dadosJson.length;
    dadosJson.removeWhere((itemJson) {
      try {
        Map<String, dynamic> itemMap = json.decode(itemJson) as Map<String, dynamic>;
        return itemMap['id'] == itemId;
      } catch(e) { return false; }
    });
    if (dadosJson.length < initialLength) {
      await prefs.setStringList(chaveHistorico, dadosJson);
      return true;
    }
    return false;
  }

  // --- Métodos de Gerenciamento de Locais ---

  Future<void> _adicionarLocalSeNaoExistir(String local) async {
    if (local.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final todosOsLocais = prefs.getStringList(_chaveTodosOsLocais) ?? [];
    final localLowerCase = local.trim().toLowerCase();
    if (!todosOsLocais.any((l) => l.toLowerCase() == localLowerCase)) {
      todosOsLocais.add(local.trim());
      await prefs.setStringList(_chaveTodosOsLocais, todosOsLocais);
    }
  }

  Future<List<String>> getTodosOsLocais() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_chaveTodosOsLocais) ?? [];
  }

  // ## INÍCIO DA CORREÇÃO DE ERRO 2 (NOVO MÉTODO) ##
  // Este método foi adicionado de volta para corrigir o erro de compilação na home_screen.
  Future<List<String>> getLocaisUnicos() async {
    final List<Map<String, dynamic>> todasAsCaixas = await getTodasCaixasComLocal();
    final Set<String> locais = {};
    for (var caixaInfo in todasAsCaixas) {
      final String? local = caixaInfo['local'] as String?;
      if (local != null && local.trim().isNotEmpty) {
        locais.add(local.trim());
      }
    }
    return locais.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
  // ## FIM DA CORREÇÃO DE ERRO 2 ##

  // --- Métodos de Gerenciamento de Caixas ---

  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixasComLocal();
    int maxNumeroId = 0;
    for (var caixa in caixas) {
      final id = caixa['id'] as String?;
      if (id != null && id.startsWith('cx-')) {
        try {
          final numStr = id.substring(3);
          final num = int.tryParse(numStr);
          if (num != null && num > maxNumeroId) maxNumeroId = num;
        } catch (e) { /* Ignora */ }
      }
    }
    return 'cx-${(maxNumeroId + 1).toString().padLeft(2, '0')}';
  }

  Future<void> criarCaixa(String id, String local) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasExistentesJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    final caixasExistentes = caixasExistentesJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    if (!caixasExistentes.any((caixa) => caixa['id'] == id)) {
      final novaCaixa = { 'id': id, 'local': local.trim(), 'observacaoFixa': null };
      caixasExistentesJson.add(json.encode(novaCaixa));
      await prefs.setStringList(_chaveListaCaixasInfo, caixasExistentesJson);
      await _adicionarLocalSeNaoExistir(local);
    }
  }

  Future<List<Map<String, dynamic>>> getTodasCaixasComLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dadosJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixasList = [];
    for (String e in dadosJson) {
      try { caixasList.add(Map<String, dynamic>.from(json.decode(e) as Map)); }
      catch (error) { /* Ignora */ }
    }
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

  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal.trim();
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
      await _adicionarLocalSeNaoExistir(novoLocal);
      return true;
    }
    return false;
  }

  Future<void> removerCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    caixas.removeWhere((caixa) => caixa['id'] == caixaId);
    final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
    await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
    await prefs.remove('$_chaveBaseHistorico$caixaId');
    await prefs.remove('$_chaveBaseProducao$caixaId');
  }

  Future<String?> getObservacaoFixa(String caixaId) async {
    final caixas = await getTodasCaixasComLocal();
    final caixa = caixas.firstWhere((c) => c['id'] == caixaId, orElse: () => <String, dynamic>{});
    return caixa['observacaoFixa'] as String?;
  }

  Future<void> salvarObservacaoFixa(String caixaId, String? observacao) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['observacaoFixa'] = observacao;
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
    }
  }

  Future<List<String>> getTodosOsIdsDeCaixas() async {
    final caixasComLocal = await getTodasCaixasComLocal();
    return caixasComLocal.map((caixa) => caixa['id'] as String?).where((id) => id != null && id.isNotEmpty).map((id) => id!).toList();
  }

  // --- Métodos de Produção ---

  Future<bool> adicionarRegistroProducao(Map<String, dynamic> dadosProducao) async {
    final prefs = await SharedPreferences.getInstance();
    String? caixaId = dadosProducao['caixaId'] as String?;
    if (caixaId == null || caixaId.isEmpty) return false;
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesDaCaixaJson = prefs.getStringList(chaveProducaoCaixa) ?? [];
    String? idRecebido = dadosProducao['producaoId']?.toString();
    bool isUpdating = false;
    int existingIndex = -1;
    if (idRecebido != null && idRecebido.isNotEmpty) {
      for (int i = 0; i < producoesDaCaixaJson.length; i++) {
        try {
          var decodedItem = jsonDecode(producoesDaCaixaJson[i]) as Map<String, dynamic>;
          if (decodedItem['producaoId'] == idRecebido) {
            existingIndex = i;
            isUpdating = true;
            break;
          }
        } catch (e) { /* ignora */ }
      }
    }
    Map<String, dynamic> dadosParaSalvar = Map.from(dadosProducao);
    if (isUpdating && existingIndex != -1) {
      producoesDaCaixaJson[existingIndex] = jsonEncode(dadosParaSalvar);
    } else {
      dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
      producoesDaCaixaJson.add(jsonEncode(dadosParaSalvar));
    }
    return await prefs.setStringList(chaveProducaoCaixa, producoesDaCaixaJson);
  }

  Future<List<Map<String, dynamic>>> getRegistrosProducaoDaCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    final List<String>? producoesJson = prefs.getStringList(chaveProducaoCaixa);
    if (producoesJson == null || producoesJson.isEmpty) return [];
    return producoesJson.map((item) => json.decode(item) as Map<String, dynamic>).toList();
  }

  Future<bool> removerRegistroProducao(String caixaId, String producaoId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesJson = prefs.getStringList(chaveProducaoCaixa) ?? [];
    int initialLength = producoesJson.length;
    producoesJson.removeWhere((item) {
      try {
        var decoded = json.decode(item) as Map<String, dynamic>;
        return decoded['producaoId'] == producaoId;
      } catch (e) { return false; }
    });
    if (producoesJson.length < initialLength) {
      await prefs.setStringList(chaveProducaoCaixa, producoesJson);
      return true;
    }
    return false;
  }


  Future<bool> removerLocalPermanente(String local) async {
    if (local.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final todosOsLocais = prefs.getStringList(_chaveTodosOsLocais) ?? [];
    final initialLength = todosOsLocais.length;
    // Remove o local, ignorando diferenças de maiúsculas/minúsculas na comparação
    todosOsLocais.removeWhere((l) => l.trim().toLowerCase() == local.trim().toLowerCase());
    if (todosOsLocais.length < initialLength) {
      await prefs.setStringList(_chaveTodosOsLocais, todosOsLocais);
      return true;
    }
    return false;
  }


  // ## INÍCIO DA CORREÇÃO DE ERRO 1 (MÉTODO RESTAURADO) ##
  // Este método estava faltando e causando erros de compilação em outras telas.
  Future<List<Map<String, dynamic>>> getTodosOsRegistrosDeProducaoComLocal() async {
    final List<Map<String, dynamic>> todasAsCaixas = await getTodasCaixasComLocal();
    final List<Map<String, dynamic>> todosOsRegistros = [];

    for (var caixa in todasAsCaixas) {
      final String caixaId = caixa['id'] as String;
      final String local = caixa['local'] as String? ?? 'Local não definido';
      final List<Map<String, dynamic>> registrosDaCaixa = await getRegistrosProducaoDaCaixa(caixaId);

      for (var registro in registrosDaCaixa) {
        // Adiciona o local e o ID da caixa a cada registro de produção
        registro['local'] = local;
        registro['caixaDisplayId'] = caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
        todosOsRegistros.add(registro);
      }
    }

    // Opcional: Ordenar todos os registros por data, se necessário
    todosOsRegistros.sort((a, b) {
      try {
        DateTime? dateA = DateTime.tryParse(a['dataProducao'] as String? ?? '');
        DateTime? dateB = DateTime.tryParse(b['dataProducao'] as String? ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA); // Mais recente primeiro
      } catch (e) {
        return 0;
      }
    });

    return todosOsRegistros;
  }
// ## FIM DA CORREÇÃO DE ERRO 1 ##
}

