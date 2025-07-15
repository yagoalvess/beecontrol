import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GerarQRCodeScreen extends StatelessWidget {
  final String novoId;
  GerarQRCodeScreen({super.key, required this.novoId});

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _compartilharQRCode(BuildContext context) async {
    try {
      // Aguarda o próximo frame para garantir que o QR foi renderizado
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('QR Code ainda não foi renderizado.');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_code.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'QR Code: $novoId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar QR Code: $e')),
      );
    }
  }

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

            RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: novoId,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white, // Garante fundo branco
              ),
            ),

            const SizedBox(height: 20),
            const Text('Imprima ou cole este QR na caixa.'),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _compartilharQRCode(context),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
