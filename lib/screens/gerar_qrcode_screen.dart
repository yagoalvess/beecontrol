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
    // Formata o ID para exibição: remove não-dígitos, preenche com zeros
    final String formattedNumericId = novoId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('QR Code da Nova Caixa')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ALTERADO AQUI: Substitui "ID: $novoId" por "Caixa-$formattedNumericId"
            Text(
              'Caixa-$formattedNumericId', // Exibe "Caixa-001", "Caixa-002", etc.
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            RepaintBoundary(
              key: _qrKey,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: novoId,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    // Mantém o texto abaixo do QR Code como "CX-00X" (ou o que estava antes)
                    Text(
                      'CX-${novoId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}', // Mantém a formatação original que você tinha para esta linha
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text('Imprima e cole este QR na caixa.'),

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => _compartilharQRCode(context),
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar/Imprimir QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}