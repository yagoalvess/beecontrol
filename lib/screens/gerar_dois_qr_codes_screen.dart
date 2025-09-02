// lib/screens/gerar_dois_qr_codes_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'qr_code_com_texto_widget.dart'; // Ajuste o caminho se necessário

class GerarDoisQrCodesScreen extends StatefulWidget { // Já é StatefulWidget
  final String idCaixa1;
  final String idCaixa2;

  const GerarDoisQrCodesScreen({
    super.key,
    required this.idCaixa1,
    required this.idCaixa2,
  });

  @override
  State<GerarDoisQrCodesScreen> createState() => _GerarDoisQrCodesScreenState();
}

class _GerarDoisQrCodesScreenState extends State<GerarDoisQrCodesScreen> {
  final GlobalKey _doisQrKey = GlobalKey();

  // --- ESTADO PARA O TAMANHO DO QR CODE ---
  double _tamanhoSelecionadoQr = 120.0; // Valor inicial
  final double _minQrSize = 80.0;
  final double _maxQrSize = 200.0;

  // O padding da imagem também pode ser ajustado com base no tamanho do QR,
  // mas para simplificar, vamos mantê-lo fixo por enquanto ou torná-lo uma constante grande.
  final double _margemInternaDaImagemGerada = 30.0;

  Future<void> _compartilharDoisQrCodes(BuildContext context) async {
    // ... (código de compartilhamento existente, sem alterações aqui) ...
    // ... ele já usará o tamanho renderizado pelos widgets ...
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final boundary = _doisQrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('QR Code ainda não foi renderizado.');
      }
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        throw Exception('Falha ao obter bytes da imagem.');
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dois_qr_codes_para_impressao.png');
      await file.writeAsBytes(pngBytes);
      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'QR Codes para Caixas: ${widget.idCaixa1} e ${widget.idCaixa2}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar QR Codes: ${e.toString()}')),
        );
      }
      print('Erro ao compartilhar: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Espaço vertical entre os dois widgets de QR code
    const double espacoEntreOsQrWidgets = 15.0;
    const Color corDeFundoDaAreaDeCaptura = Colors.white;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('QR Codes para Impressão'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _compartilharDoisQrCodes(context),
            tooltip: 'Compartilhar Imagem',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // Padding da tela
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Pré-visualização para impressão:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // --- CONTROLE DE TAMANHO ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  children: [
                    Text('Ajustar Tamanho do QR Code: ${_tamanhoSelecionadoQr.round()}'),
                    Slider(
                      value: _tamanhoSelecionadoQr,
                      min: _minQrSize,
                      max: _maxQrSize,
                      divisions: ((_maxQrSize - _minQrSize) / 10).round(), // Ex: divisões a cada 10 pixels
                      label: _tamanhoSelecionadoQr.round().toString(),
                      onChanged: (double value) {
                        setState(() {
                          _tamanhoSelecionadoQr = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              // --- FIM DO CONTROLE DE TAMANHO ---

              const SizedBox(height: 10),

              // --- ÁREA DE CAPTURA DO REPAINTBOUNDARY ---
              RepaintBoundary(
                key: _doisQrKey,
                child: Container(
                  color: corDeFundoDaAreaDeCaptura,
                  padding: EdgeInsets.all(_margemInternaDaImagemGerada), // Usa a margem definida
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QrCodeComTextoWidget(
                        idCaixa: widget.idCaixa1,
                        qrRenderSize: _tamanhoSelecionadoQr, // Usa o tamanho do estado
                        backgroundColor: Colors.transparent,
                      ),
                      const SizedBox(height: espacoEntreOsQrWidgets),
                      QrCodeComTextoWidget(
                        idCaixa: widget.idCaixa2,
                        qrRenderSize: _tamanhoSelecionadoQr, // Usa o tamanho do estado
                        backgroundColor: Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
              // --- FIM DA ÁREA DE CAPTURA ---

              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () => _compartilharDoisQrCodes(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Compartilhar / Imprimir'),
              ),
              const SizedBox(height: 15),
              const Text(
                'A imagem gerada conterá os dois QR Codes acima.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

