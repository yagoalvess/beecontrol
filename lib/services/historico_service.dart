import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HistoricoService {
  Future<List<Map<String, String>>> getHistorico(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(caixaId);
    if (data == null) return [];
    final List<dynamic> json = jsonDecode(data);
    return json.map((item) => Map<String, String>.from(item)).toList();
  }

  Future<void> adicionarHistorico(String caixaId, String descricao) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final entrada = {
      'data': DateFormat('yyyy-MM-dd').format(now),
      'hora': DateFormat('HH:mm').format(now),
      'descricao': descricao,
    };
    final historico = await getHistorico(caixaId);
    historico.insert(0, entrada);
    await prefs.setString(caixaId, jsonEncode(historico));
  }

  Future<void> criarCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(caixaId, jsonEncode([]));
    final todas = await getTodasCaixas();
    if (!todas.contains(caixaId)) {
      todas.add(caixaId);
      await prefs.setString('lista_caixas', jsonEncode(todas));
    }
  }

  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixas();
    int proximo = caixas.length + 1;
    return 'CAIXA-${proximo.toString().padLeft(3, '0')}';
  }

  Future<List<String>> getTodasCaixas() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('lista_caixas');
    if (data == null) return [];
    return List<String>.from(jsonDecode(data));
  }
}
