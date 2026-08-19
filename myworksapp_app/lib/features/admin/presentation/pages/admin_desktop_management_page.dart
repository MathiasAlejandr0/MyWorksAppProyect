import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/design_system/app_brand_logo.dart';
import '../../../../core/widgets/design_system/status_badge.dart';

/// Software de Gestión de Escritorio (Desktop Admin Management Hub) estilo Apple HIG.
class AdminDesktopManagementPage extends StatefulWidget {
  const AdminDesktopManagementPage({super.key});

  @override
  State<AdminDesktopManagementPage> createState() => _AdminDesktopManagementPageState();
}

class _AdminDesktopManagementPageState extends State<AdminDesktopManagementPage> {
  int _selectedTabIndex = 0;
  final currencyFormatter = NumberFormat.currency(locale: 'es_CL', symbol: '\$', decimalDigits: 0);

  final List<_DisputeTicket> _mockDisputes = [
    _DisputeTicket(
      id: 'TICK-9021',
      clientName: 'Roberto Silva',
      workerName: 'Juan Pérez (Electricista)',
      issue: 'Filtración no resuelta en caja automática principal',
      escrowAmount: 45000,
      date: '16 Ago 2026',
      status: 'En Revisión',
    ),
    _DisputeTicket(
      id: 'TICK-8842',
      clientName: 'Camila Torres',
      workerName: 'Carlos Muñoz (Gásfiter)',
      issue: 'Retraso de más de 3 horas en llegada',
      escrowAmount: 32000,
      date: '15 Ago 2026',
      status: 'Pendiente Reembolso',
    ),
    _DisputeTicket(
      id: 'TICK-7610',
      clientName: 'Andrea Gómez',
      workerName: 'Pedro Alarcón (Constructor)',
      issue: 'Diferencia en cotización de materiales de pintura',
      escrowAmount: 85000,
      date: '14 Ago 2026',
      status: 'Resuelto',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // 1. Sidebar de Navegación Lateral (Estilo Escritorio Apple macOS)
          Container(
            width: 260,
            color: isDark ? const Color(0xFF0F172A) : AppColors.brandNavy,
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      AppBrandLogo(size: 32),
                      SizedBox(width: 10),
                      Text(
                        'MyWorks Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'SOFTWARE ESCRITORIO v2.5',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 32),

                // Ítems de Menú
                _sidebarItem(0, Icons.dashboard_rounded, 'Dashboard & KPIs'),
                _sidebarItem(1, Icons.confirmation_number_rounded, 'Resolución de Tickets', badgeCount: 2),
                _sidebarItem(2, Icons.analytics_rounded, 'Presupuesto y Uso'),
                _sidebarItem(3, Icons.people_alt_rounded, 'Directorio de Usuarios'),
                _sidebarItem(4, Icons.build_circle_rounded, 'Catálogo & Tarifas'),

                const Spacer(),
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                  title: const Text('Volver a la App', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  onTap: () => context.go('/user/home'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 2. Área de Contenido Principal de Gestión
          Expanded(
            child: Column(
              children: [
                // Topbar de Escritorio
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white10 : AppColors.grayBorder.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titleForTab(_selectedTabIndex),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.brandNavy,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.brandOrange,
                        child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                // Cuerpo según pestaña seleccionada
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildTabBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label, {int? badgeCount}) {
    final isSelected = _selectedTabIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.brandOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13.5,
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    color: isSelected ? AppColors.brandNavy : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        onTap: () => setState(() => _selectedTabIndex = index),
      ),
    );
  }

  String _titleForTab(int tab) {
    switch (tab) {
      case 0:
        return 'Dashboard de Gestión & KPIs';
      case 1:
        return 'Centro de Resolución de Problemas y Tickets';
      case 2:
        return 'Métricas de Presupuesto, Crecimiento y Escrow';
      case 3:
        return 'Directorio General de Usuarios y Profesionales';
      case 4:
        return 'Configuración de Catálogo y Tarifas';
      default:
        return 'Gestión MyWorks';
    }
  }

  Widget _buildTabBody() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildKpiOverview();
      case 1:
        return _buildDisputeResolutionCenter();
      case 2:
        return _buildAnalyticsCenter();
      default:
        return _buildKpiOverview();
    }
  }

  Widget _buildKpiOverview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjetas KPI Principales
        Row(
          children: [
            _kpiCard('GMV Transaccionado Escrow', currencyFormatter.format(14850000), '+24.5% este mes', Icons.account_balance_wallet_rounded, AppColors.emerald),
            const SizedBox(width: 16),
            _kpiCard('Trabajos Activos en Curso', '48 solicitudes', '12 en espera de PIN', Icons.engineering_rounded, AppColors.brandOrange),
            const SizedBox(width: 16),
            _kpiCard('Usuarios Registrados', '3,420 usuarios', '+180 esta semana', Icons.people_alt_rounded, AppColors.info),
            const SizedBox(width: 16),
            _kpiCard('Tickets / Reclamos Abiertos', '2 en revisión', 'Atención inmediata', Icons.warning_amber_rounded, AppColors.crimson),
          ],
        ),
        const SizedBox(height: 28),

        // Lista Rápida de Tickets de Disputa Pendientes
        Text(
          'Problemas Recientes en la App Requeridos de Atención',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.brandNavy,
          ),
        ),
        const SizedBox(height: 12),
        _buildDisputesTable(),
      ],
    );
  }

