import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart';
import 'package:abelhas/screens/caixa_screen.dart';

class CaixaScreen extends StatefulWidget {
  final String caixaId;

  const CaixaScreen({super.key, required this.caixaId});

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen> {
  List<Map<String, String>> historico = [];

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  void carregarHistorico() async {
    final dados = await HistoricoService().getHistorico(widget.caixaId);
    setState(() => historico = dados);
  }

  void adicionarEntrada() async {
    final descricao = await _inputDescricao(context);
    if (descricao != null) {
      await HistoricoService().adicionarHistorico(widget.caixaId, descricao);
      carregarHistorico();
    }
  }

  Future<String?> _inputDescricao(BuildContext context) async {
    String? descricao;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Anotação'),
        content: SizedBox(
          height: 120, // ⬅️ altura maior da caixa de texto
          child: TextField(
            autofocus: true,
            maxLines: null, // ⬅️ permite múltiplas linhas
            expands: true, // ⬅️ expande para preencher o SizedBox
            textAlignVertical: TextAlignVertical.top, // ⬅️ começa a digitar no topo
            onChanged: (val) => descricao = val,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              border: OutlineInputBorder(), // ⬅️ borda visível
              alignLabelWithHint: true,
            ),
          ),
        ),

        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Salvar')),
        ],
      ),
    );
    return descricao;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Caixa ${widget.caixaId}')),
      body: ListView.builder(
        itemCount: historico.length,
        itemBuilder: (_, index) {
          final item = historico[index];
          return ListTile(
            title: Text(item['descricao']!),
            subtitle: Text('${item['data']} às ${item['hora']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: adicionarEntrada,
        child: const Icon(Icons.add),
      ),
    );
  }
}
