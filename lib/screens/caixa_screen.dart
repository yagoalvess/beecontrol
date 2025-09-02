import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart';

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

class _CaixaScreenState extends State<CaixaScreen> {
  final HistoricoService _historicoService = HistoricoService(); // Instância do serviço
  List<Map<String, String>> historico = [];
  String? _observacaoFixa;
  bool _isLoading = true;

  // --- NOVO ESTADO PARA O LOCAL ATUAL DA CAIXA ---
  late String _localAtualDaCaixa;

  // --- LISTA DE LOCAIS PREDEFINIDOS (mantenha sincronizada com a HomeScreen se usar a mesma) ---
  final List<String> _locaisPreDefinidos = [
    'Apiário Central',
    'Apiário Morro Alto',
    'Apiário de Suzano',
    'Bosque das Abelhas',
    // Adicione mais locais conforme necessário
  ];


  @override
  void initState() {
    super.initState();
    _localAtualDaCaixa = widget.localCaixa; // Inicializa com o local passado
    _carregarDadosDaCaixa();
  }

  Future<void> _carregarDadosDaCaixa() async { // Renomeado para seguir convenção
    setState(() => _isLoading = true);
    // Não precisamos recarregar o local da caixa do serviço aqui,
    // pois ele é gerenciado pelo estado _localAtualDaCaixa e atualizado após a edição.
    final dadosHistorico = await _historicoService.getHistorico(widget.caixaId);
    final observacaoFixa = await _historicoService.getObservacaoFixa(widget.caixaId);

    if (mounted) {
      setState(() {
        historico = dadosHistorico;
        _observacaoFixa = observacaoFixa;
        _isLoading = false;
      });
    }
  }

  Future<void> _adicionarEntrada() async { // Renomeado para seguir convenção
    final descricao = await _inputDescricaoDialog(context, 'Nova Anotação', 'Digite sua anotação aqui...');
    if (descricao != null && descricao.trim().isNotEmpty) {
      await _historicoService.adicionarHistorico(widget.caixaId, descricao.trim());
      _carregarDadosDaCaixa(); // Recarrega apenas histórico e observação
    }
  }

  Future<void> _gerenciarObservacaoFixa(BuildContext context, {String? textoAtual}) async {
    final novaObservacao = await _inputDescricaoDialog(
      context,
      textoAtual == null ? 'Adicionar Observação' : 'Editar Observação',
      'Digite sua observação fixa aqui...',
      initialText: textoAtual,
    );

    // Salva apenas se houver uma nova observação (mesmo que seja string vazia para limpar)
    // ou se a observação inicial era nula e agora temos algo.
    if (novaObservacao != null) {
      await _historicoService.salvarObservacaoFixa(widget.caixaId, novaObservacao.trim().isEmpty ? null : novaObservacao.trim());
      _carregarDadosDaCaixa(); // Recarrega apenas histórico e observação
    }
  }

