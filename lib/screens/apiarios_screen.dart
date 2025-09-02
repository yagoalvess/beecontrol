import 'package:flutter/material.dart';
import 'caixa_screen.dart';
import 'gerar_qrcode_screen.dart';
import 'package:abelhas/services/historico_service.dart';

class ApiariosScreen extends StatefulWidget {
  const ApiariosScreen({super.key});

  @override
  _ApiariosScreenState createState() => _ApiariosScreenState();
}

class _ApiariosScreenState extends State<ApiariosScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _todasAsCaixas = [];
  List<Map<String, dynamic>> _caixasFiltradas = [];

  final List<String> _locaisPreDefinidos = const [
    'Apiário Central',
    'Apiário do Sul',
    'Apiário Experimental',
    'Apiário da Mata',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCaixas();
    _searchController.addListener(_filterCaixas);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCaixas);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCaixas() async {
    final caixas = await HistoricoService().getTodasCaixasComLocal();
    setState(() {
      _todasAsCaixas = caixas;
      _caixasFiltradas = caixas;
    });
  }

  void _filterCaixas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _caixasFiltradas = _todasAsCaixas.where((caixa) {
        final id = caixa['id'] as String? ?? '';
        final local = caixa['local'] as String? ?? '';
        final displayId = id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
        return id.toLowerCase().contains(query) ||
            local.toLowerCase().contains(query) ||
            displayId.contains(query);
      }).toList();
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
      const SnackBar(content: Text('Histórico da Colmeia excluído com sucesso!')),
    );
    _fetchCaixas();
  }

  Future<void> _editarCaixa(String caixaId, String localAtual) async {
    final historicoService = HistoricoService();
    String? novoLocal = await _showInputDialog(
      context,
      'Editar Local',
      'Novo nome do local',
      predefinedOptions: _locaisPreDefinidos,
      predefinedText: localAtual,
    );

    if (novoLocal != null && novoLocal.isNotEmpty && novoLocal != localAtual) {
      await historicoService.atualizarLocalDaCaixa(caixaId, novoLocal);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local da colmeia atualizado com sucesso!')),
      );
      _fetchCaixas();
    }
  }

  Future<void> _criarNovaCaixa() async {
    final historicoService = HistoricoService();
    String? localDaNovaCaixa = await _showInputDialog(
      context,
      'Local da Nova Caixa',
      'Digite ou selecione o nome do local',
      predefinedOptions: _locaisPreDefinidos,
    );

    if (localDaNovaCaixa != null && localDaNovaCaixa.isNotEmpty) {
      String novoId = await historicoService.gerarNovoId();
      await historicoService.criarCaixa(novoId, localDaNovaCaixa);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GerarQRCodeScreen(novoId: novoId)),
      );
      _fetchCaixas();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Criação de caixa de colmeia cancelada. Local não informado.')),
      );
    }
  }

  Future<String?> _showInputDialog(
      BuildContext context,
      String title,
      String hintText, {
        List<String>? predefinedOptions,
        String? predefinedText,
      }) async {
    TextEditingController controller = TextEditingController(text: predefinedText);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (predefinedOptions != null && predefinedOptions.isNotEmpty) ...[
                  ...predefinedOptions.map((option) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                        title: Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                        onTap: () {
                          Navigator.of(context).pop(option);
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    labelText: 'Nome do Local',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.edit_location_alt, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
        title: const Text('Minhas Produções'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
            ),
          ),
          Expanded(
            child: _caixasFiltradas.isEmpty && _searchController.text.isEmpty
                ? const Center(child: Text('Nenhuma colmeia salva ainda.'))
                : _caixasFiltradas.isEmpty
                ? const Center(child: Text('Nenhum resultado encontrado.'))
                : ListView.builder(
              itemCount: _caixasFiltradas.length,
              itemBuilder: (context, index) {
                final caixaData = _caixasFiltradas[index];
                final String id = caixaData['id'] ?? 'ID Desconhecido';
                final String local = caixaData['local']?.isNotEmpty == true
                    ? caixaData['local']!
                    : 'Local Desconhecido';
                String displayId = id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Dismissible(
                    key: Key(id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Excluir Colmeia"),
                          content: const Text("Tem certeza que deseja excluir todo o histórico dessa colmeia?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("Excluir", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      await _excluirCaixa(id);
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.hive_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                        title: Text(
                          'Colmeia-$displayId',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Local: $local'),
                        onTap: () => _navegarParaCaixa(context, id, local),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarCaixa(id, local),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criarNovaCaixa,
        label: const Text('NOVA PRODUÇÃO'),
        icon: const Icon(Icons.edit),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}