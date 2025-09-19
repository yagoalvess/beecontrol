import 'package:abelhas/screens/RelatoriosConsolidadosScreen.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:abelhas/services/historico_service.dart';
import 'package:abelhas/screens/caixa_screen.dart';
import 'package:abelhas/screens/gerar_qrcode_screen.dart';
import 'package:abelhas/screens/apiarios_screen.dart';
import 'package:abelhas/screens/gerar_dois_qr_codes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  Future<String?> _showInputDialogParaCriacao(
      BuildContext context,
      String title,
      String hintText,
      List<String> predefinedOptions,
      ) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (predefinedOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text("Ou selecione um local existente:", style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ...predefinedOptions.map((option) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      title: Text(option, style: const TextStyle(fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.of(dialogContext).pop(option);
                      },
                    ),
                  );
                }).toList(),
                if (predefinedOptions.isNotEmpty) const SizedBox(height: 16),
                if (predefinedOptions.isNotEmpty)
                  Row(
                    children: <Widget>[
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("OU", style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                if (predefinedOptions.isNotEmpty) const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Ex: Apiário da Fazenda',
                    labelText: 'Novo Nome do Local',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.edit_location_alt, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  autofocus: predefinedOptions.isEmpty,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text('Cancelar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Salvar Novo'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, digite o nome do local para criar um novo ou selecione um existente.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _criarNovaCaixa(BuildContext context) async {
    final historicoService = HistoricoService();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Buscando locais..."),
              ],
            ),
          ),
        );
      },
    );
    List<String> locaisExistentes = await historicoService.getLocaisUnicos();
    if (mounted) {
      Navigator.pop(context);
    } else {
      return;
    }
    if (!mounted) return;

    String? localDaNovaCaixa = await _showInputDialogParaCriacao(
      context,
      'Criar Nova Colmeia',
      'Digite o local ou escolha um existente',
      locaisExistentes,
    );

    if (localDaNovaCaixa != null && localDaNovaCaixa.isNotEmpty) {
      String novoId = await historicoService.gerarNovoId();
      await historicoService.criarCaixa(novoId, localDaNovaCaixa);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GerarQRCodeScreen(novoId: novoId)),
      );
    }
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Carregando caixas..."),
              ],
            ),
          ),
        );
      },
    );
    _listaDeTodasAsCaixasParaSelecao = await historicoService.getTodasCaixasComLocal();
    if(mounted) Navigator.pop(context); else return;

    if (!context.mounted) return;
    if (_listaDeTodasAsCaixasParaSelecao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma caixa criada para selecionar.')),
      );
      return;
    }
    _caixasSelecionadasParaImpressaoDupla.clear();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext modalContext) {
        Set<String> selecaoNoModal = Set.from(_caixasSelecionadasParaImpressaoDupla);
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter modalSetState) {
            return SizedBox(
              height: MediaQuery.of(modalContext).size.height * 0.75,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Text(
                      'Selecione 2 Caixas (${selecaoNoModal.length}/2)',
                      style: Theme.of(innerContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                        final bool isSelected = selecaoNoModal.contains(idCaixa);
                        return CheckboxListTile(
                          title: Text('Caixa: $idCaixa', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Local: $localCaixa'),
                          value: isSelected,
                          activeColor: Theme.of(innerContext).primaryColor,
                          onChanged: (bool? selecionado) {
                            modalSetState(() {
                              if (selecionado == true) {
                                if (selecaoNoModal.length < 2) {
                                  selecaoNoModal.add(idCaixa);
                                } else {
                                  ScaffoldMessenger.of(modalContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('Máximo de 2 caixas já selecionadas. Desmarque uma primeiro.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                selecaoNoModal.remove(idCaixa);
                              }
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
                        backgroundColor: Theme.of(innerContext).primaryColor,
                        foregroundColor: Theme.of(innerContext).colorScheme.onPrimary,
                      ),
                      onPressed: selecaoNoModal.length == 2
                          ? () {
                        setState(() {
                          _caixasSelecionadasParaImpressaoDupla.clear();
                          _caixasSelecionadasParaImpressaoDupla.addAll(selecaoNoModal);
                        });
                        Navigator.pop(modalContext);
                        if (mounted) {
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

    if (codigoLido != null && codigoLido.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Verificando caixa..."),
                ],
              ),
            ),
          );
        },
      );
      final historicoService = HistoricoService();
      final List<Map<String, dynamic>> todasAsCaixas = await historicoService.getTodasCaixasComLocal();
      if(mounted) Navigator.pop(context); else return;

      final caixaEncontrada = todasAsCaixas.firstWhere(
            (caixa) => caixa['id']?.toString() == codigoLido,
        orElse: () => <String, dynamic>{},
      );

      if (caixaEncontrada.isNotEmpty && mounted) {
        final String localDaCaixaParaNavegar = caixaEncontrada['local']?.toString() ?? 'Local Desconhecido';
        _navegarParaCaixa(context, codigoLido, localDaCaixaParaNavegar);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Caixa com ID "$codigoLido" não encontrada.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_MenuItem> menuItensPrincipais = [
      _MenuItem("Ler Caixa", Icons.qr_code_scanner, Colors.deepOrange, () => _lerQRCode(context)),
      _MenuItem("Ver Colmeias", Icons.folder_open_outlined, Colors.purple, () => _verCaixasSalvas(context)),
      _MenuItem(
        "Relatórios Produção",
        Icons.insights,
        Colors.black,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RelatoriosConsolidadosScreen()),
          );
        },
      ),
    ];

    // **** AJUSTE DE PERFORMANCE: CÁLCULO DA LARGURA DO BOTÃO FORA DO .map() ****
    double screenWidth = MediaQuery.of(context).size.width;
    int itemsPerRow = screenWidth > (700 - 32) ? 3 : 2;
    double availableWidthForWrap = screenWidth - (16.0 * 2); // Considera o padding do body
    double totalHorizontalSpacingInWrap = (itemsPerRow - 1) * 16.0;
    double buttonWidth = (availableWidthForWrap - totalHorizontalSpacingInWrap) / itemsPerRow;

    if (buttonWidth < 140) buttonWidth = 140;
    if (buttonWidth > 220 && itemsPerRow == 2) buttonWidth = 220;
    if (buttonWidth > 190 && itemsPerRow == 3) buttonWidth = 190;
    // **** FIM DO AJUSTE DE PERFORMANCE ****

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('BeeControl'),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hive_outlined, size: 40, color: Colors.black87.withOpacity(0.8)),
                  const SizedBox(height: 10),
                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.add_box_outlined, color: Colors.blue.shade700),
              title: const Text('Criar Nova Caixa', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _criarNovaCaixa(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.qr_code_2_sharp, color: Colors.teal.shade700),
              title: const Text('Imprimir 2 QR Codes', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                _selecionarCaixasParaImpressaoDupla(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: Colors.grey.shade700),
              title: const Text('Sobre', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'BeeControl',
                  applicationVersion: '1.0.1',
                  applicationIcon: const Icon(Icons.hive_outlined, size: 40, color: Color(0xFFFFC107)),
                  applicationLegalese: '© 2023-2024 Seu Nome/Empresa',
                  children: <Widget>[
                    const Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text('Aplicativo para gerenciamento eficiente de apiários e colmeias.')
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acesso Rápido',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: menuItensPrincipais.map((item) {
                    // USA O buttonWidth CALCULADO FORA DO MAP
                    return SizedBox(
                      width: buttonWidth, // Variável calculada acima
                      height: 125,
                      child: ElevatedButton(
                        onPressed: item.acao,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.cor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.4),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(item.icone, size: 36, color: Colors.white),
                            const SizedBox(height: 10),
                            Text(
                              item.titulo,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
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
            ),
          ],
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
      appBar: AppBar(
        title: const Text('Ler Caixa'),
        backgroundColor: const Color(0xFFFFC107),
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.black54);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellowAccent);
                }
              },
            ),
            tooltip: 'Lanterna',
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.black54);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.black54);
                }
              },
            ),
            tooltip: 'Virar Câmera',
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (_codigoLido || !mounted) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? codigo = barcodes.first.rawValue;
                if (codigo != null && codigo.isNotEmpty) {
                  setState(() {
                    _codigoLido = true;
                  });
                  if (mounted) Navigator.pop(context, codigo);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent.withOpacity(0.7), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
