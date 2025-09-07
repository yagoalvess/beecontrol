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
      'data': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'hora': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
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
    int numero = caixas.length + 1;
    return 'cx-${numero.toString().padLeft(2, '0')}';
  }

  Future<void> criarCaixa(String id, String local) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasExistentesJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    final caixasExistentes = caixasExistentesJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    if (!caixasExistentes.any((caixa) => caixa['id'] == id)) {
      final novaCaixa = {'id': id, 'local': local, 'observacaoFixa': null};
      caixasExistentesJson.add(json.encode(novaCaixa));
      await prefs.setStringList(_chaveListaCaixasInfo, caixasExistentesJson);
    } else {
      print('Caixa com ID $id já existe. Nenhuma nova caixa foi criada.');
    }
  }

  Future<List<Map<String, dynamic>>> getTodasCaixasComLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dadosJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    return dadosJson.map((e) => Map<String, dynamic>.from(json.decode(e) as Map)).toList();
  }

  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson.map((str) => json.decode(str) as Map<String, dynamic>).toList();
    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);
    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal;
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
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
    return caixa.containsKey('observacaoFixa') ? caixa['observacaoFixa'] as String? : null;
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
    return caixasComLocal.map((caixa) => caixa['id'] as String).toList();
  }

  // --- MÉTODO ADICIONARREGISTROPRODUCAO CORRIGIDO PARA ATUALIZAÇÃO ---
  Future<bool> adicionarRegistroProducao(Map<String, dynamic> dadosProducao) async {
    final prefs = await SharedPreferences.getInstance();
    String caixaId = dadosProducao['caixaId'] as String;
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesDaCaixaJson = prefs.getStringList(chaveProducaoCaixa) ?? [];

    String? idRecebido = dadosProducao['producaoId']?.toString();
    bool isUpdating = false;
    int existingIndex = -1;

    // Se um ID foi recebido, tenta encontrar o registro para atualizar
    if (idRecebido != null && idRecebido.isNotEmpty) {
      for (int i = 0; i < producoesDaCaixaJson.length; i++) {
        try {
          var decodedItem = jsonDecode(producoesDaCaixaJson[i]) as Map<String, dynamic>;
          if (decodedItem['producaoId'] == idRecebido) {
            existingIndex = i;
            isUpdating = true; // Marca que é uma atualização
            break;
          }
        } catch (e) {
          print("HistoricoService: Erro ao decodificar JSON ao procurar ID para atualização: $e. Item: ${producoesDaCaixaJson[i]}");
        }
      }
    }

    // Prepara os dados para salvar, garantindo que o 'producaoId' esteja presente e correto.
    Map<String, dynamic> dadosParaSalvar = Map.from(dadosProducao);

    if (isUpdating && existingIndex != -1) {
      // ATUALIZAR: Substitui o item no índice encontrado
      // O 'producaoId' em dadosParaSalvar já é o correto (veio de dadosProducao que foi preenchido na tela de edição)
      producoesDaCaixaJson[existingIndex] = jsonEncode(dadosParaSalvar);
      print("HistoricoService: Produção ATUALIZADA para $caixaId com ID $idRecebido. Dados: $dadosParaSalvar");
    } else {
      // CRIAR NOVO:
      // Se um ID foi recebido mas não encontrado (isUpdating é false), ou nenhum ID foi recebido.
      if (idRecebido != null && idRecebido.isNotEmpty && !isUpdating) {
        // ID foi passado mas não encontrado na lista. Pode ser um ID antigo/inválido.
        // Para evitar problemas, é mais seguro gerar um NOVO ID para este "novo" registro.
        // Ou, se você tem certeza que o ID é confiável, pode usá-lo, mas há risco de colisão se a busca falhou.
        print("HistoricoService: ID $idRecebido fornecido mas não encontrado. Gerando novo ID para evitar conflitos.");
        String novoProducaoIdGerado = DateTime.now().millisecondsSinceEpoch.toString(); // Ou Uuid().v4()
        dadosParaSalvar['producaoId'] = novoProducaoIdGerado; // Sobrescreve o ID inválido/não encontrado
      } else if (idRecebido == null || idRecebido.isEmpty) {
        // Nenhum ID foi fornecido, então é uma criação de novo registro. Gerar ID.
        String novoProducaoIdGerado = DateTime.now().millisecondsSinceEpoch.toString(); // Ou Uuid().v4()
        dadosParaSalvar['producaoId'] = novoProducaoIdGerado;
      }
      // Se idRecebido existe, não está vazio, mas isUpdating é false (não encontrado),
      // e não entramos nos ifs acima para gerar novo ID, significa que estamos usando o idRecebido.
      // Isso é aceitável se você confia que esse ID é novo para a lista.
      // O mais seguro é sempre garantir que 'producaoId' está em dadosParaSalvar.
      if (dadosParaSalvar['producaoId'] == null || (dadosParaSalvar['producaoId'] as String).isEmpty) {
        dadosParaSalvar['producaoId'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      producoesDaCaixaJson.add(jsonEncode(dadosParaSalvar));
      print("HistoricoService: Produção ADICIONADA para $caixaId com ID ${dadosParaSalvar['producaoId']}. Dados: $dadosParaSalvar");
    }

    bool sucesso = await prefs.setStringList(chaveProducaoCaixa, producoesDaCaixaJson);

    if (!sucesso) {
      print("HistoricoService: FALHA ao ${isUpdating ? 'atualizar' : 'adicionar'} produção para $caixaId no SharedPreferences.");
    }
    return sucesso;
  }


  Future<List<Map<String, dynamic>>> getRegistrosProducaoDaCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    final List<String>? producoesJson = prefs.getStringList(chaveProducaoCaixa);

    if (producoesJson == null || producoesJson.isEmpty) {
      // print("HistoricoService: Nenhum registro de produção encontrado para $caixaId");
      return [];
    }

    final List<Map<String, dynamic>> producoes = [];
    for (String jsonString in producoesJson) {
      try {
        producoes.add(jsonDecode(jsonString) as Map<String, dynamic>);
      } catch (e) {
        print("HistoricoService: Erro ao decodificar JSON ao buscar registros: $e. Item: $jsonString");
        // Pular item malformado
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

    // print("HistoricoService: ${producoes.length} registros de produção encontrados para $caixaId");
    return producoes;
  }

  Future<bool> removerRegistroProducao(String caixaId, String producaoId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveProducaoCaixa = '$_chaveBaseProducao$caixaId';
    List<String> producoesDaCaixaJson = prefs.getStringList(chaveProducaoCaixa) ?? [];

    if (producoesDaCaixaJson.isEmpty) {
      print("HistoricoService: Tentativa de remover produção de uma lista vazia para $caixaId.");
      return false;
    }

    int initialLength = producoesDaCaixaJson.length;
    List<String> producoesAtualizadasJson = [];
    bool removido = false;

    for (String jsonString in producoesDaCaixaJson) {
      try {
        var decodedItem = jsonDecode(jsonString) as Map<String, dynamic>;
        if (decodedItem['producaoId'] == producaoId) {
          removido = true; // Marca que o item foi encontrado e será pulado
        } else {
          producoesAtualizadasJson.add(jsonString); // Adiciona os outros itens à nova lista
        }
      } catch (e) {
        print("HistoricoService: Erro ao decodificar JSON durante a remoção: $e. Item: $jsonString");
        producoesAtualizadasJson.add(jsonString); // Mantém item malformado se não for o de exclusão
      }
    }

    if (removido) {
      bool sucesso = await prefs.setStringList(chaveProducaoCaixa, producoesAtualizadasJson);
      if (sucesso) {
        print("HistoricoService: Registro de produção $producaoId removido para $caixaId.");
      } else {
        print("HistoricoService: Falha ao salvar lista após remover produção $producaoId para $caixaId.");
      }
      return sucesso;
    } else {
      print("HistoricoService: Registro de produção $producaoId NÃO encontrado para remoção em $caixaId.");
      return false; // Não encontrou, nada foi alterado efetivamente
    }
  }

  Future getTodosOsRegistrosDeProducaoComLocal() async {}
}



