// ARQUIVO ATUALIZADO E FINAL: C:/Users/Usuario/Documents/GitHub/beecontrol/lib/screens/apiarios_screen.dart

import 'package:flutter/material.dart';
import 'dart:async'; // Para Timer (debounce)
import 'caixa_screen.dart';
import 'package:abelhas/services/historico_service.dart';

class ApiariosScreen extends StatefulWidget {
  const ApiariosScreen({super.key});

  @override
  _ApiariosScreenState createState() => _ApiariosScreenState();
}

class _ApiariosScreenState extends State<ApiariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _todasAsCaixas = [];
  Map<String, List<Map<String, dynamic>>> _caixasAgrupadasPorLocal = {};
  List<String> _locaisOrdenados = [];

  // ## INÍCIO DA ALTERAÇÃO 1/6 (NOVO) ##
  List<String> _todosOsLocaisPersistentes = [];
  // ## FIM DA ALTERAÇÃO 1/6 ##

  bool _isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAndGroupCaixas();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ## INÍCIO DA ALTERAÇÃO 2/6 (MODIFICADO) ##
  Future<void> _fetchAndGroupCaixas() async {
    if (mounted) setState(() => _isLoading = true);

    final historicoService = HistoricoService();
    // Busca as duas listas em paralelo para otimizar
    final results = await Future.wait([
      historicoService.getTodasCaixasComLocal(),
      historicoService.getTodosOsLocais(),
    ]);

    if (!mounted) return;

    final caixas = results[0] as List<Map<String, dynamic>>;
    final locaisPersistentes = results[1] as List<String>;

    final caixasValidas = caixas.where((caixa) => caixa['id'] != null && caixa['id'].toString().isNotEmpty).toList();

    _todasAsCaixas = caixasValidas;
    _todosOsLocaisPersistentes = locaisPersistentes;
    _filterCaixas();
  }
  // ## FIM DA ALTERAÇÃO 2/6 ##

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _filterCaixas();
      }
    });
  }

  // ## INÍCIO DA ALTERAÇÃO 3/6 (REESTRUTURADO) ##
  void _filterCaixas() {
    if (!mounted) return;

    final query = _searchController.text.trim();
    Map<String, List<Map<String, dynamic>>> agrupadasResultado = {};

    // Inicia o mapa de resultados com TODOS os locais persistentes, cada um com uma lista vazia.
    for (var local in _todosOsLocaisPersistentes) {
      agrupadasResultado[local] = [];
    }

    List<Map<String, dynamic>> listaParaFiltrar = _todasAsCaixas;

    // A lógica de filtragem por busca continua a mesma, atuando sobre as CAIXAS
    if (query.isNotEmpty) {
      final isNumericQuery = int.tryParse(query) != null;
      listaParaFiltrar = _todasAsCaixas.where((caixa) {
        final id = caixa['id'] as String? ?? '';
        final local = caixa['local'] as String? ?? '';
        final queryLowerCase = query.toLowerCase();
        if (isNumericQuery) {
          final String numeroId = id.replaceAll(RegExp(r'[^0-9]'), '');
          final int? numeroIdInt = int.tryParse(numeroId);
          if (numeroIdInt != null && numeroIdInt.toString() == query) {
            return true;
          }
        }
        if (!isNumericQuery) {
          return local.toLowerCase().contains(queryLowerCase) || id.toLowerCase().contains(queryLowerCase);
        }
        return false;
      }).toList();
    }

    // Popula o mapa de resultados com as caixas (já filtradas ou todas)
    for (var caixa in listaParaFiltrar) {
      final local = caixa['local']?.toString() ?? 'Local não definido';
      if (agrupadasResultado.containsKey(local)) {
        agrupadasResultado[local]!.add(caixa);
      } else {
        agrupadasResultado[local] = [caixa];
      }
    }

    List<String> locaisFinais;
    // Se houver uma busca ativa, mostramos apenas os locais que têm caixas correspondentes.
    if (query.isNotEmpty) {
      locaisFinais = agrupadasResultado.keys.where((local) => agrupadasResultado[local]!.isNotEmpty).toList();
    } else {
      // Se não houver busca, a lista de locais a exibir é a lista completa e persistente.
      locaisFinais = _todosOsLocaisPersistentes;
    }

    // Mantendo a ordenação original do seu código.
    locaisFinais.sort();

    if (locaisFinais.contains('Local não definido')) {
      locaisFinais.remove('Local não definido');
      locaisFinais.add('Local não definido');
    }

    setState(() {
      _caixasAgrupadasPorLocal = agrupadasResultado;
      _locaisOrdenados = locaisFinais;
      _isLoading = false;
    });
  }
  // ## FIM DA ALTERAÇÃO 3/6 ##

  void _navegarParaCaixa(BuildContext context, String caixaId, String localCaixa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaixaScreen(
          caixaId: caixaId,
          localCaixa: localCaixa,
        ),
      ),
      // O .then() que recarregava a tela foi removido para manter o código original.
      // O recarregamento agora deve ser feito manualmente pelo usuário se necessário (ex: voltando para a home e abrindo a tela de novo).
    );
  }

  Future<void> _excluirCaixa(String caixaId) async {
    final historicoService = HistoricoService();
    await historicoService.removerCaixa(caixaId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Colmeia excluída com sucesso!')),
    );
    _fetchAndGroupCaixas();
  }

  // ## INÍCIO DA ALTERAÇÃO 4/6 (NOVO) ##
  Future<void> _excluirLocal(String local) async {
    final historicoService = HistoricoService();
    await historicoService.removerLocalPermanente(local);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Local "$local" excluído com sucesso!')),
    );
    _fetchAndGroupCaixas();
  }
  // ## FIM DA ALTERAÇÃO 4/6 ##

  Future<void> _editarCaixa(String caixaId, String localAtual) async {
    String? novoLocal = await _showSimpleInputDialog(
      context,
      'Editar Local da Colmeia',
      'Novo nome do local',
      initialValue: localAtual,
    );
    if (!mounted) return;

    if (novoLocal != null && novoLocal.trim().isNotEmpty && novoLocal.trim().toLowerCase() != localAtual.toLowerCase().trim()) {
      final historicoService = HistoricoService();
      await historicoService.atualizarLocalDaCaixa(caixaId, novoLocal.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local da colmeia atualizado com sucesso!')),
      );
      _fetchAndGroupCaixas();
    }
  }

  Future<String?> _showSimpleInputDialog(
      BuildContext context,
      String title,
      String hintText, {
        String? initialValue,
      }) async {
    TextEditingController controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (BuildContext alertContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText, labelText: 'Nome do Local'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(alertContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(alertContext).pop(controller.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ## INÍCIO DA ALTERAÇÃO 5/6 (MODIFICADO) ##
    // A condição para mostrar a tela vazia agora verifica a lista de locais persistentes.
    final bool shouldShowEmptyScreen = _todosOsLocaisPersistentes.isEmpty && _searchController.text.isEmpty && !_isLoading;
    // ## FIM DA ALTERAÇÃO 5/6 ##

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Colmeias'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por ID ou Local...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Limpar busca',
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: shouldShowEmptyScreen // <-- Variável usada aqui
                ? const Center(child: Text('Nenhuma colmeia salva ainda.\nCrie novas colmeias na tela inicial.'))
                : _locaisOrdenados.isEmpty && !_isLoading
                ? Center(child: Text('Nenhum resultado para "${_searchController.text}".'))
                : ListView.builder(
              itemCount: _locaisOrdenados.length,
              padding: const EdgeInsets.only(bottom: 16.0),
              itemBuilder: (context, indexLocal) {
                final local = _locaisOrdenados[indexLocal];
                final caixasDoLocal = _caixasAgrupadasPorLocal[local] ?? [];

                // ## INÍCIO DA ALTERAÇÃO 6/6 (WIDGET ENVOLVIDO COM DISMISSIBLE) ##
                return Dismissible(
                  key: ValueKey('local_$local'), // Chave única para o Dismissible do local
                  direction: caixasDoLocal.isEmpty ? DismissDirection.endToStart : DismissDirection.none, // Só permite arrastar se estiver vazio
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4.0), // Combina com a borda do Card
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0), // Mesmo margin do Card
                    child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text("Excluir Local"),
                          content: Text('Tem certeza que deseja excluir o local "$local"? Esta ação não pode ser desfeita.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(true),
                              child: Text("Excluir", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            ),
                          ],
                        );
                      },
                    ) ?? false;
                  },
                  onDismissed: (direction) {
                    _excluirLocal(local);
                  },
                  child: Card(
                    // O Card original agora é filho do Dismissible
                    key: ValueKey(local),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: ExpansionTile(
                      initiallyExpanded: _searchController.text.isNotEmpty,
                      title: Text('$local (${caixasDoLocal.length})', style: Theme.of(context).textTheme.titleLarge),
                      children: caixasDoLocal.isEmpty
                          ? [
                        const Padding( // Mensagem para locais vazios
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text("Nenhuma colmeia neste local.", style: TextStyle(fontStyle: FontStyle.italic)),
                        )
                      ]
                          : [ // O `children` original do seu código
                        const Divider(height: 1),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: caixasDoLocal.length,
                          itemBuilder: (context, indexCaixa) {
                            final caixaData = caixasDoLocal[indexCaixa];
                            final String id = caixaData['id'] as String? ?? 'N/A';
                            final String localCaixa = caixaData['local'] as String? ?? 'Local Desconhecido';
                            String displayId = id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
                            if (id == 'N/A') displayId = 'ID Inválido';

                            return Dismissible(
                              key: Key(id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
                                child: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext dialogContextConfirm) {
                                    return AlertDialog(
                                      title: const Text("Excluir Colmeia"),
                                      content: Text('Tem certeza que deseja excluir a Colmeia-$displayId e todo o seu histórico? Esta ação não pode ser desfeita.'),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContextConfirm).pop(false),
                                          child: const Text("Cancelar"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(dialogContextConfirm).pop(true),
                                          child: Text("Excluir", style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                        ),
                                      ],
                                    );
                                  },
                                ) ?? false;
                              },
                              onDismissed: (direction) {
                                _excluirCaixa(id);
                              },
                              child: ListTile(
                                leading: const Icon(Icons.hive),
                                title: Text('Colmeia-$displayId', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(localCaixa),
                                onTap: () => _navegarParaCaixa(context, id, localCaixa),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_note_outlined),
                                  tooltip: 'Editar Local',
                                  onPressed: () => _editarCaixa(id, localCaixa),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
                // ## FIM DA ALTERAÇÃO 6/6 ##
              },
            ),
          ),
        ],
      ),
    );
  }
}
