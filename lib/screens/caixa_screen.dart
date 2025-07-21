import 'package:flutter/material.dart';
import 'package:abelhas/services/historico_service.dart';

// Removida a importação de 'package:abelhas/screens/caixa_screen.dart'; pois já estamos neste arquivo.

class CaixaScreen extends StatefulWidget {
  final String caixaId;
  final String localCaixa; // Novo parâmetro para o local

  const CaixaScreen({
    super.key,
    required this.caixaId,
    required this.localCaixa, // Adicionado ao construtor
  });

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen> {
  List<Map<String, String>> historico = [];
  bool _isLoading = true; // Para feedback de carregamento

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  void carregarHistorico() async {
    setState(() {
      _isLoading = true;
    });
    // Pequena simulação de delay para ver o loading, remova se não necessário
    // await Future.delayed(const Duration(milliseconds: 300));
    final dados = await HistoricoService().getHistorico(widget.caixaId);
    if (mounted) { // Verifica se o widget ainda está no tree
      setState(() {
        historico = dados;
        _isLoading = false;
      });
    }
  }

  void adicionarEntrada() async {
    final descricao = await _inputDescricao(context);
    if (descricao != null && descricao.trim().isNotEmpty) { // Verifica se a descrição não está vazia
      await HistoricoService().adicionarHistorico(widget.caixaId, descricao.trim());
      carregarHistorico(); // Recarrega para mostrar a nova entrada
    }
  }

  Future<String?> _inputDescricao(BuildContext context) async {
    String? descricao;
    TextEditingController controller = TextEditingController(); // Controller para o TextField

    return await showDialog<String>( // Retorna o valor do pop
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova Anotação'),
        content: SizedBox(
          height: 120,
          child: TextField(
            controller: controller, // Usa o controller
            autofocus: true,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            // onChanged: (val) => descricao = val, // Não é mais necessário com o controller
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Digite sua anotação aqui...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Não retorna valor ao cancelar
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Retorna o texto do controller ao salvar
              Navigator.pop(context, controller.text);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    // return descricao; // Removido, o valor é retornado pelo Navigator.pop
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Modificado para incluir o local
        title: Text('Caixa: ${widget.caixaId} - Local: ${widget.localCaixa}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Feedback de carregamento
          : historico.isEmpty
          ? const Center(
        child: Text(
          'Nenhuma anotação encontrada.\nClique no botão + para adicionar.',
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: historico.length,
        itemBuilder: (_, index) {
          final item = historico[index];
          // Gerando uma chave mais robusta para o Dismissible
          // Considerando que a descrição pode mudar, usar id se disponível ou data/hora
          // Se você não tiver um ID único por anotação do serviço,
          // esta chave pode ser problemática se duas anotações tiverem mesma data/hora.
          // Idealmente, cada anotação deveria ter um ID único do backend/serviço.
          final String itemKey = item['id'] ?? '${item['data']}-${item['hora']}-${item['descricao']}-$index';

          return Dismissible(
            key: Key(itemKey),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.redAccent, // Cor um pouco diferente
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_sweep_outlined, color: Colors.white), // Ícone diferente
            ),
            confirmDismiss: (direction) async { // Adiciona confirmação para deletar
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirmar Exclusão"),
                    content: const Text("Você tem certeza que deseja excluir esta anotação?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text("CANCELAR"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("EXCLUIR", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (_) async {
              // Não precisamos mais do if aqui se confirmDismiss retorna true
              await HistoricoService().removerHistorico(widget.caixaId, index);
              // carregarHistorico(); // O setState em onDismissed já atualiza a UI se a lista mudar
              // Remover o item da lista localmente para uma resposta visual mais rápida
              setState(() {
                historico.removeAt(index);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Anotação excluída')),
                );
              }
              // Se você quiser recarregar do serviço para garantir consistência:
              // carregarHistorico();
            },
            child: Card( // Envolve o ListTile em um Card para melhor visual
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                title: Text(item['descricao'] ?? 'Sem descrição'),
                subtitle: Text('${item['data']} às ${item['hora']}'),
                // Adicionar um ícone talvez?
                // leading: Icon(Icons.note_alt_outlined),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended( // Alterado para FloatingActionButton.extended
        onPressed: adicionarEntrada,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Anotar'),
      ),
    );
  }
}
