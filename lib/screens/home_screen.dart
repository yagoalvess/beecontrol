import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'caixa_screen.dart';
import 'gerar_qrcode_screen.dart';
import 'package:abelhas/services/historico_service.dart';
import 'apiarios_screen.dart';
import 'gerar_dois_qr_codes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> _locaisPreDefinidos = const [
    'Apiário Central',
    'Apiário do Sul',
    'Apiário Experimental',
    'Apiário da Mata',
  ];

  final Set<String> _caixasSelecionadasParaImpressaoDupla = {};
  List<Map<String, dynamic>> _listaDeTodasAsCaixasParaSelecao = [];

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
      'Criar Nova Colmeia',
      'Digite o local ou escolha um existente',
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...predefinedOptions.map((option) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      title: Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.of(context).pop(option);
                      },
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    labelText: 'Nome do Local',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.edit_location_alt, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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

  void _verCaixasSalvas(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiariosScreen(),
      ),
    );
  }

  void _selecionarCaixasParaImpressaoDupla(BuildContext context) async {
    final historicoService = HistoricoService();
    _listaDeTodasAsCaixasParaSelecao = await historicoService.getTodasCaixasComLocal();

    if (!context.mounted) return;

    if (_listaDeTodasAsCaixasParaSelecao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma caixa criada para selecionar.')),
      );
      return;
    }

    setState(() {
      _caixasSelecionadasParaImpressaoDupla.clear();
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return SizedBox(
              height: MediaQuery.of(modalContext).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text(
                      'Selecione 2 Caixas (${_caixasSelecionadasParaImpressaoDupla.length}/2)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _listaDeTodasAsCaixasParaSelecao.isEmpty
                        ? const Center(child: Text('Nenhuma caixa encontrada.'))
                        : ListView.builder(
                      itemCount: _listaDeTodasAsCaixasParaSelecao.length,
                      itemBuilder: (ctx, index) {
                        final caixa = _listaDeTodasAsCaixasParaSelecao[index];
                        final String idCaixa = caixa['id']?.toString() ?? 'ID Desconhecido';
                        final String localCaixa = caixa['local']?.toString() ?? 'Local não definido';
                        final isSelected = _caixasSelecionadasParaImpressaoDupla.contains(idCaixa);

                        return CheckboxListTile(
                          title: Text('Caixa: $idCaixa', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Local: $localCaixa'),
                          value: isSelected,
                          onChanged: (bool? selecionado) {
                            modalSetState(() {
                              setState(() {
                                if (selecionado == true) {
                                  if (_caixasSelecionadasParaImpressaoDupla.length < 2) {
                                    _caixasSelecionadasParaImpressaoDupla.add(idCaixa);
                                  } else {
                                    ScaffoldMessenger.of(modalContext).showSnackBar(
                                      const SnackBar(
                                        content: Text('Máximo de 2 caixas já selecionadas. Desmarque uma primeiro.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else {
                                  _caixasSelecionadasParaImpressaoDupla.remove(idCaixa);
                                }
                              });
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_2_outlined),
                      label: const Text('Gerar QR Codes Empilhados'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _caixasSelecionadasParaImpressaoDupla.length == 2
                          ? () {
                        Navigator.pop(modalContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GerarDoisQrCodesScreen(
                              idCaixa1: _caixasSelecionadasParaImpressaoDupla.first,
                              idCaixa2: _caixasSelecionadasParaImpressaoDupla.last,
                            ),
                          ),
                        );
                      }
                          : null,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _lerQRCode(BuildContext context) async {
    final codigoLido = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (codigoLido != null && codigoLido.isNotEmpty && context.mounted) {
      final historicoService = HistoricoService();
      final List<Map<String, dynamic>> todasAsCaixas = await historicoService.getTodasCaixasComLocal();

      final caixaEncontrada = todasAsCaixas.firstWhere(
            (caixa) => caixa['id']?.toString() == codigoLido,
        orElse: () => <String, dynamic>{},
      );

      if (caixaEncontrada.isNotEmpty && context.mounted) {
        final String localDaCaixaParaNavegar = caixaEncontrada['local']?.toString() ?? 'Local Desconhecido';
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
      _MenuItem(
        "Imprimir 2 QR Codes",
        Icons.qr_code_2_sharp,
        Colors.teal,
            () => _selecionarCaixasParaImpressaoDupla(context),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('BeeControl')),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: menuItens.map((item) {
            double buttonWidth = (MediaQuery.of(context).size.width / 2) - (12 * 1.5);
            if (buttonWidth < 100) buttonWidth = 100;

            return SizedBox(
              width: buttonWidth,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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