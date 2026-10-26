import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myworksapp/core/theme/app_colors.dart';

enum SiiDocumentType {
  boletaHonorarios('Boleta de Honorarios Electrónica'),
  factura('Factura');

  const SiiDocumentType(this.label);
  final String label;
}

/// Formulario local de datos tributarios del especialista.
/// El estado queda en controladores y en SharedPreferences; no usa Supabase.
class SiiTaxInfoWidget extends StatefulWidget {
  const SiiTaxInfoWidget({super.key});

  @override
  State<SiiTaxInfoWidget> createState() => _SiiTaxInfoWidgetState();
}

class _SiiTaxInfoWidgetState extends State<SiiTaxInfoWidget> {
  static const _rutKey = 'sii_tax_rut_razon_social';
  static const _giroKey = 'sii_tax_giro';
  static const _docKey = 'sii_tax_document_type';

  final _formKey = GlobalKey<FormState>();
  final _rutController = TextEditingController();
  final _giroController = TextEditingController();
  SiiDocumentType _documentType = SiiDocumentType.boletaHonorarios;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rutController.dispose();
    _giroController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final stored = prefs.getString(_docKey);
    setState(() {
      _rutController.text = prefs.getString(_rutKey) ?? '';
      _giroController.text = prefs.getString(_giroKey) ?? '';
      _documentType = SiiDocumentType.values.firstWhere(
        (type) => type.name == stored,
        orElse: () => SiiDocumentType.boletaHonorarios,
      );
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rutKey, _rutController.text.trim());
    await prefs.setString(_giroKey, _giroController.text.trim());
    await prefs.setString(_docKey, _documentType.name);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Datos tributarios guardados en este dispositivo'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SiiHonorariosBanner(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Datos para boleta / SII',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Se guardan solo en este dispositivo. No se envían a un servidor.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rutController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'RUT / Razón Social',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Ingresa el RUT o la razón social';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _giroController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Giro o actividad económica',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 3) {
                              return 'Ingresa el giro o la actividad económica';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tipo de documento',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        RadioGroup<SiiDocumentType>(
                          groupValue: _documentType,
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _documentType = value);
                          },
                          child: Column(
                            children: [
                              for (final type in SiiDocumentType.values)
                                RadioListTile<SiiDocumentType>(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(type.label),
                                  value: type,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Guardar datos tributarios'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SiiHonorariosBanner extends StatelessWidget {
  const _SiiHonorariosBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.infoSoft,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Boleta de Honorarios al liberar el Escrow',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando el pago en garantía queda liberado, emite la boleta en el portal del SII con estos 3 pasos:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            const _Step(
              number: '1',
              text:
                  'Ingresa a sii.cl con tu Clave Única o Clave Tributaria.',
            ),
            const _Step(
              number: '2',
              text:
                  'Abre Servicios online, luego Boletas de honorarios electrónicas y elige Emitir boleta.',
            ),
            const _Step(
              number: '3',
              text:
                  'Indica el RUT del pagador y el monto bruto del servicio liberado, emite la boleta y descarga el comprobante.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.info,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
