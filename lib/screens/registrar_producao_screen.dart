import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart';

class RegistrarProducaoScreen extends StatefulWidget {
  final String caixaId;
  final Map<String, dynamic>? registroProducaoExistente;

  const RegistrarProducaoScreen({
    super.key,
    required this.caixaId,
    this.registroProducaoExistente,
  });

  @override
  _RegistrarProducaoScreenState createState() =>
      _RegistrarProducaoScreenState();
}

class _RegistrarProducaoScreenState extends State<RegistrarProducaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final HistoricoService _historicoService = HistoricoService();

  DateTime _dataProducao = DateTime.now();
  final TextEditingController _quantidadeMelController = TextEditingController();

  // --- CORRIGIDO: Variáveis renomeadas de Geleia Real para Cera de Abelha ---
  bool _produzCeraAbelha = false;
  final TextEditingController _quantidadeCeraController =
  TextEditingController();

  bool _produzPropolis = false;
  final TextEditingController _quantidadePropolisController =
  TextEditingController();
  String? _selectedCorPropolis;
  final List<String> _opcoesCorPropolis = ['Verde', 'Marrom', 'Outra'];


  bool _produzPolen = false;
  final TextEditingController _quantidadePolenController =
  TextEditingController();

  bool _isSalvando = false;
  bool _isEditando = false;
  String? _idProducaoExistente;


  @override
  void initState() {
    super.initState();
    _quantidadeMelController.addListener(() {
      if(mounted) setState(() {});
    });


    if (widget.registroProducaoExistente != null &&
        widget.registroProducaoExistente!.isNotEmpty) {
      _isEditando = true;
      _preencherCamposComDadosExistentes(widget.registroProducaoExistente!);
    }
  }

  void _preencherCamposComDadosExistentes(Map<String, dynamic> dados) {
    _idProducaoExistente = dados['producaoId'] as String?;

    try {
      _dataProducao = DateTime.parse(
          dados['dataProducao'] as String? ?? DateTime.now().toIso8601String());
    } catch (e) {
      _dataProducao = DateTime.now();
    }

    _quantidadeMelController.text =
        (dados['quantidadeMel'] as num?)?.toString().replaceAll('.', ',') ?? '';

    // --- CORRIGIDO: Lógica para preencher os dados de Cera de Abelha ao editar ---
    _produzCeraAbelha = dados['produzCera'] as bool? ?? false;
    if (_produzCeraAbelha) {
      _quantidadeCeraController.text =
          (dados['quantidadeCera'] as num?)
              ?.toString()
              .replaceAll('.', ',') ??
              '';
    }

    _produzPropolis = dados['produzPropolis'] as bool? ?? false;
    if (_produzPropolis) {
      _quantidadePropolisController.text =
          (dados['quantidadePropolis'] as num?)
              ?.toString()
              .replaceAll('.', ',') ??
              '';
      _selectedCorPropolis = dados['corDaPropolis'] as String?;
      if (_selectedCorPropolis != null && !_opcoesCorPropolis.contains(_selectedCorPropolis)) {
        _selectedCorPropolis = null;
      }
    } else {
      _selectedCorPropolis = null;
    }


    _produzPolen = dados['produzPolen'] as bool? ?? false;
    if (_produzPolen) {
      _quantidadePolenController.text =
          (dados['quantidadePolen'] as num?)?.toString().replaceAll('.', ',') ??
              '';
    }
  }

  @override
  void dispose() {
    _quantidadeMelController.dispose();
    _quantidadeCeraController.dispose(); // CORRIGIDO
    _quantidadePropolisController.dispose();
    _quantidadePolenController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataProducao,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _dataProducao) {
      setState(() {
        _dataProducao = picked;
      });
    }
  }

  Future<void> _salvarProducao() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    bool temQuantidadePropolis = (double.tryParse(_quantidadePropolisController.text.replaceAll(',', '.')) ?? 0) > 0;
    if (_produzPropolis && temQuantidadePropolis && _selectedCorPropolis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione a cor da própolis.')),
      );
      return;
    }

    setState(() {
      _isSalvando = true;
    });

    double? tryParseDoubleWithComma(String value) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }

    // --- CORRIGIDO: Mapa de dados para salvar 'produzCera' e 'quantidadeCera' ---
    Map<String, dynamic> dadosProducao = {
      'caixaId': widget.caixaId,
      'dataProducao': _dataProducao.toIso8601String(),
      'quantidadeMel': tryParseDoubleWithComma(_quantidadeMelController.text),

      'produzCera': _produzCeraAbelha, // Chave correta
      'quantidadeCera': _produzCeraAbelha
          ? tryParseDoubleWithComma(_quantidadeCeraController.text)
          : null, // Chave e controller corretos

      'produzPropolis': _produzPropolis,
      'quantidadePropolis': _produzPropolis
          ? tryParseDoubleWithComma(_quantidadePropolisController.text)
          : null,
      'corDaPropolis': _produzPropolis && temQuantidadePropolis ? _selectedCorPropolis : null,

      'produzPolen': _produzPolen,
      'quantidadePolen': _produzPolen
          ? tryParseDoubleWithComma(_quantidadePolenController.text)
          : null,
    };

    if (!(_produzPropolis && temQuantidadePropolis)) {
      dadosProducao.remove('corDaPropolis');
    }

    if (_isEditando && _idProducaoExistente != null) {
      dadosProducao['producaoId'] = _idProducaoExistente;
    }

    print(
        "RegistrarProducaoScreen: Enviando dados para o serviço: $dadosProducao");

    bool sucesso =
    await _historicoService.adicionarRegistroProducao(dadosProducao);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Produção ${_isEditando ? "atualizada" : "registrada"} com sucesso!')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Falha ao ${_isEditando ? "atualizar" : "registrar"} produção. Verifique os logs.')),
      );
    }

    if (mounted) {
      setState(() {
        _isSalvando = false;
      });
    }
  }

  Widget _buildProductSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TextEditingController controller,
    required String quantityLabel,
    Widget? additionalField,
  }) {
    // ... (este widget auxiliar já é genérico e não precisa de mudanças) ...
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(title,
              style:
              const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(
                top: 0.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: quantityLabel,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (text) {
                    if (mounted) setState(() {});
                  },
                  validator: (val) {
                    if (value && (val == null || val.trim().isEmpty)) {
                      return 'Informe a quantidade';
                    }
                    if (val != null && val.isNotEmpty) {
                      if (double.tryParse(val.replaceAll(',', '.')) == null) {
                        return 'Número inválido';
                      }
                    }
                    return null;
                  },
                ),
                if (additionalField != null) ...[
                  const SizedBox(height: 8.0),
                  additionalField,
                ]
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool temQuantidadePropolis = (double.tryParse(
        _quantidadePropolisController.text.replaceAll(',', '.')) ??
        0) >
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${_isEditando ? "Editar" : "Registrar"} Produção - Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ... (widget de Data da Produção) ...
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Data da Produção: ${DateFormat('dd/MM/yyyy').format(_dataProducao)}",
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _selecionarData(context),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              // ... (widget de Mel) ...
              Text('Mel',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8.0),
              TextFormField(
                controller: _quantidadeMelController,
                decoration: const InputDecoration(
                    labelText: 'Quantidade de Mel (kg ou L)',
                    border: OutlineInputBorder()),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Número inválido';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12.0),
              const Divider(),
              const SizedBox(height: 16.0),

              // --- CORRIGIDO: Chamada do _buildProductSwitch para Cera de Abelha ---
              _buildProductSwitch(
                title: 'Cera de Abelha', // Título que você já tinha mudado
                value: _produzCeraAbelha, // Variável correta
                onChanged: (bool val) {
                  setState(() {
                    _produzCeraAbelha = val; // Lógica correta
                    if (!val) _quantidadeCeraController.clear(); // Controller correto
                  });
                },
                controller: _quantidadeCeraController, // Controller correto
                quantityLabel: 'Quantidade (g)',
              ),
              const SizedBox(height: 16.0),

              // ... (widget de Própolis) ...
              _buildProductSwitch(
                title: 'Própolis',
                value: _produzPropolis,
                onChanged: (bool val) {
                  setState(() {
                    _produzPropolis = val;
                    if (!val) {
                      _quantidadePropolisController.clear();
                      _selectedCorPropolis = null;
                    }
                  });
                },
                controller: _quantidadePropolisController,
                quantityLabel: 'Quantidade (g)',
                additionalField: _produzPropolis && temQuantidadePropolis
                    ? DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'Cor da Própolis',
                      border: OutlineInputBorder(),
                      isDense: true),
                  value: _selectedCorPropolis,
                  hint: const Text('Selecione a cor'),
                  isExpanded: true,
                  items: _opcoesCorPropolis.map((String cor) {
                    return DropdownMenuItem<String>(
                      value: cor,
                      child: Text(cor),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCorPropolis = newValue;
                    });
                  },
                  validator: (value) {
                    if (_produzPropolis && temQuantidadePropolis && value == null) {
                      return 'Selecione a cor da própolis';
                    }
                    return null;
                  },
                )
                    : null,
              ),
              const SizedBox(height: 16.0),

              // ... (widget de Pólen) ...
              _buildProductSwitch(
                title: 'Pólen',
                value: _produzPolen,
                onChanged: (bool val) {
                  setState(() {
                    _produzPolen = val;
                    if (!val) _quantidadePolenController.clear();
                  });
                },
                controller: _quantidadePolenController,
                quantityLabel: 'Quantidade (g)',
              ),
              const SizedBox(height: 30.0),

              // ... (botão de Salvar) ...
              ElevatedButton.icon(
                icon: _isSalvando
                    ? Container(
                    width: 20,
                    height: 20,
                    padding: const EdgeInsets.all(2.0),
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSalvando
                    ? 'Salvando...'
                    : (_isEditando ? 'Atualizar Produção' : 'Salvar Produção')),
                onPressed: _isSalvando ? null : _salvarProducao,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
