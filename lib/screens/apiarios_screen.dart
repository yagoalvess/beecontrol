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
  final HistoricoService _historicoService = HistoricoService();

  List<Map<String, dynamic>> _todasAsCaixas = [];
  List<String> _todosOsLocaisSalvos = []; 
  
  Map<String, List<Map<String, dynamic>>> _caixasAgrupadasFiltradas = {};
  List<String> _locaisOrdenadosParaExibicao = [];

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
    if (mounted) setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _historicoService.getTodasCaixasComLocal(),
        _historicoService.getTodosOsLocais(),
      ]);

      if (!mounted) return;

      final caixas = results[0] as List<Map<String, dynamic>>;
      final locais = results[1] as List<String>;

      final caixasValidas = caixas
          .where((caixa) => caixa['id'] != null && caixa['id'].toString().isNotEmpty)
          .toList();

      setState(() {
        _todasAsCaixas = caixasValidas;
        _todosOsLocaisSalvos = locais;
        _filterCaixas();
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}'))
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _filterCaixas();
      }
    });
  }

  void _filterCaixas() {
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();
    
    final Map<String, List<Map<String, dynamic>>> caixasAgrupadas = {};
    for (var caixa in _todasAsCaixas) {
      final local = caixa['local']?.toString() ?? 'Local não definido';
      caixasAgrupadas.putIfAbsent(local, () => []).add(caixa);
    }
    
    List<String> locaisParaExibir;
    if (query.isEmpty) {
      locaisParaExibir = List.from(_todosOsLocaisSalvos);
      _caixasAgrupadasFiltradas = caixasAgrupadas;
    } else {
      final List<Map<String, dynamic>> caixasFiltradas = _todasAsCaixas.where((caixa) {
        final id = (caixa['id'] as String? ?? '').toLowerCase();
        final local = (caixa['local'] as String? ?? '').toLowerCase();
        
        final numericId = id.replaceAll(RegExp(r'[^0-9]'), '');
        final queryAsInt = int.tryParse(query);
        final idAsInt = int.tryParse(numericId);

        if (queryAsInt != null && idAsInt != null) {
          return idAsInt == queryAsInt;
        }
        
        return local.contains(query) || id.contains(query);
      }).toList();

      final Map<String, List<Map<String, dynamic>>> caixasAgrupadasQuery = {};
       for (var caixa in caixasFiltradas) {
        final local = caixa['local']?.toString() ?? 'Local não definido';
        caixasAgrupadasQuery.putIfAbsent(local, () => []).add(caixa);
      }
      
      locaisParaExibir = caixasAgrupadasQuery.keys.toList();
      _caixasAgrupadasFiltradas = caixasAgrupadasQuery;
    }

    locaisParaExibir.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    
    if (locaisParaExibir.contains('Local não definido')) {
      locaisParaExibir.remove('Local não definido');
      locaisParaExibir.add('Local não definido');
    }

    setState(() {
      _locaisOrdenadosParaExibicao = locaisParaExibir;
      _isLoading = false;
    });
  }

  void _navegarParaCaixa(BuildContext context, String caixaId, String localCaixa) async {
    final bool? recarregar = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CaixaScreen(
          caixaId: caixaId,
          localCaixa: localCaixa,
        ),
      ),
    );

    if (recarregar == true && mounted) {
      _fetchAndGroupCaixas();
    }
  }

  Future<void> _excluirCaixa(String caixaId) async {
    await _historicoService.removerCaixa(caixaId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Colmeia excluída com sucesso!')),
    );
    _fetchAndGroupCaixas();
  }

  // ===================================================================
  // **[NOVA FUNÇÃO]** - Para excluir um local/apiário vazio
  // ===================================================================
  Future<void> _excluirLocalVazio(String local) async {
    final bool success = await _historicoService.removerLocalPermanente(local);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apiário "$local" excluído com sucesso!')),
      );
      _fetchAndGroupCaixas(); 
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir o apiário "$local".')),
      );
    }
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
      await _historicoService.atualizarLocalDaCaixa(caixaId, novoLocal.trim());
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar Lista',
            onPressed: _fetchAndGroupCaixas,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            child: !_isLoading && _todosOsLocaisSalvos.isEmpty
                ? const Center(
                    child: Text('Nenhum apiário criado ainda.\nCrie novos apiários na tela inicial.', textAlign: TextAlign.center,)
                  )
                : !_isLoading && _locaisOrdenadosParaExibicao.isEmpty && _searchController.text.isNotEmpty
                ? Center(child: Text('Nenhum resultado para "${_searchController.text}".'))
                : ListView.builder(
              itemCount: _locaisOrdenadosParaExibicao.length,
              padding: const EdgeInsets.only(bottom: 16.0),
              itemBuilder: (context, indexLocal) {
                final local = _locaisOrdenadosParaExibicao[indexLocal];
                final caixasDoLocal = _caixasAgrupadasFiltradas[local] ?? [];
                final bool isLocalVazio = caixasDoLocal.isEmpty;
                
                // ===================================================================
                // **[CORREÇÃO]** - Envolve o Card com Dismissible para apagar locais vazios
                // ===================================================================
                return Dismissible(
                  key: ValueKey(local),
                  direction: isLocalVazio ? DismissDirection.endToStart : DismissDirection.none,
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: const Icon(Icons.delete_forever_outlined, color: Colors.white, size: 28),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text("Excluir Apiário Vazio"),
                          content: Text('Tem certeza que deseja excluir o apiário "$local"? Esta ação não pode ser desfeita.'),
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
                    _excluirLocalVazio(local);
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: ExpansionTile(
                      initiallyExpanded: _locaisOrdenadosParaExibicao.length == 1,
                      title: Text('$local (${caixasDoLocal.length})', style: Theme.of(context).textTheme.titleLarge),
                      children: [
                        if (caixasDoLocal.isEmpty)
                          const ListTile(
                            leading: Icon(Icons.info_outline, color: Colors.grey),
                            title: Text('Nenhuma colmeia neste apiário.'),
                          )
                        else
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
                                leading: const Icon(Icons.hive_outlined),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}