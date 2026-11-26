import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/payout_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/utils/clp_format.dart';
import '../../../../core/widgets/dialog_controllers_scope.dart';

class AdminPayoutsPage extends ConsumerStatefulWidget {
  const AdminPayoutsPage({super.key});

  @override
  ConsumerState<AdminPayoutsPage> createState() => _AdminPayoutsPageState();
}

class _AdminPayoutsPageState extends ConsumerState<AdminPayoutsPage> {
  final _repo = PayoutRepository();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await _repo.pendingForAdmin();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    }
  }

  Future<void> _mark(Map<String, dynamic> row) async {
    final reference = TextEditingController();
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DialogControllersScope(
        controllers: [reference, notes],
        child: AlertDialog(
          title: const Text('Marcar transferencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pago ${row['id']}\n'
                'Transferir \$${row['neto_clp'] ?? row['monto']} '
                '(bruto \$${row['monto']} − comisión \$${row['comision_clp'] ?? 0})',
              ),
              TextField(
                controller: reference,
                decoration: const InputDecoration(
                  labelText: 'Referencia (mín. 4)',
                ),
              ),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Marcar pagado'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await _repo.markPaid(
        paymentId: row['id'] as String,
        reference: reference.text,
        notes: notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transferencia registrada')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const money =
        ClpFormat();
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Liquidaciones'),
        actions: [
          IconButton(
              tooltip: 'Actualizar',
              onPressed: _load,
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const Center(
                  child: Text('No hay pagos pendientes de transferir.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rows.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    final gross = (row['monto'] as num?)?.round() ?? 0;
                    final fee = (row['comision_clp'] as num?)?.round() ?? 0;
                    final net =
                        (row['neto_clp'] as num?)?.round() ?? gross - fee;
                    return Card(
                      child: ListTile(
                        title: Text('Transferir ${money.format(net)}'),
                        subtitle: Text(
                          'Bruto ${money.format(gross)} − comisión ${money.format(fee)}\n'
                          '${row['estado']} · trabajo ${row['id_trabajo']}',
                        ),
                        isThreeLine: true,
                        trailing: FilledButton(
                          onPressed: () => _mark(row),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandOrange,
                            // Acota el ancho mínimo infinito del tema global:
                            // como trailing de ListTile no puede ocupar todo.
                            minimumSize: const Size(0, 40),
                          ),
                          child: const Text('Pagado'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
