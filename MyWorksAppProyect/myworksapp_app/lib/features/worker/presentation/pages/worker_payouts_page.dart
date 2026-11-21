import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/repositories/payout_repository.dart';
import '../../../../core/domain/payout_summary.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/clp_format.dart';

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
        _type = account.accountType.trim().isEmpty
            ? 'vista'
            : account.accountType.trim();
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
    const money =
        ClpFormat();
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
                  'Por recibir (neto)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  money.format(summary?.pendingClp ?? 0),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandOrange,
                      ),
                ),
                if ((summary?.pendingFeeClp ?? 0) > 0)
                  Text(
                    'Bruto ${money.format(summary!.pendingGrossClp)} − comisión ${money.format(summary.pendingFeeClp)}',
                  ),
                const SizedBox(height: 8),
                Text(
                  'Es lo que recibirás por trabajos retenidos o liberados que todavía no tienen una transferencia marcada: lo que pagó el cliente menos la comisión del servicio (5 %, mínimo \$1.000).',
                  style: TextStyle(
                    height: 1.4,
                    color: AppColors.onCanvasMuted(Theme.of(context).brightness),
                  ),
                ),
                const SizedBox(height: 20),
                _BankAccountForm(
                  bank: _bank,
                  number: _number,
                  rut: _rut,
                  name: _name,
                  type: _type,
                  saving: _saving,
                  onTypeChanged: (value) => setState(() => _type = value),
                  onNumberChanged: () => setState(() {}),
                  onSave: _save,
                ),
                const SizedBox(height: 24),
                Text('Liquidaciones',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (summary != null && summary.transferredClp > 0) ...[
                  Text(
                    'Total transferido: ${money.format(summary.transferredClp)} neto',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Bruto ${money.format(summary.transferredGrossClp)} − comisión ${money.format(summary.transferredFeeClp)}',
                  ),
                  const SizedBox(height: 8),
                ],
                if (summary == null || summary.history.isEmpty)
                  const Text('Aún no hay transferencias registradas.')
                else
                  for (final row in summary.history)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      isThreeLine: true,
                      title: Text('Neto ${money.format(row.amountClp)}'),
                      subtitle: Text(
                        'Bruto ${money.format(row.grossClp)} − comisión ${money.format(row.feeClp)}\n'
                        '${_statusLabel(row.transferStatus)}'
                        '${row.transferReference == null ? '' : ' · ref. ${row.transferReference}'}',
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

List<DropdownMenuItem<String>> _accountTypeItems(String type) {
  const known = <String, String>{
    'vista': 'Cuenta vista',
    'corriente': 'Cuenta corriente',
    'rut': 'Cuenta RUT',
    'ahorro': 'Cuenta de ahorro',
  };
  return [
    for (final entry in known.entries)
      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
    if (!known.containsKey(type))
      DropdownMenuItem(value: type, child: Text(type)),
  ];
}

class _BankAccountForm extends StatelessWidget {
  const _BankAccountForm({
    required this.bank,
    required this.number,
    required this.rut,
    required this.name,
    required this.type,
    required this.saving,
    required this.onTypeChanged,
    required this.onNumberChanged,
    required this.onSave,
  });

  final TextEditingController bank;
  final TextEditingController number;
  final TextEditingController rut;
  final TextEditingController name;
  final String type;
  final bool saving;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onNumberChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.onCanvasMuted(Theme.of(context).brightness);
    final masked = number.text.trim().isEmpty
        ? null
        : 'Se muestra como ${maskAccountNumber(number.text)}';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: AppDecorations.surfaceCardOf(
        context,
        accent: AppColors.brandOrange,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Cuenta para la transferencia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Datos del titular. Quedan visibles solo para ti y para un administrador.',
            style: TextStyle(color: muted, height: 1.35, fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: bank,
            textCapitalization: TextCapitalization.words,
            decoration: _field(context, 'Banco', Icons.account_balance_outlined),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: type,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.brandOrange,
            ),
            decoration: _field(
              context,
              'Tipo de cuenta',
              Icons.account_balance_wallet_outlined,
            ),
            items: [
              for (final item in _accountTypeItems(type)) item,
            ],
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: number,
            keyboardType: TextInputType.number,
            onChanged: (_) => onNumberChanged(),
            decoration: _field(context, 'Número de cuenta', Icons.tag_outlined),
          ),
          if (masked != null) ...[
            const SizedBox(height: 6),
            Text(masked, style: TextStyle(color: muted, fontSize: 12)),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: rut,
            textCapitalization: TextCapitalization.characters,
            decoration: _field(context, 'RUT del titular', Icons.badge_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: _field(context, 'Nombre del titular', Icons.person_outline),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: saving ? null : onSave,
            child: Text(saving ? 'Guardando…' : 'Guardar cuenta'),
          ),
        ],
      ),
    );
  }

  InputDecoration _field(BuildContext context, String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);
    final idle = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.14)
          : AppColors.grayBorder,
    );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppColors.brandOrange),
      filled: true,
      fillColor: isDark ? AppColors.surfaceDarkElevated : AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: radius, borderSide: idle),
      enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: idle),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.brandOrange, width: 1.6),
      ),
    );
  }
}
