import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'caixa_screen.dart';
import 'gerar_qrcode_screen.dart';
import 'package:abelhas/services/historico_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // PASSO 1: Modificar _navegarParaCaixa
  void _navegarParaCaixa(BuildContext context, String caixaId, String localRealDaCaixa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaixaScreen(
          caixaId: caixaId,
          localCaixa: localRealDaCaixa, // Usa o local recebido
        ),
      ),
    );
  }

  void _criarNovaCaixa(BuildContext context) async {
    final historicoService = HistoricoService();
    String? localDaNovaCaixa = await _showInputDialog(
        context, 'Local da Nova Caixa', 'Digite o nome do local');

    if (localDaNovaCaixa != null && localDaNovaCaixa.isNotEmpty) {
      String novoId = await historicoService.gerarNovoId();
      await historicoService.criarCaixa(novoId, localDaNovaCaixa);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GerarQRCodeScreen(novoId: novoId)),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Criação de caixa cancelada. Local não informado.')),
      );
    }
  }

  Future<String?> _showInputDialog(BuildContext context, String title, String hintText) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _verCaixasSalvas(BuildContext context) async {
    final caixasComLocal = await HistoricoService().getTodasCaixasComLocal();

    if (!context.mounted) return;

    if (caixasComLocal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma caixa salva ainda.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.builder(
        itemCount: caixasComLocal.length,
        itemBuilder: (context, index) {
          final caixaData = caixasComLocal[index];
          final String id = caixaData['id'] ?? 'ID Desconhecido';
          final String local = caixaData['local']?.isNotEmpty == true ? caixaData['local']! : 'Local Desconhecido';


          return ListTile(
            title: Text('Caixa: $id'),
            subtitle: Text('Local: $local'),
            onTap: () {
              Navigator.pop(context);
              // PASSO 2: Corrigir chamada aqui
              _navegarParaCaixa(context, id, local);
            },
          );
        },
      ),
    );
  }

  // PASSO 3: Corrigir _lerQRCode
  void _lerQRCode(BuildContext context) async {
    final codigoLido = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()), // Use const
    );

    if (codigoLido != null && codigoLido.isNotEmpty && context.mounted) {
      final historicoService = HistoricoService();
      final todasAsCaixas = await historicoService.getTodasCaixasComLocal();

      final caixaEncontrada = todasAsCaixas.firstWhere(
            (caixa) => caixa['id'] == codigoLido,
        orElse: () => <String, String>{},
      );

      if (caixaEncontrada.isNotEmpty && context.mounted) {
        final String localDaCaixaParaNavegar = caixaEncontrada['local']?.isNotEmpty == true
            ? caixaEncontrada['local']!
            : 'Local Desconhecido';

        _navegarParaCaixa(context, codigoLido, localDaCaixaParaNavegar);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Caixa com ID "$codigoLido" não encontrada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... seu build method permanece o mesmo
    return Scaffold(
      appBar: AppBar(title: const Text('BeeControl')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Ler QR Code'),
              onPressed: () => _lerQRCode(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Nova Caixa'),
              onPressed: () => _criarNovaCaixa(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Ver Caixas'),
              onPressed: () => _verCaixasSalvas(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ... Sua classe ScannerScreen permanece a mesma
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _codigoLido = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_codigoLido || !mounted) return;

          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? codigo = barcodes.first.rawValue;

            if (codigo != null) {
              setState(() {
                _codigoLido = true;
              });
              Navigator.pop(context, codigo);
            }
          }
        },
      ),
    );
  }
}
