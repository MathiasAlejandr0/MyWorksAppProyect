import 'package:flutter/material.dart';

import '../../../../core/utils/chile_comunas.dart';

class WorkerWorkZoneField extends StatelessWidget {
  const WorkerWorkZoneField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Zona de trabajo',
        prefixIcon: Icon(Icons.location_on_outlined),
        helperText: 'Comuna principal donde atiendes solicitudes',
      ),
      items: ChileComunas.allZones
          .map(
            (comuna) => DropdownMenuItem(
              value: comuna,
              child: Text(comuna),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Selecciona tu zona de trabajo';
        }
        return null;
      },
    );
  }
}
