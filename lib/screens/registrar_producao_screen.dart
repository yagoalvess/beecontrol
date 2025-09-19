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
  // REMOVIDO: _selectedCorMel
  final TextEditingController _quantidadeMelController = TextEditingController();

  bool _produzGeleiaReal = false;
  final TextEditingController _quantidadeGeleiaRealController =
  TextEditingController();

  bool _produzPropolis = false;
  final TextEditingController _quantidadePropolisController =
  TextEditingController();
  // NOVO: Estado para cor da Própolis
  String? _selectedCorPropolis;
  final List<String> _opcoesCorPropolis = ['Verde', 'Marrom', 'Outra'];


  bool _produzCera = false;
  final TextEditingController _quantidadeCeraController =
  TextEditingController();

  bool _isSalvando = false;
  bool _isEditando = false;
  String? _idProducaoExistente;

  // REMOVIDO: Listas de cores de mel
  // final List<String> _opcoesCorMelPadrao = [...];
  // final List<String> _opcoesCorMelPropolis = [...];
  // List<String> _opcoesCorMelAtuais = [];


  @override
  void initState() {
    super.initState();
    // Não precisamos mais de listeners complexos para cor do mel
    _quantidadeMelController.addListener(() {
      if(mounted) setState(() {}); // Para atualizar temQuantidadeMel se necessário
    });


    if (widget.registroProducaoExistente != null &&
        widget.registroProducaoExistente!.isNotEmpty) {
      _isEditando = true;
      _preencherCamposComDadosExistentes(widget.registroProducaoExistente!);
    }
  }

  // REMOVIDO: _atualizarOpcoesCorMelDropdown()
  // REMOVIDO: _onQuantidadeMelChanged() (a lógica simples foi para o listener anônimo acima)


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
    // REMOVIDO: _selectedCorMel = dados['corDoMel'] as String?;


    _produzGeleiaReal = dados['produzGeleiaReal'] as bool? ?? false;
    if (_produzGeleiaReal) {
      _quantidadeGeleiaRealController.text =
          (dados['quantidadeGeleiaReal'] as num?)
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
      // NOVO: Carregar cor da Própolis
      _selectedCorPropolis = dados['corDaPropolis'] as String?;
      // Garante que a cor selecionada está na lista de opções válidas
      if (_selectedCorPropolis != null && !_opcoesCorPropolis.contains(_selectedCorPropolis)) {
        _selectedCorPropolis = null; // Reseta se não for uma opção válida
      }
    } else {
      _selectedCorPropolis = null; // Garante que está nulo se não produz própolis
    }


    _produzCera = dados['produzCera'] as bool? ?? false;
    if (_produzCera) {
      _quantidadeCeraController.text =
          (dados['quantidadeCera'] as num?)?.toString().replaceAll('.', ',') ??
              '';
    }
  }

  @override
  void dispose() {
    _quantidadeMelController.dispose();
    _quantidadeGeleiaRealController.dispose();
    _quantidadePropolisController.dispose();
    _quantidadeCeraController.dispose();
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
    // Validação para cor da Própolis se Própolis estiver ativa e com quantidade
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

    Map<String, dynamic> dadosProducao = {
      'caixaId': widget.caixaId,
      'dataProducao': _dataProducao.toIso8601String(),
      // REMOVIDO: 'corDoMel'
      'quantidadeMel': tryParseDoubleWithComma(_quantidadeMelController.text),
      'produzGeleiaReal': _produzGeleiaReal,
      'quantidadeGeleiaReal': _produzGeleiaReal
          ? tryParseDoubleWithComma(_quantidadeGeleiaRealController.text)
          : null,
      'produzPropolis': _produzPropolis,
      'quantidadePropolis': _produzPropolis
          ? tryParseDoubleWithComma(_quantidadePropolisController.text)
          : null,
      // NOVO: Salvar cor da Própolis
      'corDaPropolis': _produzPropolis && temQuantidadePropolis ? _selectedCorPropolis : null,

      'produzCera': _produzCera,
      'quantidadeCera': _produzCera
          ? tryParseDoubleWithComma(_quantidadeCeraController.text)
          : null,
    };

    // Remove a chave 'corDaPropolis' se não for aplicável
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
    Widget? additionalField, // NOVO: Campo adicional (para o dropdown de cor da própolis)
  }) {
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
            child: Column( // Envolve em Column para adicionar o campo adicional
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
                  onChanged: (text) { // Adicionado onChanged para forçar rebuild se necessário
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
                if (additionalField != null) ...[ // Adiciona o campo adicional se fornecido
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
    bool temQuantidadeMel = (double.tryParse(
        _quantidadeMelController.text.replaceAll(',', '.')) ??
        0) >
        0;
    bool temQuantidadePropolis = (double.tryParse(
        _quantidadePropolisController.text.replaceAll(',', '.')) ??
        0) >
        0; // Usado para mostrar cor da própolis


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

              // REMOVIDO: Dropdown de cor do mel
              // if (temQuantidadeMel) DropdownButtonFormField<String>(...),


              const SizedBox(height: 12.0),
              const Divider(),
              const SizedBox(height: 16.0),

              _buildProductSwitch(
                title: 'Geleia Real',
                value: _produzGeleiaReal,
                onChanged: (bool val) {
                  setState(() {
                    _produzGeleiaReal = val;
                    if (!val) _quantidadeGeleiaRealController.clear();
                  });
                },
                controller: _quantidadeGeleiaRealController,
                quantityLabel: 'Quantidade (g)',
              ),
              const SizedBox(height: 16.0),

              _buildProductSwitch(
                title: 'Própolis',
                value: _produzPropolis,
                onChanged: (bool val) {
                  setState(() {
                    _produzPropolis = val;
                    if (!val) {
                      _quantidadePropolisController.clear();
                      _selectedCorPropolis = null; // Reseta cor se desabilitar
                    }
                    // O setState já vai reconstruir e o additionalField será avaliado
                  });
                },
                controller: _quantidadePropolisController,
                quantityLabel: 'Quantidade (g ou mL)',
                // NOVO: Adiciona o dropdown de cor da Própolis aqui
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
                    : null, // Não mostra o dropdown se não for aplicável
              ),
              const SizedBox(height: 16.0),

              _buildProductSwitch(
                title: 'Cera de Abelha',
                value: _produzCera,
                onChanged: (bool val) {
                  setState(() {
                    _produzCera = val;
                    if (!val) _quantidadeCeraController.clear();
                  });
                },
                controller: _quantidadeCeraController,
                quantityLabel: 'Quantidade (kg ou placas)',
              ),
              const SizedBox(height: 16.0),

              const SizedBox(height: 30.0),
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

