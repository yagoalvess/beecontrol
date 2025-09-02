// Caminho do seu arquivo: lib/screens/qr_code_com_texto_widget.dart (ou lib/widgets/)
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeComTextoWidget extends StatelessWidget {
  final String idCaixa;
  final double qrRenderSize;
  final Color backgroundColor;

  const QrCodeComTextoWidget({
    super.key,
    required this.idCaixa,
    this.qrRenderSize = 180.0, // Este valor será substituído pelo que passarmos
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedNumericId = idCaixa.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0');

    return Container(
      // Se backgroundColor for Colors.transparent, este Container não define cor,
      // permitindo que o pai (o Container do RepaintBoundary) controle o fundo.
      // Se uma cor específica for passada (diferente de transparente), ela será usada.
      color: backgroundColor == Colors.transparent ? null : backgroundColor,
      // Padding INTERNO para este widget individual. Mantenha-o razoável.
      padding: const EdgeInsets.all(10.0), // Reduzido de 16.0 para dar mais espaço ao container pai
      child: Column(
        mainAxisSize: MainAxisSize.min, // Importante para que o Column não se estique desnecessariamente
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Caixa-$formattedNumericId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          QrImageView(
            data: idCaixa,
            version: QrVersions.auto,
            size: qrRenderSize, // Este é o tamanho real do QR code visual
            backgroundColor: Colors.transparent, // O QR em si sempre transparente, o Container pai define o fundo da área
            gapless: false,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
          const SizedBox(height: 8),
          Text(
            'CX-$formattedNumericId',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
