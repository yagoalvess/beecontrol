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
  List<Map<String, String>> historico = [];
  String? _observacaoFixa;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosDaCaixa();
  }

  void _carregarDadosDaCaixa() async {
    setState(() => _isLoading = true);
    final dadosHistorico = await HistoricoService().getHistorico(widget.caixaId);
    final observacaoFixa = await HistoricoService().getObservacaoFixa(widget.caixaId);
    if (mounted) {
      setState(() {
        historico = dadosHistorico;
        _observacaoFixa = observacaoFixa;
        _isLoading = false;
      });
    }
  }

  void _adicionarEntrada() async {
    final descricao = await _inputDescricao(context, 'Nova Anotação', 'Digite sua anotação aqui...');
    if (descricao != null && descricao.trim().isNotEmpty) {
      await HistoricoService().adicionarHistorico(widget.caixaId, descricao.trim());
      _carregarDadosDaCaixa();
    }
  }

  void _gerenciarObservacaoFixa(BuildContext context, {String? textoAtual}) async {
    final novaObservacao = await _inputDescricao(
      context,
      textoAtual == null ? 'Adicionar Observação' : 'Editar Observação',
      'Digite sua observação fixa aqui...',
      initialText: textoAtual,
    );

    if (novaObservacao != null && novaObservacao.trim().isNotEmpty) {
      await HistoricoService().salvarObservacaoFixa(widget.caixaId, novaObservacao.trim());
      _carregarDadosDaCaixa();
    }
  }

  void _excluirObservacaoFixa() async {
    await HistoricoService().salvarObservacaoFixa(widget.caixaId, null);
    _carregarDadosDaCaixa();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Observação fixa removida.')),
      );
    }
  }

  Future<String?> _inputDescricao(
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
                    widget.localCaixa,
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // === Seção de Observação Fixa (MODIFICADA) ===
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
                      // Adicionando um botão de edição
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
                icon: const Icon(Icons.push_pin),
                label: const Text('Adicionar Observação'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),

          // === Seção de Histórico (Lista de Anotações) ===
          if (historico.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notes, size: 60, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'Nenhuma anotação encontrada.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toque no botão abaixo para adicionar.',
                      style: TextStyle(fontSize: 14, color: Colors.black45),
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
                  final String itemKey = item['id'] ?? '${item['data']}-${item['hora']}-${item['descricao']}-$index';
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
                      await HistoricoService().removerHistorico(widget.caixaId, index);
                      setState(() => historico.removeAt(index));
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Anotação excluída')),
                        );
                      }
                    },
                    child: Card(
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        title: Text(
                          item['descricao'] ?? 'Sem descrição',
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Text(
                          '${item['data']} às ${item['hora']}',
                          style: const TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        leading: const Icon(Icons.note_alt_outlined, color: Colors.amber),
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