  Future<void> _excluirObservacaoFixa() async {
    await _historicoService.salvarObservacaoFixa(widget.caixaId, null);
    _carregarDadosDaCaixa(); // Recarrega apenas histórico e observação
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observação fixa removida.')),
      );
    }
  }

  // Renomeado para _inputDescricaoDialog para clareza
  Future<String?> _inputDescricaoDialog(
      BuildContext context,
      String title,
      String hintText, {
        String? initialText,
      }) async {
    TextEditingController controller = TextEditingController(text: initialText);
    return await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          height: 120,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              labelText: hintText,
              hintText: hintText,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // --- NOVA FUNÇÃO PARA EDITAR O LOCAL DA CAIXA ---
  Future<void> _editarLocalCaixa() async {
    final novoLocal = await _showSelectOrInputDialog(
      context,
      'Editar Local da Caixa',
      'Novo nome do local ou selecione',
      _localAtualDaCaixa, // Passa o local atual para pré-preenchimento
      _locaisPreDefinidos,
    );

    if (novoLocal != null && novoLocal.trim().isNotEmpty && novoLocal.trim() != _localAtualDaCaixa) {
      final sucesso = await _historicoService.atualizarLocalDaCaixa(widget.caixaId, novoLocal.trim());
      if (sucesso && mounted) {
        setState(() {
          _localAtualDaCaixa = novoLocal.trim(); // Atualiza o local na UI desta tela
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local atualizado para: $_localAtualDaCaixa')),
        );
        // Informa a tela anterior que uma atualização ocorreu, para que ela possa recarregar.
        Navigator.pop(context, true); // Envia 'true' de volta
      } else if (!sucesso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar o local. Tente novamente.')),
        );
      }
    } else if (novoLocal != null && novoLocal.trim() == _localAtualDaCaixa) {
      // Nenhuma mudança, apenas fecha o diálogo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O local não foi alterado.')),
        );
      }
    }
    // Se novoLocal for null (cancelado), não faz nada.
  }

  // --- NOVO DIÁLOGO PARA SELECIONAR OU INSERIR LOCAL (similar ao da HomeScreen) ---
  Future<String?> _showSelectOrInputDialog(
      BuildContext context,
      String title,
      String hintText,
      String valorAtual,
      List<String> predefinedOptions,
      ) async {
    TextEditingController controller = TextEditingController(text: valorAtual);
    String? localSelecionadoOpcao = predefinedOptions.contains(valorAtual) ? valorAtual : null;

    // Adiciona o valor atual às opções se ele não estiver lá, para o RadioListTile
    List<String> displayOptions = List.from(predefinedOptions);
    if (!displayOptions.contains(valorAtual) && valorAtual.isNotEmpty) {
      displayOptions.add(valorAtual); // Adiciona para permitir seleção se for um valor customizado
      displayOptions.sort(); // Opcional: mantém ordenado
    }


    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Usuário deve usar os botões
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder( // Para atualizar o RadioListTile e o TextField
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Nome do Local',
                        hintText: hintText,
                        border: const OutlineInputBorder(),
                      ),
                      autofocus: true,
                      onChanged: (text) {
                        // Se o usuário digitar, desmarca a seleção de opção pré-definida
                        // a menos que o texto digitado corresponda a uma opção
                        setStateDialog(() {
                          if (predefinedOptions.contains(text)) {
                            localSelecionadoOpcao = text;
                          } else {
                            localSelecionadoOpcao = null;
                          }
                        });
                      },
                    ),
                    if (predefinedOptions.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text("Ou selecione um local existente:", style: TextStyle(fontSize: 14)),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.25, // Limita altura
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: displayOptions.length,
                          itemBuilder: (context, index) {
                            final option = displayOptions[index];
                            return RadioListTile<String>(
                              title: Text(option),
                              value: option,
                              groupValue: localSelecionadoOpcao,
                              onChanged: (String? value) {
                                setStateDialog(() {
                                  localSelecionadoOpcao = value;
                                  if (value != null) {
                                    controller.text = value; // Atualiza o TextField
                                  }
                                });
                              },
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Retorna null
              },
            ),
            ElevatedButton(
              child: const Text('Salvar'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('O nome do local não pode ser vazio.')),
                  );
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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Caixa ${widget.caixaId}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _localAtualDaCaixa, // --- USA O ESTADO LOCAL ATUALIZADO ---
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        // --- BOTÃO DE AÇÕES COM EDIÇÃO DE LOCAL ---
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt_outlined),
            onPressed: _editarLocalCaixa,
            tooltip: 'Editar Local da Caixa',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // === Seção de Observação Fixa ===
          if (_observacaoFixa != null && _observacaoFixa!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Dismissible(
                key: Key('observacao-fixa-${widget.caixaId}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Excluir Observação"),
                      content: const Text("Tem certeza que deseja excluir esta observação?"),
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
                  _excluirObservacaoFixa();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade400),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.push_pin, color: Colors.red, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _observacaoFixa!,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _gerenciarObservacaoFixa(context, textoAtual: _observacaoFixa),
                        child: const Icon(Icons.edit, color: Colors.red, size: 24),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () => _gerenciarObservacaoFixa(context),
                icon: const Icon(Icons.push_pin_outlined), // Ícone alterado para diferenciação
                label: const Text('Adicionar Observação Fixa'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700, // Cor mais suave
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          // === Seção de Histórico (Lista de Anotações) ===
          if (historico.isEmpty && !_isLoading) // Adicionado !_isLoading para evitar mostrar "nenhuma anotação" durante o carregamento
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.forum_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma anotação encontrada.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toque no botão abaixo para adicionar a primeira.',
                      style: TextStyle(fontSize: 14, color: Colors.black45),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: historico.length,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemBuilder: (_, index) {
                  final item = historico[index];
                  // Criando uma chave mais robusta, mas ainda pode melhorar se os itens tiverem IDs únicos do backend.
                  final String itemKey = '${widget.caixaId}-hist-$index-${item['data']}-${item['hora']}';
                  return Dismissible(
                    key: Key(itemKey),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Excluir Anotação"),
                          content: const Text("Tem certeza que deseja excluir esta anotação?"),
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
                      await _historicoService.removerHistorico(widget.caixaId, index);
                      //setState(() => historico.removeAt(index)); // Não é mais necessário se _carregarDadosDaCaixa() for chamado
                      _carregarDadosDaCaixa(); // Recarrega para garantir consistência
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anotação excluída')),
                        );
                      }
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 2, // Suavizado
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 5), // Reduzido
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(
                          item['descricao'] ?? 'Sem descrição',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500), // Ajustado
                        ),
                        subtitle: Text(
                          '${item['data']} às ${item['hora']}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12), // Ajustado
                        ),
                        leading: Icon(Icons.notes_rounded, color: Colors.amber.shade700), // Ajustado
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
        onPressed: _adicionarEntrada,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Anotar'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
