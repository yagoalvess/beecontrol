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

  Future<void> _fetchAndGroupCaixas() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    } else {
      _isLoading = true;
    }

    final historicoService = HistoricoService();
    final caixas = await historicoService.getTodasCaixasComLocal();
    if (!mounted) return;

    final caixasValidas = caixas.where((caixa) => caixa['id'] != null && caixa['id'].toString().isNotEmpty).toList();

    _todasAsCaixas = caixasValidas;
    _filterCaixas();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _filterCaixas();
      }
    });
  }

  void _filterCaixas() {
    if (!mounted) return;

    final query = _searchController.text.toLowerCase();
    Map<String, List<Map<String, dynamic>>> agrupadasResultado = {};
    List<String> locaisResultado = [];

    List<Map<String, dynamic>> listaParaFiltrar = _todasAsCaixas;

    if (query.isNotEmpty) {
      listaParaFiltrar = _todasAsCaixas.where((caixa) {
        final id = caixa['id'] as String? ?? '';
        final local = caixa['local'] as String? ?? '';
        final displayId = id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
        return id.toLowerCase().contains(query) ||
            local.toLowerCase().contains(query) ||
            displayId.contains(query);
      }).toList();
    }

    for (var caixa in listaParaFiltrar) {
      final local = caixa['local']?.toString() ?? 'Local não definido';
      if (!agrupadasResultado.containsKey(local)) {
        agrupadasResultado[local] = [];
      }
      agrupadasResultado[local]!.add(caixa);
    }
    locaisResultado = agrupadasResultado.keys.toList()..sort();

    if (locaisResultado.contains('Local não definido')) {
      locaisResultado.remove('Local não definido');
      locaisResultado.add('Local não definido');
    }

    setState(() {
      _caixasAgrupadasPorLocal = agrupadasResultado;
      _locaisOrdenados = locaisResultado;
      _isLoading = false;
    });
  }

  void _navegarParaCaixa(BuildContext context, String caixaId, String localCaixa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaixaScreen(
          caixaId: caixaId,
          localCaixa: localCaixa,
        ),
      ),
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
            child: _caixasAgrupadasPorLocal.isEmpty && _searchController.text.isEmpty && !_isLoading
                ? const Center(child: Text('Nenhuma colmeia salva ainda.\nCrie novas colmeias na tela inicial.'))
                : _caixasAgrupadasPorLocal.isEmpty && !_isLoading
                ? Center(child: Text('Nenhum resultado para "${_searchController.text}".'))
                : ListView.builder(
              itemCount: _locaisOrdenados.length,
              padding: const EdgeInsets.only(bottom: 16.0),
              itemBuilder: (context, indexLocal) {
                final local = _locaisOrdenados[indexLocal];
                final caixasDoLocal = _caixasAgrupadasPorLocal[local]!;
                return Card(
                  key: ValueKey(local),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    title: Text('$local - ${caixasDoLocal.length}', style: Theme.of(context).textTheme.titleLarge),
                    children: [
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

                          // **** DISMISSIBLE RESTAURADO ****
                          return Dismissible(
                            key: Key(id), // Essencial para Dismissible
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.9), // Cor do fundo ao arrastar
                                borderRadius: BorderRadius.circular(8.0), // Ajuste o raio se o ListTile/Card tiver bordas arredondadas
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0), // Garante que o fundo não exceda o item
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
                              ) ?? false; // Retorna false se o diálogo for dispensado (ex: toque fora)
                            },
                            onDismissed: (direction) {
                              _excluirCaixa(id);
                            },
                            child: ListTile( // O ListTile é o filho direto do Dismissible
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
                          // **** FIM DO DISMISSIBLE RESTAURADO ****
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
