import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart'; // Certifique-se que o caminho está correto
import 'package:intl/intl.dart';
import 'package:abelhas/screens/registrar_producao_screen.dart';

// --- Utilitários ---
Future<bool> showAppConfirmDialog(
    BuildContext context, {
      required String title,
      required String content,
      String confirmButtonText = 'Excluir',
      String cancelButtonText = 'Cancelar',
    }) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          TextButton(
              child: Text(cancelButtonText),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              }
          ),
          TextButton(
              child: Text(
                confirmButtonText,
                style: TextStyle(
                    color: confirmButtonText.toLowerCase() == 'excluir' ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              }
          ),
        ],
      );
    },
  ) ??
      false;
}

String formatDisplayDate(DateTime? date) {
  if (date == null) return "N/D";
  return DateFormat('dd/MM/yyyy').format(date);
}
// --- Fim dos Utilitários ---

class CaixaScreen extends StatefulWidget {
  final String caixaId;
  final String localCaixa;

  const CaixaScreen({
    super.key,
    required this.caixaId,
    required this.localCaixa,
  });

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen>
    with SingleTickerProviderStateMixin {
  final HistoricoService _historicoService = HistoricoService();

  List<Map<String, dynamic>> _historicoItens = [];
  String? _observacaoFixa;
  bool _isLoading = true;
  late String _localAtualDaCaixa;
  List<Map<String, dynamic>> _registrosProducaoDaCaixa = [];

  double _totalMelDaCaixa = 0;
  double _totalGeleiaRealDaCaixa = 0;
  double _totalPropolisDaCaixa = 0;
  double _totalCeraDaCaixa = 0;
  DateTime? _dataProducaoMaisAntigaDaCaixa;
  DateTime? _dataProducaoMaisRecenteDaCaixa;

  static const List<String> _locaisPreDefinidos = [
    'Apiário Central', 'Apiário Morro Alto', 'Apiário de Suzano', 'Bosque das Abelhas',
  ];

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _localAtualDaCaixa = widget.localCaixa;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarDadosIniciais();
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _tabController.index != _currentTabIndex) {
      if (mounted) setState(() => _currentTabIndex = _tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showErrorSnackBar(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _carregarDadosEProcessarRelatorio() async {
    if (!mounted) return;
    if (!_isLoading) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _historicoService.getHistorico(widget.caixaId),
        _historicoService.getObservacaoFixa(widget.caixaId),
        _historicoService.getRegistrosProducaoDaCaixa(widget.caixaId),
      ]);
      if (!mounted) return;

      List<Map<String, dynamic>> historicoCarregado = results[0] as List<Map<String, dynamic>>;
      try {
        historicoCarregado.sort((a, b) {
          DateTime? dateA = DateTime.tryParse(a['timestamp'] as String? ?? '');
          DateTime? dateB = DateTime.tryParse(b['timestamp'] as String? ?? '');
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA); // Mais recente primeiro
        });
      } catch (e) {
        print("Erro ao ordenar histórico durante carregamento: $e");
      }

      setState(() {
        _historicoItens = historicoCarregado;
        _observacaoFixa = results[1] as String?;
        _registrosProducaoDaCaixa = results[2] as List<Map<String, dynamic>>;
        _processarDadosDeProducaoParaRelatorioLocal(_registrosProducaoDaCaixa);
      });
    } catch (e) {
      if (mounted) _showErrorSnackBar("Erro ao carregar dados: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarDadosIniciais() async {
    if (mounted && !_isLoading) setState(() => _isLoading = true);
    await _carregarDadosEProcessarRelatorio();
  }

  void _processarDadosDeProducaoParaRelatorioLocal(List<Map<String, dynamic>> registros) {
    _totalMelDaCaixa = 0;
    _totalGeleiaRealDaCaixa = 0;
    _totalPropolisDaCaixa = 0;
    _totalCeraDaCaixa = 0;
    _dataProducaoMaisAntigaDaCaixa = null;
    _dataProducaoMaisRecenteDaCaixa = null;
    if (registros.isEmpty) return;
    for (var registro in registros) {
      try {
        if (registro['dataProducao'] != null) {
          DateTime dataAtualRegistro = DateTime.parse(registro['dataProducao'] as String);
          if (_dataProducaoMaisAntigaDaCaixa == null || dataAtualRegistro.isBefore(_dataProducaoMaisAntigaDaCaixa!)) {
            _dataProducaoMaisAntigaDaCaixa = dataAtualRegistro;
          }
          if (_dataProducaoMaisRecenteDaCaixa == null || dataAtualRegistro.isAfter(_dataProducaoMaisRecenteDaCaixa!)) {
            _dataProducaoMaisRecenteDaCaixa = dataAtualRegistro;
          }
        }
      } catch (e) { /* silent */ }
      _totalMelDaCaixa += ((registro['quantidadeMel'] as num?)?.toDouble() ?? 0);
      _totalGeleiaRealDaCaixa += ((registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0);
      _totalPropolisDaCaixa += ((registro['quantidadePropolis'] as num?)?.toDouble() ?? 0);
      _totalCeraDaCaixa += ((registro['quantidadeCera'] as num?)?.toDouble() ?? 0);
    }
  }

  Future<void> _handleServiceAndUpdate(
      Future<bool> Function() serviceCall, {
        String? successMessage,
        String? failureMessage,
      }) async {
    bool success = false;
    try {
      success = await serviceCall();
      if (!mounted) return;
      if (success) {
        if (successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
        }
        _carregarDadosEProcessarRelatorio();
      } else {
        if (failureMessage != null) {
          _showErrorSnackBar(failureMessage);
        } else {
          _showErrorSnackBar("A operação falhou."); // Mensagem genérica se nenhuma específica for fornecida
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(failureMessage ?? "Ocorreu um erro: ${e.toString()}");
      }
    }
  }

  Future<void> _adicionarAnotacaoComRecarga() async {
    final descricao = await _showInputDescricaoDialog(context, 'Nova Anotação', 'Digite sua anotação aqui...');
    if (descricao != null && descricao.trim().isNotEmpty) {
      // AdicionarHistorico não retorna bool, então não podemos usar _handleServiceAndUpdate diretamente
      // a menos que o modifiquemos no service para retornar bool ou envolvamos em um try-catch aqui.
      // Por enquanto, chamando diretamente e recarregando.
      await _historicoService.adicionarHistorico(widget.caixaId, descricao.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anotação adicionada!')));
        _carregarDadosEProcessarRelatorio();
      }
    }
  }

  Future<void> _editarAnotacaoHistoricoComRecarga(Map<String, dynamic> anotacaoParaEditar) async {
    final String? itemId = anotacaoParaEditar['id']?.toString();
    final String? descricaoAtual = anotacaoParaEditar['descricao']?.toString();
    if (itemId == null || itemId.isEmpty) {
      _showErrorSnackBar("Erro: ID da anotação inválido para edição.");
      return;
    }
    if (descricaoAtual == null) {
      _showErrorSnackBar("Erro: Descrição original não encontrada para edição.");
      return;
    }
    final novaDescricao = await _showInputDescricaoDialog(context, 'Editar Anotação', 'Edite sua anotação...', initialText: descricaoAtual);
    if (novaDescricao != null && novaDescricao.trim().isNotEmpty) {
      if (novaDescricao.trim() == descricaoAtual.trim()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma alteração detectada.')));
        return;
      }
      final now = DateTime.now();
      await _handleServiceAndUpdate(
              () => _historicoService.atualizarItemHistorico(
              widget.caixaId,
              itemId,
              novaDescricao.trim(),
              now.toIso8601String(), // timestamp_modificacao
              '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}', // data_modificacao
              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}' // hora_modificacao
          ),
          successMessage: 'Anotação atualizada com sucesso!',
          failureMessage: 'Falha ao atualizar a anotação.'
      );
    }
  }

  Future<String?> _showInputDescricaoDialog(
      BuildContext context, String title, String hintText, {String? initialText}) async {
    TextEditingController controller = TextEditingController(text: initialText);
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 120.0, // Altura que você definiu
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(labelText: hintText, border: const OutlineInputBorder(), alignLabelWithHint: true),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context, controller.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A descrição não pode ser vazia.')));
                }
              },
              child: const Text('Salvar')),
        ],
      ),
    );
  }

  Future<void> _navegarParaRegistrarProducaoComRecarga({Map<String, dynamic>? producaoParaEditar}) async {
    final bool? resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => RegistrarProducaoScreen(caixaId: widget.caixaId, registroProducaoExistente: producaoParaEditar)),
    );
    if (resultado == true && mounted) _carregarDadosEProcessarRelatorio();
  }

  Future<void> _gerenciarObservacaoFixaComRecarga(BuildContext context, {String? textoAtual}) async {
    final novaObservacao = await _showInputDescricaoDialog(context, textoAtual == null || textoAtual.isEmpty ? 'Adicionar Obs. Fixa' : 'Editar Obs. Fixa', 'Digite sua observação fixa...', initialText: textoAtual);
    if (novaObservacao != null) {
      // salvarObservacaoFixa não retorna bool, então não podemos usar _handleServiceAndUpdate
      await _historicoService.salvarObservacaoFixa(widget.caixaId, novaObservacao.trim().isEmpty ? null : novaObservacao.trim());
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(novaObservacao.trim().isEmpty ? 'Observação fixa removida.' : 'Observação fixa salva!')));
        _carregarDadosEProcessarRelatorio();
      }
    }
  }

  Future<void> _excluirObservacaoFixaComRecarga() async {
    await _historicoService.salvarObservacaoFixa(widget.caixaId, null); // Define como null para excluir
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Observação fixa removida.')));
      _carregarDadosEProcessarRelatorio();
    }
  }

  Future<void> _editarLocalCaixaComRecarga() async {
    final novoLocal = await _showSelectOrInputDialog(context, 'Editar Local da Caixa', 'Novo nome do local ou selecione', _localAtualDaCaixa, _locaisPreDefinidos);
    if (novoLocal == null || novoLocal.trim().isEmpty) return;
    if (novoLocal.trim().toLowerCase() == _localAtualDaCaixa.toLowerCase()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O local não foi alterado.')));
      return;
    }
    final sucesso = await _historicoService.atualizarLocalDaCaixa(widget.caixaId, novoLocal.trim());
    if (!mounted) return;
    if (sucesso) {
      setState(() => _localAtualDaCaixa = novoLocal.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Local atualizado para: $_localAtualDaCaixa')));
    } else {
      if (mounted) _showErrorSnackBar('Erro ao atualizar o local.');
    }
  }

  Future<String?> _showSelectOrInputDialog(
      BuildContext context, String title, String hintText, String valorAtual, List<String> predefinedOptions) async {
    TextEditingController controller = TextEditingController(text: valorAtual);
    String? localSelecionadoOpcao = predefinedOptions.map((e) => e.toLowerCase()).contains(valorAtual.toLowerCase()) ? predefinedOptions.firstWhere((e) => e.toLowerCase() == valorAtual.toLowerCase()) : null;

    List<String> displayOptions = List.from(predefinedOptions);
    if (!displayOptions.map((e) => e.toLowerCase()).contains(valorAtual.toLowerCase()) && valorAtual.isNotEmpty) {
      displayOptions.add(valorAtual);
    }
    displayOptions.sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(labelText: 'Nome do Local', hintText: hintText, border: const OutlineInputBorder()),
                    autofocus: true,
                    onChanged: (text) {
                      String? matchingOption;
                      try { matchingOption = displayOptions.firstWhere((opt) => opt.toLowerCase() == text.trim().toLowerCase()); }
                      catch (e) { matchingOption = null;}
                      setStateDialog(() => localSelecionadoOpcao = matchingOption);
                    },
                  ),
                  if (predefinedOptions.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.only(top: 16.0, bottom: 8.0), child: Text("Ou selecione um local existente:", style: TextStyle(fontSize: 14.0))),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.25),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: displayOptions.length,
                        itemBuilder: (context, index) {
                          final option = displayOptions[index];
                          return RadioListTile<String>(
                            title: Text(option), value: option, groupValue: localSelecionadoOpcao,
                            onChanged: (String? value) {
                              setStateDialog(() { localSelecionadoOpcao = value; if (value != null) controller.text = value;});
                            },
                            dense: true, contentPadding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          actions: <Widget>[
            TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('O nome do local não pode ser vazio.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutroProdutoRelatorioCaixa(String nome, double total, String unidade) {
    if (total <= 0) return const SizedBox.shrink();
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nome, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${total.toStringAsFixed(2)} $unidade', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0, color: Colors.black87)),
        const SizedBox(height: 4.0),
        Row(children: [
          const Icon(Icons.location_on, size: 18.0, color: Colors.black54),
          const SizedBox(width: 4.0),
          Expanded(child: Text(_localAtualDaCaixa, style: const TextStyle(fontSize: 14.0, color: Colors.black54), overflow: TextOverflow.ellipsis)),
        ]),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentTabIndex == 0) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_anotar'), backgroundColor: const Color(0xFFFFC107), foregroundColor: Colors.black87,
        onPressed: _adicionarAnotacaoComRecarga,
        icon: const Icon(Icons.add_comment_outlined), label: const Text('Anotar'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      );
    } else if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_producao'), backgroundColor: Colors.green.shade600, foregroundColor: Colors.white,
        onPressed: () => _navegarParaRegistrarProducaoComRecarga(),
        icon: const Icon(Icons.eco_outlined), label: const Text('Nova Produção'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      );
    }
    return null;
  }

  // ... outras partes do _CaixaScreenState ...

  @override
  Widget build(BuildContext context) {
    String displayCaixaId = widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
        elevation: 2.0,
        title: _buildAppBarTitle(), // Seu método _buildAppBarTitle
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined),
              onPressed: _editarLocalCaixaComRecarga,
              tooltip: 'Editar Local da Caixa'),
          // PopupMenu para OPÇÕES ADICIONAIS (como Adicionar/Editar Observação Fixa)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_outlined),
            tooltip: "Mais opções",
            onSelected: (value) async { // Não precisa mais ser async aqui
              if (value == 'gerenciar_obs_fixa') {
                _gerenciarObservacaoFixaComRecarga(context, textoAtual: _observacaoFixa);
              }
              // A exclusão da observação fixa agora é feita pelo Dismissible
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'gerenciar_obs_fixa',
                child: ListTile(
                  leading: Icon(_observacaoFixa == null || _observacaoFixa!.isEmpty
                      ? Icons.push_pin_outlined // Ícone para adicionar
                      : Icons.edit_note_outlined), // Ícone para editar
                  title: Text(_observacaoFixa == null || _observacaoFixa!.isEmpty
                      ? 'Adicionar Obs. Fixa'
                      : 'Editar Obs. Fixa'),
                ),
              ),
              // Não precisa mais do item de excluir observação fixa aqui se o Dismissible estiver ativo
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : Column(
        children: [
          // **** RESTAURANDO A EXIBIÇÃO DA OBSERVAÇÃO FIXA ****
          if (_observacaoFixa != null && _observacaoFixa!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Dismissible(
                key: Key('observacao-fixa-${widget.caixaId}'), // Chave para o Dismissible
                direction: DismissDirection.endToStart,
                background: Container( // Seu background para o Dismissible
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.0)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 26),
                        Text("Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                      ]),
                ),
                confirmDismiss: (DismissDirection direction) async {
                  // Sua lógica de confirmação
                  final bool? confirmado = await showAppConfirmDialog(
                      context,
                      title: 'Excluir Observação Fixa',
                      content: 'Tem certeza que deseja excluir esta observação fixa?',
                      confirmButtonText: "Excluir" // Garante o texto correto no botão
                  );
                  return confirmado ?? false;
                },
                onDismissed: (DismissDirection direction) {
                  // Sua lógica para excluir
                  _excluirObservacaoFixaComRecarga();
                },
                child: Container( // Seu widget para exibir a observação
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                      color: Colors.red.shade100, // Sua cor
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.red.shade400)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.report_problem_outlined, color: Colors.red.shade700, size: 24.0),
                      const SizedBox(width: 8.0),
                      Expanded(
                          child: Text(_observacaoFixa!,
                              style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.5))),
                      // Ícone de Edição para a Observação Fixa
                      GestureDetector(
                          onTap: () => _gerenciarObservacaoFixaComRecarga(
                              context,
                              textoAtual: _observacaoFixa), // Chama a função de gerenciar
                          child: Icon(Icons.edit_note_rounded, // Ícone de edição
                              color: Colors.red.shade800,
                              size: 24.0)),
                    ],
                  ),
                ),
              ),
            )
          else // Se não houver observação fixa, mostrar o botão de adicionar
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () => _gerenciarObservacaoFixaComRecarga(context), // Chama a função de gerenciar
                  icon: const Icon(Icons.push_pin_outlined, size: 20),
                  label: const Text('Adicionar Observação Fixa', style: TextStyle(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0))),
                ),
              ),
            ),
          // **** FIM DA RESTAURAÇÃO DA OBSERVAÇÃO FIXA ****

          TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFFFFC107),
            tabs: const [
              Tab(icon: Icon(Icons.notes_rounded), text: 'Anotações'),
              Tab(icon: Icon(Icons.eco_outlined), text: 'Produção'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Relatório'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAnotacoesView(),
                _buildProducaoView(),
                _buildRelatorioCaixaView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

// ... restante do código da _CaixaScreenState (os métodos _buildAnotacoesView, _buildProducaoView, etc. permanecem os mesmos da última versão completa que te dei)

  Widget _buildAnotacoesView() {
    if (_historicoItens.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.forum_outlined, size: 60.0, color: Colors.grey.shade400),
            const SizedBox(height: 12.0),
            const Text('Nenhuma anotação encontrada.', style: TextStyle(fontSize: 16.0, color: Colors.black54)),
            const SizedBox(height: 6.0),
            const Text('Toque no botão "Anotar" para adicionar a primeira.', style: TextStyle(fontSize: 14.0, color: Colors.black45), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _historicoItens.length,
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 80.0),
      itemBuilder: (_, index) {
        final item = _historicoItens[index];
        final String? itemId = item['id']?.toString();
        final String descricao = item['descricao']?.toString() ?? 'Sem descrição';

        String displayTimestamp = item['data'] ?? 'N/D';
        if (item['hora'] != null && (item['hora'] as String).isNotEmpty) {
          displayTimestamp += ' às ${item['hora']}';
        }
        // Prioriza o timestamp completo se existir
        if (item['timestamp'] != null) {
          try { displayTimestamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['timestamp']));} catch(_){}
        }

        final bool foiModificado = item.containsKey('timestamp_modificacao') && item['timestamp_modificacao'] != null;
        String subtitleText = displayTimestamp;
        if (foiModificado) {
          try {
            subtitleText = "${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['timestamp_modificacao']))} (editado)";
          } catch(_){
            subtitleText += " (editado)"; // Fallback se o timestamp_modificacao for inválido
          }
        }

        final Key itemKey = itemId != null ? ValueKey(itemId) : ValueKey('${widget.caixaId}-hist-$index-${item['timestamp'] ?? UniqueKey().toString()}');

        return Dismissible(
          key: itemKey,
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(12.0)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 26),
              Text("Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
            ]),
          ),
          confirmDismiss: (DismissDirection direction) async {
            final bool? confirmado = await showAppConfirmDialog(context, title: "Excluir Anotação", content: "Tem certeza que deseja excluir esta anotação?", confirmButtonText: "Excluir");
            return confirmado ?? false;
          },
          onDismissed: (DismissDirection direction) async {
            if (itemId != null) {
              await _handleServiceAndUpdate(
                      () => _historicoService.removerItemHistoricoPorId(widget.caixaId, itemId),
                  successMessage: 'Anotação excluída!',
                  failureMessage: 'Falha ao excluir anotação.'
              );
            } else {
              if(mounted) _showErrorSnackBar('Não foi possível excluir: ID da anotação não encontrado.');
              _carregarDadosEProcessarRelatorio(); // Recarrega para restaurar o item se a exclusão falhar no service
            }
          },
          child: Card(
            color: Colors.white, elevation: 1.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0), side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            margin: const EdgeInsets.symmetric(vertical: 4.5),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              title: Text(descricao, style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500, color: Colors.black87)),
              subtitle: Text(subtitleText, style: TextStyle(color: foiModificado ? Colors.blueGrey.shade700 : Colors.grey.shade600, fontSize: 12.0, fontStyle: foiModificado ? FontStyle.italic : FontStyle.normal)),
              leading: Icon(Icons.notes_rounded, color: Colors.amber.shade600, size: 28),
              trailing: IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.blueGrey.shade700, size: 22),
                tooltip: 'Editar Anotação',
                onPressed: () {
                  if (itemId != null) {
                    _editarAnotacaoHistoricoComRecarga(item);
                  } else {
                    _showErrorSnackBar('Não é possível editar: ID da anotação não encontrado.');
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProducaoView() {
    if (_registrosProducaoDaCaixa.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.eco_outlined, size: 60.0, color: Colors.grey.shade400),
            const SizedBox(height: 12.0),
            const Text('Nenhum registro de produção.', style: TextStyle(fontSize: 16.0, color: Colors.black54)),
            const SizedBox(height: 6.0),
            const Text('Use o botão "Nova Produção" abaixo para adicionar.', style: TextStyle(fontSize: 14.0, color: Colors.black45), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _registrosProducaoDaCaixa.length,
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 80.0),
      itemBuilder: (context, index) {
        final producaoItem = _registrosProducaoDaCaixa[index];
        return _buildRegistroProducaoCard(producaoItem);
      },
    );
  }

  Widget _buildRegistroProducaoCard(Map<String, dynamic> producao) {
    String dataFormatada = "Data não informada";
    if (producao['dataProducao'] != null) {
      try { dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(producao['dataProducao']));} catch (e) { /* silent */ }
    }
    Widget buildDetalheItem(String label, String? value, {String? corPropolis}) {
      if (value == null || value.isEmpty || value == "0.0" || value == "0" || value == "0.00") return const SizedBox.shrink();
      String textoFinal = value;
      if (label.toLowerCase().contains('própolis') && corPropolis != null && corPropolis.isNotEmpty) {
        textoFinal = '$value (Cor: $corPropolis)';
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6.0, bottom: 2.0),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label: ', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          Expanded(child: Text(textoFinal, style: const TextStyle(fontSize: 14.5, color: Colors.black87), softWrap: true)),
        ]),
      );
    }
    List<Widget> childrenDetalhes = [
      buildDetalheItem('Mel', producao['quantidadeMel'] != null ? '${(producao['quantidadeMel'] as num).toStringAsFixed(2)} kg/L' : null),
      buildDetalheItem('Geleia Real', producao['quantidadeGeleiaReal'] != null ? '${(producao['quantidadeGeleiaReal'] as num).toStringAsFixed(2)}g' : null),
      buildDetalheItem('Própolis', producao['quantidadePropolis'] != null ? '${(producao['quantidadePropolis'] as num).toStringAsFixed(2)}g/mL' : null, corPropolis: producao['corDaPropolis']?.toString()),
      buildDetalheItem('Cera', producao['quantidadeCera'] != null ? '${(producao['quantidadeCera'] as num).toStringAsFixed(2)}kg/placas' : null),
    ];
    if (producao['observacaoProducao'] != null && (producao['observacaoProducao'] as String).isNotEmpty) {
      childrenDetalhes.add(Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Obs: ${producao['observacaoProducao']}", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade700))));
    }
    childrenDetalhes.removeWhere((widget) => widget is SizedBox && widget.height == 0 && widget.width == 0);
    final String producaoId = producao['producaoId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    return Dismissible(
      key: Key('producao_${widget.caixaId}_$producaoId'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(10.0)),
        alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [ Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 26), Text("Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
      ),
      confirmDismiss: (DismissDirection direction) async {
        final bool? confirmado = await showAppConfirmDialog(context, title: 'Confirmar Exclusão', content: 'Tem certeza que deseja excluir este registro de produção?', confirmButtonText: "Excluir");
        return confirmado ?? false;
      },
      onDismissed: (DismissDirection direction) {
        if (producao['producaoId'] != null) {
          _handleServiceAndUpdate(
                  () => _historicoService.removerRegistroProducao(widget.caixaId, producao['producaoId'] as String),
              successMessage: 'Registro de produção excluído!', failureMessage: 'Falha ao excluir registro.'
          );
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível excluir: ID da produção inválido.')));
          _carregarDadosEProcessarRelatorio();
        }
      },
      child: Card(
        color: Colors.white, elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.green.shade300, width: 1.0)),
        margin: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0),
        child: InkWell(
          onTap: () => _navegarParaRegistrarProducaoComRecarga(producaoParaEditar: producao),
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Produção de $dataFormatada', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              const SizedBox(height: 10.0),
              if (childrenDetalhes.isNotEmpty) Column(crossAxisAlignment: CrossAxisAlignment.start, children: childrenDetalhes)
              else Padding(padding: const EdgeInsets.only(top: 4.0), child: Text('Nenhum produto registrado para esta data.', style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic, color: Colors.grey.shade600))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatorioCaixaView() {
    if (_registrosProducaoDaCaixa.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.analytics_outlined, size: 60.0, color: Colors.grey.shade400),
            const SizedBox(height: 16.0),
            Text('Nenhum dado de produção para gerar relatório nesta caixa.', style: TextStyle(fontSize: 18.0, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _carregarDadosEProcessarRelatorio, color: const Color(0xFFFFC107),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          Text('Período de Produção (Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}):', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800)),
          Text('De: ${formatDisplayDate(_dataProducaoMaisAntigaDaCaixa)}   Até: ${formatDisplayDate(_dataProducaoMaisRecenteDaCaixa)}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24.0), const Divider(),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text('Produção de Mel (Caixa)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900))),
          if (_totalMelDaCaixa > 0)
            Card(
              elevation: 1.5, margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text('TOTAL DE MEL (CAIXA):', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)), Text('${_totalMelDaCaixa.toStringAsFixed(2)} kg/L', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.amber.shade900))]),
              ),
            )
          else Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('Nenhum registro de mel para esta caixa.', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade700))),
          const SizedBox(height: 24.0), const Divider(),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text('Outros Produtos (Caixa)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade700))),
          _buildOutroProdutoRelatorioCaixa('Geleia Real:', _totalGeleiaRealDaCaixa, 'g'),
          _buildOutroProdutoRelatorioCaixa('Própolis:', _totalPropolisDaCaixa, 'g/mL'),
          _buildOutroProdutoRelatorioCaixa('Cera de Abelha:', _totalCeraDaCaixa, 'kg/placas'),
        ],
      ),
    );
  }
}
