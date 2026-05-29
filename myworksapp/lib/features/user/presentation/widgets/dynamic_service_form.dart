import 'package:flutter/material.dart';
import '../../../../core/database/models/service_config_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Widget para renderizar campos dinámicos de servicio
/// 
/// Renderiza campos según el schema JSON de service_configs.
/// Soporta: text, select, number, boolean.
/// 
/// Retorna un Map<String, dynamic> con los valores ingresados.
class DynamicServiceForm extends StatefulWidget {
  final ServiceConfigModel config;
  final Map<String, dynamic>? initialValues;
  final Function(Map<String, dynamic>) onChanged;
  final GlobalKey<FormState>? formKey;

  const DynamicServiceForm({
    super.key,
    required this.config,
    this.initialValues,
    required this.onChanged,
    this.formKey,
  });

  @override
  State<DynamicServiceForm> createState() => _DynamicServiceFormState();
}

class _DynamicServiceFormState extends State<DynamicServiceForm> {
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _textControllers = {};

  @override
  void initState() {
    super.initState();
    // Inicializar valores inmediatamente sin llamar onChanged
    _initializeValues();
    // NO llamar onChanged durante initState - solo cuando el usuario cambia valores
  }

  void _initializeValues() {
    // Inicializar con valores por defecto o valores iniciales
    final fields = widget.config.configSchema['fields'] as List<dynamic>?;
    if (fields != null) {
      for (final field in fields) {
        if (field is Map<String, dynamic>) {
          final name = field['name'] as String? ?? '';
          final type = field['type'] as String? ?? 'text';
          
          // Usar valor inicial si existe, sino valor por defecto según tipo
          if (widget.initialValues?.containsKey(name) == true) {
            _values[name] = widget.initialValues![name];
          } else {
            switch (type) {
              case 'boolean':
                _values[name] = false;
                break;
              case 'number':
                _values[name] = null;
                break;
              case 'select':
                _values[name] = null;
                break;
              default:
                _values[name] = '';
                // Crear controller para campos de texto
                _textControllers[name] = TextEditingController();
                if (widget.initialValues?.containsKey(name) == true) {
                  _textControllers[name]!.text = widget.initialValues![name].toString();
                }
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateValue(String name, dynamic value) {
    // Verificar si el valor realmente cambió
    if (_values[name] == value) return;
    
    setState(() {
      _values[name] = value;
    });
    
    // Llamar onChanged solo cuando el usuario realmente cambia un valor
    // Usar Future.microtask para evitar setState durante build
    Future.microtask(() {
      if (mounted) {
        widget.onChanged(Map<String, dynamic>.from(_values));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fields = widget.config.configSchema['fields'] as List<dynamic>?;
    if (fields == null || fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información adicional del servicio',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.grayDark,
            ),
          ),
          const SizedBox(height: 16),
          ...fields.map((field) => _buildField(field as Map<String, dynamic>)),
        ],
      ),
    );
  }

  Widget _buildField(Map<String, dynamic> field) {
    final name = field['name'] as String? ?? '';
    final type = field['type'] as String? ?? 'text';
    final label = field['label'] as String? ?? name;
    final required = field['required'] as bool? ?? false;

    switch (type) {
      case 'text':
        return _buildTextField(name, label, required);
      case 'select':
        final options = field['options'] as List<dynamic>? ?? [];
        return _buildSelectField(name, label, required, options);
      case 'number':
        return _buildNumberField(name, label, required);
      case 'boolean':
        return _buildBooleanField(name, label);
      default:
        return _buildTextField(name, label, required);
    }
  }

  Widget _buildTextField(String name, String label, bool required) {
    if (!_textControllers.containsKey(name)) {
      _textControllers[name] = TextEditingController(
        text: _values[name]?.toString() ?? '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _textControllers[name],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColors.grayLight,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              }
            : null,
        onChanged: (value) => _updateValue(name, value),
      ),
    );
  }

  Widget _buildSelectField(
    String name,
    String label,
    bool required,
    List<dynamic> options,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: _values[name]?.toString(),
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColors.grayLight,
        ),
        items: options.map((option) {
          final optionStr = option.toString();
          return DropdownMenuItem<String>(
            value: optionStr,
            child: Text(optionStr),
          );
        }).toList(),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor selecciona una opción';
                }
                return null;
              }
            : null,
        onChanged: (value) => _updateValue(name, value),
      ),
    );
  }

  Widget _buildNumberField(String name, String label, bool required) {
    if (!_textControllers.containsKey(name)) {
      _textControllers[name] = TextEditingController(
        text: _values[name]?.toString() ?? '',
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _textControllers[name],
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: AppColors.grayLight,
        ),
        keyboardType: TextInputType.number,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                if (int.tryParse(value) == null) {
                  return 'Por favor ingresa un número válido';
                }
                return null;
              }
            : (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingresa un número válido';
                  }
                }
                return null;
              },
        onChanged: (value) {
          final numValue = int.tryParse(value);
          _updateValue(name, numValue);
        },
      ),
    );
  }

  Widget _buildBooleanField(String name, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Switch(
            value: _values[name] as bool? ?? false,
            onChanged: (value) => _updateValue(name, value),
            activeThumbColor: AppColors.primaryLight,
          ),
        ],
      ),
    );
  }
}

