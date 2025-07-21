import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoService {
  // Chave para armazenar as informações das caixas (ID e Local)
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
  // Este método agora usa getTodasCaixasComLocal para determinar o número
  Future<String> gerarNovoId() async {
    final caixas = await getTodasCaixasComLocal(); // Modificado para usar a nova função
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
      final novaCaixa = {'id': id, 'local': local};
      caixasExistentesJson.add(json.encode(novaCaixa));
      await prefs.setStringList(_chaveListaCaixasInfo, caixasExistentesJson);
    } else {
      // Opcional: Lidar com o caso de ID duplicado
      // Pode lançar uma exceção, retornar um booleano, ou atualizar o local se essa for a intenção.
      print('Caixa com ID $id já existe. Nenhuma nova caixa foi criada.');
      // Exemplo de como poderia atualizar o local se o ID já existir:
      // await atualizarLocalDaCaixa(id, local);
    }
  }

  // ✅ Retorna a lista de todas as caixas existentes com ID e Local
  Future<List<Map<String, String>>> getTodasCaixasComLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dadosJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    // É importante garantir que o mapa decodificado seja do tipo correto.
    return dadosJson
        .map((e) => Map<String, String>.from(json.decode(e) as Map))
        .toList();
  }

  // Novo método: ✅ Atualiza o local de uma caixa existente
  Future<bool> atualizarLocalDaCaixa(String caixaId, String novoLocal) async {
    final prefs = await SharedPreferences.getInstance();
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];

    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    int indexDaCaixa = caixas.indexWhere((caixa) => caixa['id'] == caixaId);

    if (indexDaCaixa != -1) {
      caixas[indexDaCaixa]['local'] = novoLocal;
      // Converte de volta para lista de strings JSON
      final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
      await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);
      return true; // Sucesso
    }
    return false; // Caixa não encontrada
  }

  // Novo método: ✅ Remove uma caixa e seu histórico
  Future<void> removerCaixa(String caixaId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Remover a caixa da lista de informações de caixas
    final caixasJson = prefs.getStringList(_chaveListaCaixasInfo) ?? [];
    List<Map<String, dynamic>> caixas = caixasJson
        .map((str) => json.decode(str) as Map<String, dynamic>)
        .toList();

    caixas.removeWhere((caixa) => caixa['id'] == caixaId);

    final novasCaixasJson = caixas.map((caixa) => json.encode(caixa)).toList();
    await prefs.setStringList(_chaveListaCaixasInfo, novasCaixasJson);

    // 2. Remover o histórico associado a essa caixa
    final chaveHistorico = '$_chaveBaseHistorico$caixaId';
    await prefs.remove(chaveHistorico); // Remove a chave do histórico
  }

  // Para compatibilidade, se você ainda precisar de uma lista apenas com os IDs.
  // Pode ser útil em alguns cenários, mas getTodasCaixasComLocal é mais completo.
  Future<List<String>> getTodosOsIdsDeCaixas() async {
    final caixasComLocal = await getTodasCaixasComLocal();
    return caixasComLocal.map((caixa) => caixa['id']!).toList();
  }
}
