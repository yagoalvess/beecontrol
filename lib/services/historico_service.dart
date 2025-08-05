// lib/services/historico_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoService {
  // Chave para armazenar as informações das caixas (ID, Local e Observação Fixa)
  static const _chaveListaCaixasInfo = 'todas_caixas_info';
  // Chave base para o histórico de cada caixa
  static const _chaveBaseHistorico = 'historico_';

  // 🔹 Recupera histórico de anotações de uma caixa
  Future<List<Map<String, String>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];
    return dados.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  // 🔹 Adiciona uma nova anotação ao histórico
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

  // ✅ Remove uma anotação do histórico
  Future<void> removerHistorico(String caixaId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    final dados = prefs.getStringList(chaveHistorico) ?? [];

    if (index >= 0 && index < dados.length) {
      dados.removeAt(index);
      await prefs.setStringList(chaveHistorico, dados);
    }
  }

  // ✅ Gera um novo ID para caixa (ex: cx-01, cx-02, ...)
  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixasComLocal();
    int numero = caixas.length + 1;
    return 'cx-${numero.toString().padLeft(2, '0')}';
  }

  // ✅ Cria uma nova caixa no sistema com ID e Local
  Future<void> criarCaixa(String id, String local) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasExistentesJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];

    final caixasExistentes = caixasExistentesJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    // Verifica se uma caixa com o mesmo ID já existe
    if (!caixasExistentes.any((caixa) => caixa['id'] == id)) {
      // Adicionando um campo 'observacaoFixa' com valor nulo por padrão
      final novaCaixa = {'id': id, 'local': local, 'observacaoFixa': null};
      caixasExistentesJson.add(json.encode(novaCaixa));
      await prefs.setStringList(_chaveListaCaixasInfo, caixasExistentesJson);
    } else {
      print('Caixa com ID $id já existe. Nenhuma nova caixa foi criada.');
    }
  }

  // ✅ Retorna a lista de todas as caixas existentes com ID e Local
  // Este método agora também retorna a 'observacaoFixa'
  Future<List<Map<String, dynamic>>> getTodasCaixasComLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dadosJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    return dadosJson
        .map((e) => Map<String, dynamic>.from(json.decode(e) as Map))
        .toList();
  }

  // ✅ Atualiza o local de uma caixa existente
  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];

    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);

    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal;
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
      return true;
    }
    return false;
  }

  // ✅ Remove uma caixa e seu histórico
  Future<void> removerCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();

    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    caixas.removeWhere((caixa) => caixa['id'] == caixaId);

    final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
    await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);

    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    await prefs.remove(chaveHistorico);
  }

  // ✅ Retorna a observação fixa de uma caixa
  Future<String?> getObservacaoFixa(String caixaId) async {
    final caixas = await getTodasCaixasComLocal();
    final caixa = caixas.firstWhere(
          (c) => c['id'] == caixaId,
      orElse: () => {},
    );
    // Retorna a observação ou null se não existir
    return caixa.containsKey('observacaoFixa') ? caixa['observacaoFixa'] as String? : null;
  }

  // ✅ Salva ou atualiza a observação fixa de uma caixa
  Future<void> salvarObservacaoFixa(String caixaId, String? observacao) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];

    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);

    if (indexDaCaixa != -1) {
      // Atualiza o campo 'observacaoFixa'
      caixas[indexDaCaixa]['observacaoFixa'] = observacao;
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
    }
  }

  Future<List<String>> getTodosOsIdsDeCaixas() async {
    final caixasComLocal = await getTodasCaixasComLocal();
    return caixasComLocal.map((caixa) => caixa['id'] as String).toList();
  }
}