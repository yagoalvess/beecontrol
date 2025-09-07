import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abelhas/services/historico_service.dart'; // <<< IMPORT REAL DO SEU SERVIÇO

class RegistrarProducaoScreen extends StatefulWidget {
  final String caixaId;
  final Map<String, dynamic>? registroProducaoExistente; // Para edição

  const RegistrarProducaoScreen({
    super.key,
    required this.caixaId,
    this.registroProducaoExistente, // Parâmetro opcional para edição
  });

  @override
  _RegistrarProducaoScreenState createState() => _RegistrarProducaoScreenState();
}

class _RegistrarProducaoScreenState extends State<RegistrarProducaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final HistoricoService _historicoService = HistoricoService(); // <<< INSTANCIE SEU SERVIÇO AQUI

  // Controladores e Variáveis de Estado
  DateTime _dataProducao = DateTime.now();
  String? _selectedCorMel;
  final TextEditingController _quantidadeMelController = TextEditingController();

  bool _produzGeleiaReal = false;
  final TextEditingController _quantidadeGeleiaRealController = TextEditingController();

  bool _produzPropolis = false;
  final TextEditingController _quantidadePropolisController = TextEditingController();

  bool _produzCera = false;
  final TextEditingController _quantidadeCeraController = TextEditingController();

  bool _produzApitoxina = false;
  final TextEditingController _quantidadeApitoxinaController = TextEditingController();

  bool _isSalvando = false;
  bool _isEditando = false; // Flag para saber se está editando
  String? _idProducaoExistente; // Para guardar o ID se estiver editando

  final List<String> _opcoesCorMel = [
    'Branco Água', 'Extra Branco', 'Branco',
    'Âmbar Extra Claro', 'Âmbar Claro', 'Âmbar', 'Âmbar Escuro', 'Escuro (Outro)'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.registroProducaoExistente != null && widget.registroProducaoExistente!.isNotEmpty) {
      _isEditando = true;
      _preencherCamposComDadosExistentes(widget.registroProducaoExistente!);
    }
  }

  void _preencherCamposComDadosExistentes(Map<String, dynamic> dados) {
    _idProducaoExistente = dados['producaoId'] as String?;

    try {
      _dataProducao = DateTime.parse(dados['dataProducao'] as String? ?? DateTime.now().toIso8601String());
    } catch (e) {
      print("Erro ao parsear data existente: ${dados['dataProducao']}, usando data atual.");
      _dataProducao = DateTime.now();
    }

    _selectedCorMel = dados['corDoMel'] as String?;
    _quantidadeMelController.text = (dados['quantidadeMel'] as num?)?.toString().replaceAll('.', ',') ?? ''; // Ajusta para vírgula se necessário para display

    _produzGeleiaReal = dados['produzGeleiaReal'] as bool? ?? false;
    if (_produzGeleiaReal) {
      _quantidadeGeleiaRealController.text = (dados['quantidadeGeleiaReal'] as num?)?.toString().replaceAll('.', ',') ?? '';
    }

    _produzPropolis = dados['produzPropolis'] as bool? ?? false;
    if (_produzPropolis) {
      _quantidadePropolisController.text = (dados['quantidadePropolis'] as num?)?.toString().replaceAll('.', ',') ?? '';
    }

    _produzCera = dados['produzCera'] as bool? ?? false;
    if (_produzCera) {
      _quantidadeCeraController.text = (dados['quantidadeCera'] as num?)?.toString().replaceAll('.', ',') ?? '';
    }

    _produzApitoxina = dados['produzApitoxina'] as bool? ?? false;
    if (_produzApitoxina) {
      _quantidadeApitoxinaController.text = (dados['quantidadeApitoxina'] as num?)?.toString().replaceAll('.', ',') ?? '';
    }
  }

  @override
  void dispose() {
    _quantidadeMelController.dispose();
    _quantidadeGeleiaRealController.dispose();
    _quantidadePropolisController.dispose();
    _quantidadeCeraController.dispose();
    _quantidadeApitoxinaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataProducao,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)), // Limitar a 30 dias no futuro
    );
    if (picked != null && picked != _dataProducao) {
      setState(() {
        _dataProducao = picked;
      });
    }
  }

  Future<void> _salvarProducao() async {
    if (!_formKey.currentState!.validate()) {
      return; // Impede o salvamento se o formulário for inválido
    }
    setState(() {
      _isSalvando = true;
    });

    // Função auxiliar para parsear double, lidando com vírgula e ponto
    double? tryParseDoubleWithComma(String value) {
      if (value.trim().isEmpty) return null;
      return double.tryParse(value.trim().replaceAll(',', '.'));
    }

    Map<String, dynamic> dadosProducao = {
      'caixaId': widget.caixaId,
      'dataProducao': _dataProducao.toIso8601String(),
      'corDoMel': _selectedCorMel,
      'quantidadeMel': tryParseDoubleWithComma(_quantidadeMelController.text),
      'produzGeleiaReal': _produzGeleiaReal,
      'quantidadeGeleiaReal': _produzGeleiaReal ? tryParseDoubleWithComma(_quantidadeGeleiaRealController.text) : null,
      'produzPropolis': _produzPropolis,
      'quantidadePropolis': _produzPropolis ? tryParseDoubleWithComma(_quantidadePropolisController.text) : null,
      'produzCera': _produzCera,
      'quantidadeCera': _produzCera ? tryParseDoubleWithComma(_quantidadeCeraController.text) : null,
      'produzApitoxina': _produzApitoxina,
      'quantidadeApitoxina': _produzApitoxina ? tryParseDoubleWithComma(_quantidadeApitoxinaController.text) : null,
    };

    if (_isEditando && _idProducaoExistente != null) {
      dadosProducao['producaoId'] = _idProducaoExistente;
    }
    // Para nova produção, o HistoricoService irá gerar o 'producaoId'

    print("RegistrarProducaoScreen: Enviando dados para o serviço: $dadosProducao"); // LOG

    // >>> CHAMADA REAL AO SERVIÇO <<<
    bool sucesso = await _historicoService.adicionarRegistroProducao(dadosProducao);

    if (!mounted) return;

    if (sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produção ${_isEditando ? "atualizada" : "registrada"} com sucesso!')),
      );
      Navigator.of(context).pop(true); // Retorna true para CaixaScreen recarregar
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao ${_isEditando ? "atualizar" : "registrar"} produção. Verifique os logs.')),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(title, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          contentPadding: EdgeInsets.zero,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        if (value)
          Padding(
            padding: const EdgeInsets.only(top: 0.0, left: 16.0, right: 16.0, bottom: 8.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: quantityLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (val) {
                if (value && (val == null || val.trim().isEmpty)) {
                  return 'Informe a quantidade';
                }
                if (val != null && val.isNotEmpty) {
                  // Tenta parsear com ponto e com vírgula para validação
                  if (double.tryParse(val.replaceAll(',', '.')) == null) {
                    return 'Número inválido';
                  }
                }
                return null;
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_isEditando ? "Editar" : "Registrar"} Produção - Caixa ${widget.caixaId.replaceAll(RegExp(r'[^0-9]'), '').padLeft(3, '0')}'),
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
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                    onPressed: () => _selecionarData(context),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              Text('Mel', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Cor do Mel', border: OutlineInputBorder()),
                value: _selectedCorMel,
                items: _opcoesCorMel.map((String cor) {
                  return DropdownMenuItem<String>(
                    value: cor,
                    child: Text(cor),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCorMel = newValue;
                  });
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _quantidadeMelController,
                decoration: const InputDecoration(labelText: 'Quantidade de Mel (kg ou L)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Tenta parsear com ponto e com vírgula para validação
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Número inválido';
                    }
                  }
                  return null; // Permite ser vazio se não for obrigatório
                },
              ),
              const SizedBox(height: 24.0),
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
                    if (!val) _quantidadePropolisController.clear();
                  });
                },
                controller: _quantidadePropolisController,
                quantityLabel: 'Quantidade (g ou mL)',
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

              _buildProductSwitch(
                title: 'Apitoxina',
                value: _produzApitoxina,
                onChanged: (bool val) {
                  setState(() {
                    _produzApitoxina = val;
                    if (!val) _quantidadeApitoxinaController.clear();
                  });
                },
                controller: _quantidadeApitoxinaController,
                quantityLabel: 'Quantidade (g ou coletor)',
              ),
              const SizedBox(height: 30.0),

              ElevatedButton.icon(
                icon: _isSalvando
                    ? Container(width: 20, height: 20, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSalvando ? 'Salvando...' : (_isEditando ? 'Atualizar Produção' : 'Salvar Produção')),
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

