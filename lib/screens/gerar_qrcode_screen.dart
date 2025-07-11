import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';



class GerarQRCodeScreen extends StatelessWidget {
  final String novoId;

  const GerarQRCodeScreen({super.key, required this.novoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code da Nova Caixa')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ID: $novoId', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
          QrImageView(data: novoId, version: QrVersions.auto, size: 200),
            const SizedBox(height: 20),
            const Text('Imprima ou cole este QR na caixa.'),
          ],
        ),
      ),
    );
  }
}