  Widget _kpiCard(String title, String mainVal, String subVal, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(subVal, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.grayMedium)),
            const SizedBox(height: 4),
            Text(mainVal, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.brandNavy)),
          ],
        ),
      ),
    );
  }

  Widget _buildDisputeResolutionCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Centro de Resolución de Disputas y Tickets de la App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Gestiona problemas reportados por clientes o trabajadores para la liberación de pagos o reembolsos.', style: TextStyle(color: AppColors.grayMedium, fontSize: 13)),
        const SizedBox(height: 20),
        _buildDisputesTable(),
      ],
    );
  }

  Widget _buildAnalyticsCenter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Métricas de Presupuesto, Crecimiento y Comisiones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandNavy,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.brandOrange),
                SizedBox(height: 12),
                Text('Volumen Transaccionado Escrow Mensual', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('\$14.850.000 CLP procesados en los últimos 30 días (+24.5%)', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisputesTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.grayBorder.withValues(alpha: 0.5)),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(2.5),
          3: FlexColumnWidth(1.2),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkElevated : AppColors.grayBackground,
            ),
            children: const [
              Padding(padding: EdgeInsets.all(12.0), child: Text('ID Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(12.0), child: Text('Cliente / Profesional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(12.0), child: Text('Problema Reportado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(12.0), child: Text('Escrow CLP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(12.0), child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              Padding(padding: EdgeInsets.all(12.0), child: Text('Acción Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            ],
          ),
          ..._mockDisputes.map((t) {
            return TableRow(
              children: [
                Padding(padding: const EdgeInsets.all(12.0), child: Text(t.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.clientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(t.workerName, style: const TextStyle(fontSize: 11, color: AppColors.grayMedium)),
                    ],
                  ),
                ),
                Padding(padding: const EdgeInsets.all(12.0), child: Text(t.issue, style: const TextStyle(fontSize: 12))),
                Padding(padding: const EdgeInsets.all(12.0), child: Text(currencyFormatter.format(t.escrowAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.emerald))),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: StatusBadge(
                    status: t.status == 'Resuelto'
                        ? 'completed'
                        : t.status == 'En Revisión'
                            ? 'in_progress'
                            : 'pending',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => _resolveTicketModal(t),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('Resolver', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _resolveTicketModal(_DisputeTicket ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Resolver Ticket ${ticket.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${ticket.clientName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Trabajador: ${ticket.workerName}'),
            const SizedBox(height: 8),
            Text('Monto retenido en Escrow: ${currencyFormatter.format(ticket.escrowAmount)}', style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Problema: ${ticket.issue}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reembolso total procesado al cliente.')));
            },
            child: const Text('Reembolsar Cliente', style: TextStyle(color: AppColors.crimson)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fondos liberados al trabajador.')));
            },
            child: const Text('Liberar Pago a Profesional'),
          ),
        ],
      ),
    );
  }
}

class _DisputeTicket {
  final String id;
  final String clientName;
  final String workerName;
  final String issue;
  final int escrowAmount;
  final String date;
  final String status;

  _DisputeTicket({
    required this.id,
    required this.clientName,
    required this.workerName,
    required this.issue,
    required this.escrowAmount,
    required this.date,
    required this.status,
  });
}
