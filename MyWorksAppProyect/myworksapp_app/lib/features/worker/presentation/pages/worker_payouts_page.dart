import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/repositories/payout_repository.dart';
import '../../../../core/domain/payout_summary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class WorkerPayoutsPage extends ConsumerStatefulWidget {
  const WorkerPayoutsPage({super.key});

  @override
  ConsumerState<WorkerPayoutsPage> createState() => _WorkerPayoutsPageState();
}

class _WorkerPayoutsPageState extends ConsumerState<WorkerPayoutsPage> {
  final _repo = PayoutRepository();
  final _bank = TextEditingController();
  final _number = TextEditingController();
  final _rut = TextEditingController();
  final _name = TextEditingController();
  String _type = 'vista';
  PayoutSummary? _summary;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bank.dispose();
    _number.dispose();
    _rut.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final account = await _repo.loadAccount(user.id);
      final summary = await _repo.summaryForWorker(user.id);
      if (!mounted) return;
      if (account != null) {
        _bank.text = account.bank;
        _type = account.accountType;
        _number.text = account.accountNumber;
        _rut.text = account.holderRut;
        _name.text = account.holderName;
      }
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorHandler.getErrorMessage(e);
      });
    }
  }

  Future<void> _save() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final problem = validateBankAccount(
      bank: _bank.text,
      accountType: _type,
      accountNumber: _number.text,
      holderRut: _rut.text,
      holderName: _name.text,
    );
    if (problem != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    setState(() => _saving = true);
    try {
      await _repo.saveAccount(
        userId: user.id,
        account: BankAccount(
          bank: _bank.text,
          accountType: _type,
          accountNumber: _number.text,
          holderRut: _rut.text,
          holderName: _name.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Cuenta guardada. Solo tú y un administrador la ven.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final money =
        NumberFormat.currency(locale: 'es_CL', symbol: r'$', decimalDigits: 0);
    final summary = _summary;
    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Pagos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: AppColors.error)),
                Text(
                  'Por pagar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  money.format(summary?.pendingClp ?? 0),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Es el dinero de trabajos retenido o liberado que todavía no tiene una transferencia marcada.',
                ),
                const SizedBox(height: 20),
                Text('Cuenta para la transferencia',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: _bank,
                  decoration: const InputDecoration(labelText: 'Banco'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de cuenta'),
                  items: const [
                    DropdownMenuItem(
                        value: 'vista', child: Text('Cuenta vista')),
                    DropdownMenuItem(
                        value: 'corriente', child: Text('Cuenta corriente')),
                    DropdownMenuItem(value: 'rut', child: Text('Cuenta RUT')),
                    DropdownMenuItem(
                        value: 'ahorro', child: Text('Cuenta de ahorro')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _type = value);
                  },
                ),
                TextField(
                  controller: _number,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número de cuenta',
                    helperText: _number.text.isEmpty
                        ? null
                        : 'Se muestra como ${maskAccountNumber(_number.text)}',
                  ),
                ),
                TextField(
                  controller: _rut,
                  decoration:
                      const InputDecoration(labelText: 'RUT del titular'),
                ),
                TextField(
                  controller: _name,
                  decoration:
                      const InputDecoration(labelText: 'Nombre del titular'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando…' : 'Guardar cuenta'),
                ),
                const SizedBox(height: 24),
                Text('Liquidaciones',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (summary == null || summary.history.isEmpty)
                  const Text('Aún no hay transferencias registradas.')
                else
                  for (final row in summary.history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(money.format(row.amountClp)),
                      subtitle: Text(
                        _statusLabel(row.transferStatus) +
                            (row.transferReference == null
                                ? ''
                                : ' · ref. ${row.transferReference}'),
                      ),
                    ),
              ],
            ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'transferido':
        return 'Transferido';
      case 'fallido':
        return 'Fallido';
      case 'pendiente':
        return 'Pendiente de transferencia';
      default:
        return 'Sin estado';
    }
  }
}
