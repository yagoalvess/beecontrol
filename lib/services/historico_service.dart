import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoService {
  // 🔹 Recupera histórico de anotações de uma caixa
  Future<List<Map<String, String>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = 'historico_$caixaId';
    final dados = prefs.getStringList(chave) ?? [];
    return dados.map((e) => Map<String, String>.from(json.decode(e))).toList();
  }

  // 🔹 Adiciona uma nova anotação ao histórico
  Future<void> adicionarHistorico(String caixaId, String descricao) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = 'historico_$caixaId';
    final dados = prefs.getStringList(chave) ?? [];

    final now = DateTime.now();
    final entrada = {
      'descricao': descricao,
      'data': '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
      'hora': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    };

    dados.add(json.encode(entrada));
    await prefs.setStringList(chave, dados);
  }

  // ✅ Remove uma anotação do histórico
  Future<void> removerHistorico(String caixaId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final chave = 'historico_$caixaId';
    final dados = prefs.getStringList(chave) ?? [];

    if (index >= 0 && index < dados.length) {
      dados.removeAt(index);
      await prefs.setStringList(chave, dados);
    }
  }

  // ✅ Gera um novo ID para caixa (ex: cx-01, cx-02, ...)
  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixas();
    int numero = caixas.length + 1;
    return 'cx-${numero.toString().padLeft(2, '0')}';
  }

  // ✅ Cria uma nova caixa no sistema
  Future<void> criarCaixa(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final chaveLista = 'todas_caixas';
    final caixas = prefs.getStringList(chaveLista) ?? [];

    if (!caixas.contains(id)) {
      caixas.add(id);
      await prefs.setStringList(chaveLista, caixas);
    }
  }

  // ✅ Retorna a lista de todas as caixas existentes
  Future<List<String>> getTodasCaixas() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('todas_caixas') ?? [];
  }
}
