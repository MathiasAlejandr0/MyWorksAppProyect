import 'package:material_ui/material_ui.dart';

import '../../../../core/database/supabase_db.dart';

class ParecidosIa extends StatefulWidget {
  const ParecidosIa({super.key, required this.workerId});

  final String workerId;

  @override
  State<ParecidosIa> createState() => _ParecidosIaState();
}

class _ParecidosIaState extends State<ParecidosIa> {
  List<String> _filas = const [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final rows = await supabase.rpc('profesionales_parecidos', params: {
        'p_id': widget.workerId,
        'p_limite': 3,
      });
      if (!mounted || rows is! List) return;
      setState(() {
        _filas = [
          for (final row in rows.whereType<Map>())
            '${row['nombre'] ?? 'Profesional'} · ${row['profesion'] ?? ''}',
        ];
      });
    } catch (_) {
      if (mounted) setState(() => _filas = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_filas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trabajadores parecidos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final fila in _filas) Text(fila),
      ],
    );
  }
}
