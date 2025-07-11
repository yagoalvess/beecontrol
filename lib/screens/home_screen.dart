import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'caixa_screen.dart';
import 'gerar_qrcode_screen.dart';
import 'package:abelhas/services/historico_service.dart'; // Importe o serviço correct








class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navegarParaCaixa(BuildContext context, String caixaId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CaixaScreen(caixaId: caixaId)),
    );
  }

  void _criarNovaCaixa(BuildContext context) async {
    String novoId = await HistoricoService().gerarNovoId();
    await HistoricoService().criarCaixa(novoId);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GerarQRCodeScreen(novoId: novoId)),
    );
  }

  void _verCaixasSalvas(BuildContext context) async {
    final caixas = await HistoricoService().getTodasCaixas();
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        children: caixas.map((id) {
          return ListTile(
            title: Text(id),
            onTap: () {
              Navigator.pop(context);
              _navegarParaCaixa(context, id);
            },
          );
        }).toList(),
      ),
    );
  }

  void _lerQRCode(BuildContext context) async {
    final codigo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ScannerScreen()),
    );
    if (codigo != null) _navegarParaCaixa(context, codigo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BeeControl - Caixas de Abelhas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () => _lerQRCode(context), child: const Text('📷 Ler QR Code')),
            ElevatedButton(onPressed: () => _criarNovaCaixa(context), child: const Text('➕ Nova Caixa')),
            ElevatedButton(onPressed: () => _verCaixasSalvas(context), child: const Text('📂 Ver Caixas')),
          ],
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController();
  bool _codigoLido = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_codigoLido) return; // bloqueia leitura repetida

          final barcode = capture.barcodes.first;
          final String? codigo = barcode.rawValue;

          if (codigo != null && mounted) {
            _codigoLido = true;

            Navigator.pop(context, codigo);
          }
        },
      ),
    );
  }
}

