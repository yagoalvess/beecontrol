import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart'; // Assumindo que é usado
import 'package:intl/intl.dart'; // Usado para DateFormat
import 'package:abelhas/screens/registrar_producao_screen.dart'; // Assumindo que é usado

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
            child: const Text('Cancelar'), // Aplicado const
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            child: Text(
              confirmButtonText,
              style: TextStyle( // Não pode ser const por causa de Colors.red.shade700
                  color: Colors.red.shade700, fontWeight: FontWeight.bold),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
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

  const CaixaScreen({ // Aplicado const
    super.key,
    required this.caixaId,
    required this.localCaixa,
  });

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen>
    with SingleTickerProviderStateMixin {
  final HistoricoService _historicoService = HistoricoService(); // Não pode ser const
  List<Map<String, String>> _historicoItens = [];
  String? _observacaoFixa;
  bool _isLoading = true;
  late String _localAtualDaCaixa;
  List<Map<String, dynamic>> _registrosProducaoDaCaixa = [];

  Map<String, double> _somaPorCorMelDaCaixa = {};
  double _totalMelDaCaixa = 0;
  double _totalGeleiaRealDaCaixa = 0;
  double _totalPropolisDaCaixa = 0;
  double _totalCeraDaCaixa = 0;
  double _totalApitoxinaDaCaixa = 0;
  DateTime? _dataProducaoMaisAntigaDaCaixa;
  DateTime? _dataProducaoMaisRecenteDaCaixa;

  // Se esta lista nunca mudar, pode ser const.
  // Se puder mudar em tempo de execução (mesmo que não mude neste código), não deve ser.
  // Para este exemplo, vou assumir que é uma lista fixa para esta tela.
  static const List<String> _locaisPreDefinidos = [ // Aplicado static const
    'Apiário Central',
    'Apiário Morro Alto',
    'Apiário de Suzano',
    'Bosque das Abelhas',
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
      if (mounted) {
        _carregarDadosIniciais();
      }
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging ||
        _tabController.index != _currentTabIndex) {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showErrorSnackBar(String message) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _carregarDadosEProcessarRelatorio() async {
    if (!mounted) return;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        _historicoService.getHistorico(widget.caixaId),
        _historicoService.getObservacaoFixa(widget.caixaId),
        _historicoService.getRegistrosProducaoDaCaixa(widget.caixaId),
      ]);

      if (!mounted) return;

      setState(() {
        _historicoItens = results[0] as List<Map<String, String>>;
        _observacaoFixa = results[1] as String?;
        _registrosProducaoDaCaixa = results[2] as List<Map<String, dynamic>>;
        _processarDadosDeProducaoParaRelatorioLocal(_registrosProducaoDaCaixa);
      });
    } catch (e) {
      _showErrorSnackBar("Erro ao carregar dados: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _carregarDadosIniciais() async {
    if (mounted && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    await _carregarDadosEProcessarRelatorio();
  }

  void _processarDadosDeProducaoParaRelatorioLocal(
      List<Map<String, dynamic>> registros) {
    // Lógica de processamento (sem mudanças diretas para const aqui, pois manipula dados)
    _somaPorCorMelDaCaixa = {};
    _totalMelDaCaixa = 0;
    _totalGeleiaRealDaCaixa = 0;
    _totalPropolisDaCaixa = 0;
    _totalCeraDaCaixa = 0;
    _totalApitoxinaDaCaixa = 0;
    _dataProducaoMaisAntigaDaCaixa = null;
    _dataProducaoMaisRecenteDaCaixa = null;

    if (registros.isEmpty) return;

    for (var registro in registros) {
      try {
        if (registro['dataProducao'] != null) {
          DateTime dataAtualRegistro =
          DateTime.parse(registro['dataProducao'] as String);
          if (_dataProducaoMaisAntigaDaCaixa == null ||
              dataAtualRegistro.isBefore(_dataProducaoMaisAntigaDaCaixa!)) {
            _dataProducaoMaisAntigaDaCaixa = dataAtualRegistro;
          }
          if (_dataProducaoMaisRecenteDaCaixa == null ||
              dataAtualRegistro.isAfter(_dataProducaoMaisRecenteDaCaixa!)) {
            _dataProducaoMaisRecenteDaCaixa = dataAtualRegistro;
          }
        }
      } catch (e) {
        // Log error if necessary
      }

      double qtdMel = (registro['quantidadeMel'] as num?)?.toDouble() ?? 0.0;
      if (qtdMel > 0) {
        _totalMelDaCaixa += qtdMel;
        String cor = registro['corDoMel'] as String? ?? 'Não Especificada';
        _somaPorCorMelDaCaixa[cor] =
            (_somaPorCorMelDaCaixa[cor] ?? 0) + qtdMel;
      }
      _totalGeleiaRealDaCaixa +=
          (registro['quantidadeGeleiaReal'] as num?)?.toDouble() ?? 0.0;
      _totalPropolisDaCaixa +=
          (registro['quantidadePropolis'] as num?)?.toDouble() ?? 0.0;
      _totalCeraDaCaixa +=
          (registro['quantidadeCera'] as num?)?.toDouble() ?? 0.0;
      _totalApitoxinaDaCaixa +=
          (registro['quantidadeApitoxina'] as num?)?.toDouble() ?? 0.0;
    }
  }

  Future<void> _handleItemAction(Future<void> Function() serviceCall) async {
    // Função wrapper para DRY em chamadas de serviço + recarga
    await serviceCall();
    if (mounted) { // Verifica mounted após a chamada de serviço, antes de recarregar
      _carregarDadosEProcessarRelatorio();
    }
  }


  Future<void> _adicionarAnotacaoComRecarga() async {
    final descricao = await _showInputDescricaoDialog(
        context, 'Nova Anotação', 'Digite sua anotação aqui...');
    if (descricao != null && descricao.trim().isNotEmpty) {
      await _handleItemAction(() => _historicoService.adicionarHistorico(widget.caixaId, descricao.trim()));
    }
  }

  Future<void> _navegarParaRegistrarProducaoComRecarga() async {
    final bool? resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarProducaoScreen( // Pode ser const se RegistrarProducaoScreen for
          caixaId: widget.caixaId,
          registroProducaoExistente: null,
        ),
      ),
    );
    if (resultado == true && mounted) {
      _carregarDadosEProcessarRelatorio();
    }
  }

  Future<void> _navegarParaEditarProducaoComRecarga(
      Map<String, dynamic> producaoParaEditar) async {
    final bool? resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarProducaoScreen( // Pode ser const se RegistrarProducaoScreen for
          caixaId: widget.caixaId,
          registroProducaoExistente: producaoParaEditar,
        ),
      ),
    );
    if (resultado == true && mounted) {
      _carregarDadosEProcessarRelatorio();
    }
  }

  Future<void> _gerenciarObservacaoFixaComRecarga(BuildContext context,
      {String? textoAtual}) async {
    final novaObservacao = await _showInputDescricaoDialog(
      context,
      textoAtual == null ? 'Adicionar Observação' : 'Editar Observação',
      'Digite sua observação fixa aqui...',
      initialText: textoAtual,
    );
    if (novaObservacao != null) {
      await _handleItemAction(() => _historicoService.salvarObservacaoFixa(widget.caixaId, novaObservacao.trim().isEmpty ? null : novaObservacao.trim()));
    }
  }

  Future<void> _excluirObservacaoFixaComRecarga() async {
    final bool confirmarExclusao = await showAppConfirmDialog(
      context,
      title: 'Confirmar Exclusão',
      content: 'Tem certeza que deseja excluir esta observação fixa?',
    );

    if (confirmarExclusao) {
      await _handleItemAction(() => _historicoService.salvarObservacaoFixa(widget.caixaId, null));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Observação fixa removida.'))); // Aplicado const
      }
    }
  }

  Future<String?> _showInputDescricaoDialog(
      BuildContext context, String title, String hintText,
      {String? initialText}) async {
    TextEditingController controller =
    TextEditingController(text: initialText);
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox( // Pode ser const se altura for fixa e child for const
          height: 120.0,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration( // Pode ter partes const
                labelText: hintText,
                hintText: hintText,
                border: const OutlineInputBorder(), // Aplicado const
                alignLabelWithHint: true),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')), // Aplicado const
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Salvar')), // Aplicado const
        ],
      ),
    );
  }

  Future<void> _editarLocalCaixaComRecarga() async {
    final novoLocal = await _showSelectOrInputDialog(
        context,
        'Editar Local da Caixa',
        'Novo nome do local ou selecione',
        _localAtualDaCaixa,
        _locaisPreDefinidos);
    if (novoLocal == null || novoLocal.trim().isEmpty) return;
    if (novoLocal.trim() == _localAtualDaCaixa) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('O local não foi alterado.'))); // Aplicado const
      }
      return;
    }

    // Não usa _handleItemAction aqui porque a atualização do estado local (_localAtualDaCaixa)
    // é síncrona e acontece antes do recarregamento total.
    final sucesso = await _historicoService.atualizarLocalDaCaixa(
        widget.caixaId, novoLocal.trim());
    if (!mounted) return;

    if (sucesso) {
      setState(() {
        _localAtualDaCaixa = novoLocal.trim();
      });
      // _carregarDadosEProcessarRelatorio(); // Opcional, como discutido
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar( // Não pode ser const devido a _localAtualDaCaixa
            content: Text('Local atualizado para: $_localAtualDaCaixa')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar( // Aplicado const
            content: Text('Erro ao atualizar o local. Tente novamente.')));
      }
    }
  }

  Future<String?> _showSelectOrInputDialog(
      BuildContext context,
      String title,
      String hintText,
      String valorAtual,
      List<String> predefinedOptions) async {
    TextEditingController controller = TextEditingController(text: valorAtual);
    String? localSelecionadoOpcao =
    predefinedOptions.contains(valorAtual) ? valorAtual : null;
    List<String> displayOptions = List.from(predefinedOptions);
    if (!displayOptions.contains(valorAtual) && valorAtual.isNotEmpty) {
      displayOptions.add(valorAtual);
      displayOptions.sort();
    }
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView( // Pode ser const se child for const
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                            labelText: 'Nome do Local',
                            hintText: hintText,
                            border: const OutlineInputBorder()), // Aplicado const
                        autofocus: true,
                        onChanged: (text) {
                          setStateDialog(() {
                            localSelecionadoOpcao =
                            predefinedOptions.contains(text) ? text : null;
                          });
                        },
                      ),
                      if (predefinedOptions.isNotEmpty) ...[
                        const Padding( // Aplicado const
                            padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                            child: Text("Ou selecione um local existente:",
                                style: TextStyle(fontSize: 14.0))), // Pode ser const
                        ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.25),
                          child: ListView.builder( // Não pode ser const devido a itemCount e itemBuilder
                            shrinkWrap: true,
                            itemCount: displayOptions.length,
                            itemBuilder: (context, index) {
                              final option = displayOptions[index];
                              return RadioListTile<String>( // Não pode ser const devido a groupValue e onChanged
                                title: Text(option),
                                value: option,
                                groupValue: localSelecionadoOpcao,
                                onChanged: (String? value) {
                                  setStateDialog(() {
                                    localSelecionadoOpcao = value;
                                    if (value != null) controller.text = value;
                                  });
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero, // Aplicado const
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
            TextButton(
                child: const Text('Cancelar'), // Aplicado const
                onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text('Salvar'), // Aplicado const
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                } else if (mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar( // Aplicado const
                      content: Text('O nome do local não pode ser vazio.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildOutroProdutoRelatorioCaixa(
      String nome, double total, String unidade) {
    if (total <= 0) return const SizedBox.shrink(); // Aplicado const
    return Card( // Não pode ser const devido ao child
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0), // Aplicado const
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Aplicado const
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(nome,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('${total.toStringAsFixed(2)} $unidade',
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)), // Aplicado const
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}',
            style: const TextStyle( // Aplicado const
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.black87)),
        const SizedBox(height: 4.0), // Aplicado const
        Row(children: [
          const Icon(Icons.location_on, size: 18.0, color: Colors.black54), // Aplicado const
          const SizedBox(width: 4.0), // Aplicado const
          Expanded(
              child: Text(_localAtualDaCaixa, // Não pode ser const
                  style: const TextStyle(fontSize: 14.0, color: Colors.black54), // Aplicado const
                  overflow: TextOverflow.ellipsis)),
        ]),
      ],
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentTabIndex == 0) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_anotar'), // Aplicado const
        backgroundColor: const Color(0xFFFFC107), // Aplicado const
        foregroundColor: Colors.black87,
        onPressed: _adicionarAnotacaoComRecarga,
        icon: const Icon(Icons.add_comment_outlined), // Aplicado const
        label: const Text('Anotar'), // Aplicado const
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      );
    } else if (_currentTabIndex == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_producao'), // Aplicado const
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        onPressed: _navegarParaRegistrarProducaoComRecarga,
        icon: const Icon(Icons.eco_outlined), // Aplicado const
        label: const Text('Nova Produção'), // Aplicado const
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // Aplicado const
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107), // Aplicado const
        foregroundColor: Colors.black87,
        elevation: 2.0,
        title: _buildAppBarTitle(),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit_location_alt_outlined), // Aplicado const
              onPressed: _editarLocalCaixaComRecarga,
              tooltip: 'Editar Local da Caixa'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFC107))) // Aplicado const
          : Column(
        children: [
          // Observação Fixa
          if (_observacaoFixa != null && _observacaoFixa!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), // Aplicado const
              child: Dismissible(
                key: Key('observacao-fixa-${widget.caixaId}'),
                direction: DismissDirection.endToStart,
                background: Container( // Pode ter partes const
                  decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12.0)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0), // Aplicado const
                  child: const Column( // Aplicado const
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_sweep_outlined,
                            color: Colors.white, size: 26),
                        Text("Excluir",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))
                      ]),
                ),
                confirmDismiss: (_) async =>
                await showAppConfirmDialog(
                  context,
                  title: 'Confirmar Exclusão',
                  content:
                  'Tem certeza que deseja excluir esta observação fixa?',
                ),
                onDismissed: (_) {
                  _excluirObservacaoFixaComRecarga();
                },
                child: Container( // Não pode ser const devido ao child e GestureDetector
                  padding: const EdgeInsets.all(12.0), // Aplicado const
                  decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.red.shade400)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.report_problem_outlined,
                          color: Colors.red.shade700, size: 24.0),
                      const SizedBox(width: 8.0), // Aplicado const
                      Expanded(
                          child: Text(_observacaoFixa!, // Não pode ser const
                              style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.5))),
                      GestureDetector(
                          onTap: () => _gerenciarObservacaoFixaComRecarga(
                              context,
                              textoAtual: _observacaoFixa),
                          child: Icon(Icons.edit_note_rounded,
                              color: Colors.red.shade800, size: 24.0)),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0), // Aplicado const
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _gerenciarObservacaoFixaComRecarga(context),
                  icon: const Icon(Icons.push_pin_outlined, size: 20), // Aplicado const
                  label: const Text('Adicionar Observação Fixa', // Aplicado const
                      style: TextStyle(fontSize: 14)), // Aplicado const
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0))),
                ),
              ),
            ),
          TabBar(
            controller: _tabController,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFFFFC107), // Aplicado const
            tabs: const [ // Aplicado const
              Tab(icon: Icon(Icons.notes_rounded), text: 'Anotações'),
              Tab(icon: Icon(Icons.eco_outlined), text: 'Produção'),
              Tab(icon: Icon(Icons.insights_rounded), text: 'Relatório'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [ // Os children não podem ser const pois são métodos que constroem widgets dinamicamente
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

  // --- VIEW PARA ANOTAÇÕES ---
  Widget _buildAnotacoesView() {
    if (_historicoItens.isEmpty && !_isLoading) {
      return const Center( // Aplicado const
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.forum_outlined, size: 60.0, color: Colors.grey), // Colors.grey.shade400 não é const
            SizedBox(height: 12.0),
            Text('Nenhuma anotação encontrada.', style: TextStyle(fontSize: 16.0, color: Colors.black54)),
            SizedBox(height: 6.0),
            Text('Toque no botão "Anotar" para adicionar a primeira.', style: TextStyle(fontSize: 14.0, color: Colors.black45), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _historicoItens.length,
      padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 80.0), // Aplicado const
      itemBuilder: (_, index) {
        final item = _historicoItens[index];
        final String itemKey = '${widget.caixaId}-hist-$index-${item['data']}-${item['hora']}';
        return Dismissible(
          key: Key(itemKey),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12.0)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // Aplicado const
            child: const Column( // Aplicado const
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 26),
                  Text("Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                ]),
          ),
          confirmDismiss: (_) async => await showAppConfirmDialog(
            context,
            title: "Excluir Anotação",
            content: "Tem certeza que deseja excluir esta anotação?",
          ),
          onDismissed: (_) async {
            // Usando _handleItemAction para DRY
            await _handleItemAction(() => _historicoService.removerHistorico(widget.caixaId, index));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anotação excluída'))); // Aplicado const
            }
          },
          child: Card(
            color: Colors.white,
            elevation: 1.5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.grey.shade200, width: 0.5)),
            margin: const EdgeInsets.symmetric(vertical: 4.5), // Aplicado const
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0), // Aplicado const
              title: Text(item['descricao'] ?? 'Sem descrição',
                  style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500, color: Colors.black87)), // Aplicado const
              subtitle: Text('${item['data']} às ${item['hora']}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.0)),
              leading: Icon(Icons.notes_rounded, color: Colors.amber.shade600, size: 28),
            ),
          ),
        );
      },
    );
  }

  // --- VIEW PARA PRODUÇÃO ---
  Widget _buildProducaoView() {
    if (_registrosProducaoDaCaixa.isEmpty && !_isLoading) {
      return const Center( // Aplicado const
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.eco_outlined, size: 60.0, color: Colors.grey), // Colors.grey.shade400 não é const
            SizedBox(height: 12.0),
            Text('Nenhum registro de produção.', style: TextStyle(fontSize: 16.0, color: Colors.black54)),
            SizedBox(height: 6.0),
            Text('Use o botão "Nova Produção" abaixo para adicionar.', style: TextStyle(fontSize: 14.0, color: Colors.black45), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    return ListView.builder(
      itemCount: _registrosProducaoDaCaixa.length,
      padding: const EdgeInsets.fromLTRB(0.0, 8.0, 0.0, 80.0), // Aplicado const
      itemBuilder: (context, index) {
        final producaoItem = _registrosProducaoDaCaixa[index];
        return _buildRegistroProducaoCard(producaoItem);
      },
    );
  }

  Widget _buildRegistroProducaoCard(Map<String, dynamic> producao) {
    String dataFormatada = "Data não informada";
    if (producao['dataProducao'] != null) {
      try {
        dataFormatada = DateFormat('dd/MM/yyyy').format(DateTime.parse(producao['dataProducao']));
      } catch (e) { /* silent */ }
    }

    Widget buildDetalheItem(String label, String? value, {bool isMel = false, String? corMel}) {
      if (value == null || value.isEmpty || value == "0.0" || value == "0") return const SizedBox.shrink(); // Aplicado const
      String textoFinal = value;
      if (isMel) {
        textoFinal = (corMel != null && corMel.isNotEmpty) ? '$corMel ($value)' : '$value (cor não especificada)';
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6.0, bottom: 2.0), // Aplicado const
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
            Expanded(child: Text(textoFinal, style: const TextStyle(fontSize: 14.5, color: Colors.black87), softWrap: true)), // Aplicado const
          ],
        ),
      );
    }

    List<Widget> childrenDetalhes = [
      buildDetalheItem('Mel', producao['quantidadeMel']?.toString(), isMel: true, corMel: producao['corDoMel']?.toString()),
      buildDetalheItem('Geleia Real', producao['quantidadeGeleiaReal']?.toString() != null ? '${producao['quantidadeGeleiaReal']}g' : null),
      buildDetalheItem('Própolis', producao['quantidadePropolis']?.toString() != null ? '${producao['quantidadePropolis']}g/mL' : null),
      buildDetalheItem('Cera', producao['quantidadeCera']?.toString() != null ? '${producao['quantidadeCera']}kg/placas' : null),
      buildDetalheItem('Apitoxina', producao['quantidadeApitoxina']?.toString() != null ? '${producao['quantidadeApitoxina']}g/coletor' : null),
    ];
    childrenDetalhes.removeWhere((widget) => widget is SizedBox && widget.height == 0 && widget.width == 0);

    final String producaoId = producao['producaoId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

    return Dismissible(
      key: Key('producao_${widget.caixaId}_$producaoId'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(10.0)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0), // Aplicado const
        child: const Column( // Aplicado const
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 26),
              Text("Excluir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ]),
      ),
      confirmDismiss: (direction) async => await showAppConfirmDialog(
        context,
        title: 'Confirmar Exclusão',
        content: 'Tem certeza que deseja excluir este registro de produção?',
      ),
      onDismissed: (direction) {
        if (producao['producaoId'] != null) {
          _handleItemAction(() => _historicoService.removerRegistroProducao(widget.caixaId, producao['producaoId'] as String)).then((_) {
            // O then é opcional aqui, mas pode ser usado para feedback específico APÓS a recarga.
            // ASnackBar de sucesso/falha seria melhor dentro do _handleItemAction se quisermos feedback antes da recarga.
            // Para simplificar, o feedback principal já é dado dentro da chamada original.
          });
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível excluir: ID da produção inválido.'))); // Aplicado const
          _carregarDadosEProcessarRelatorio();
        }
      },
      child: Card(
        color: Colors.white,
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0), side: BorderSide(color: Colors.green.shade300, width: 1.0)),
        margin: const EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0), // Aplicado const
        child: InkWell(
          onTap: () {
            if (producao['producaoId'] != null) {
              _navegarParaEditarProducaoComRecarga(producao);
            } else {
              if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não é possível editar: ID da produção não encontrado.'))); // Aplicado const
            }
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0), // Aplicado const
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produção de $dataFormatada',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                const SizedBox(height: 10.0), // Aplicado const
                if (childrenDetalhes.isNotEmpty)
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: childrenDetalhes)
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0), // Aplicado const
                    child: Text('Nenhum produto registrado para esta data.', style: TextStyle(fontSize: 14.0, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- VIEW PARA O RELATÓRIO DA CAIXA ---
  Widget _buildRelatorioCaixaView() {
    if (_registrosProducaoDaCaixa.isEmpty && !_isLoading) {
      return Center( // Não pode ser totalmente const por causa do Icon com Colors.grey.shade400
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Aplicado const
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.analytics_outlined, size: 60.0, color: Colors.grey.shade400),
              const SizedBox(height: 16.0), // Aplicado const
              Text('Nenhum dado de produção para gerar relatório nesta caixa.', style: TextStyle(fontSize: 18.0, color: Colors.grey.shade600), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarDadosEProcessarRelatorio,
      color: const Color(0xFFFFC107), // Aplicado const
      child: ListView( // Não pode ser const devido aos children dinâmicos
        padding: const EdgeInsets.all(16.0), // Aplicado const
        children: <Widget>[
          Text(
            'Período de Produção (Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}):',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
          ),
          Text(
            'De: ${formatDisplayDate(_dataProducaoMaisAntigaDaCaixa)}   Até: ${formatDisplayDate(_dataProducaoMaisRecenteDaCaixa)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24.0), // Aplicado const
          const Divider(), // Aplicado const
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0), // Aplicado const
            child: Text('Produção de Mel (Caixa)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
          ),
          if (_somaPorCorMelDaCaixa.isNotEmpty)
            Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0), // Aplicado const
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Aplicado const
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total por Cor/Tipo:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8.0), // Aplicado const
                    ..._somaPorCorMelDaCaixa.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0), // Aplicado const
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('  • ${entry.key}:', style: const TextStyle(fontSize: 15.5)), // Aplicado const
                            Text('${entry.value.toStringAsFixed(2)} kg/L', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500)), // Aplicado const
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 20, thickness: 1), // Aplicado const
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('TOTAL DE MEL (CAIXA):', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${_totalMelDaCaixa.toStringAsFixed(2)} kg/L', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0), // Aplicado const
              child: Text('Nenhum registro de mel para esta caixa.', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
            ),
          const SizedBox(height: 24.0), // Aplicado const
          const Divider(), // Aplicado const
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0), // Aplicado const
            child: Text('Outros Produtos (Caixa)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
          ),
          _buildOutroProdutoRelatorioCaixa('Geleia Real:', _totalGeleiaRealDaCaixa, 'g'),
          _buildOutroProdutoRelatorioCaixa('Própolis:', _totalPropolisDaCaixa, 'g/mL'),
          _buildOutroProdutoRelatorioCaixa('Cera de Abelha:', _totalCeraDaCaixa, 'kg/placas'),
          _buildOutroProdutoRelatorioCaixa('Apitoxina:', _totalApitoxinaDaCaixa, 'g/coletor'),
        ],
      ),
    );
  }
}

