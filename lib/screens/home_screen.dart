import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'caixa_screen.dart';
import 'gerar_qrcode_screen.dart';
import 'package:abelhas/services/historico_service.dart';
import 'apiarios_screen.dart'; // Import da tela de listagem de apiários

// Classe principal que agora é um StatefulWidget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _locaisPreDefinidos = const [
    'Apiário Central',
    'Apiário do Sul',
    'Apiário da Fazenda Nova',
    'Apiário Experimental',
    'Apiário da Mata',
  ];

  void _navegarParaCaixa(BuildContext context, String caixaId, String localRealDaCaixa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaixaScreen(
          caixaId: caixaId,
          localCaixa: localRealDaCaixa,
        ),
      ),
    );
  }

  void _criarNovaCaixa(BuildContext context) async {
    final historicoService = HistoricoService();

    String? localDaNovaCaixa = await _showInputDialog(
      context,
      'Local do Novo colmeias',
      'Digite ou selecione o nome do local',
      _locaisPreDefinidos,
    );

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
        const SnackBar(content: Text('Criação da colmeia cancelada. Local não informado.')),
      );
    }
  }

  Future<String?> _showInputDialog(
      BuildContext context,
      String title,
      String hintText,
      List<String> predefinedOptions,
      ) async {
    TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...predefinedOptions.map((option) {
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      Navigator.of(context).pop(option);
                    },
                  );
                }).toList(),

                const Divider(),

                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: hintText),
                  autofocus: true,
                ),
              ],
            ),
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
                if (controller.text.isNotEmpty) {
                  Navigator.of(context).pop(controller.text);
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Lógica para navegação
  void _verCaixasSalvas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiariosScreen(),
      ),
    );
  }

  void _lerQRCode(BuildContext context) async {
    final codigoLido = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
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
    final List<_MenuItem> menuItens = [
      _MenuItem("Ler Caixa", Icons.qr_code_scanner, Colors.deepOrange, () => _lerQRCode(context)),
      _MenuItem("Nova Caixa", Icons.add_box_outlined, Colors.blue, () => _criarNovaCaixa(context)),
      _MenuItem("Ver Colmeias", Icons.folder_open_outlined, Colors.purple, () => _verCaixasSalvas(context)),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('BeeControl')),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: menuItens.map((item) {
            return SizedBox(
              width: 100,
              height: 100,
              child: ElevatedButton(
                onPressed: item.acao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.cor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icone, size: 28, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      item.titulo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ... Código das outras classes (ScannerScreen, etc.) ...
// A classe _MenuItem deve estar no final do arquivo, como estava originalmente.
class _MenuItem {
  final String titulo;
  final IconData icone;
  final Color cor;
  final VoidCallback acao;

  _MenuItem(this.titulo, this.icone, this.cor, this.acao);
}

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
      appBar: AppBar(title: const Text('Ler Caixa')),
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