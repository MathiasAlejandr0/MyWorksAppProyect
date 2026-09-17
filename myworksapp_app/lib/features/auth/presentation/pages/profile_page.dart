import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/models/job_model.dart';
import '../../../../core/database/models/user_model.dart';
import '../../../../core/database/models/worker_model.dart';
import '../../../../core/design_system/app_breakpoints.dart';
import '../../../../core/design_system/layout_utils.dart';
import '../../../../core/domain/user_role.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/profile_photo_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/profile_avatar_picker.dart';
import '../providers/auth_provider.dart';
import '../widgets/sign_out_button.dart';
import '../widgets/user_role_ui.dart';

/// Perfil adaptativo: datos personales para [UserRole.cliente] y
/// especialidad/servicios para [UserRole.especialista].
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _photoLoading = false;
  WorkerModel? _worker;
  List<JobModel> _jobs = const [];
  bool _loadingExtras = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExtras());
  }

  Future<void> _loadExtras() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      setState(() => _loadingExtras = false);
      return;
    }

    setState(() => _loadingExtras = true);
    try {
      if (user.userRole.isEspecialista) {
        final worker = await ref
            .read(workerRepositoryProvider)
            .getWorkerByUserId(user.id);
        final jobs =
            await ref.read(jobRepositoryProvider).getJobsByWorkerId(user.id);
        if (!mounted) return;
        setState(() {
          _worker = worker;
          _jobs = jobs;
          _loadingExtras = false;
        });
      } else {
        final jobs =
            await ref.read(jobRepositoryProvider).getJobsByUserId(user.id);
        if (!mounted) return;
        setState(() {
          _jobs = jobs;
          _loadingExtras = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingExtras = false);
    }
  }

  Future<void> _updateProfilePhoto(ImageSource source) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _photoLoading = true);
    try {
      final path = await ProfilePhotoService.instance.pickAndSave(
        userId: user.id,
        source: source,
        currentPath: user.profilePhotoPath,
      );
      if (path == null || !mounted) return;

      await ref.read(userRepositoryProvider).updateUser(
            user.copyWith(profilePhotoPath: path),
          );
      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la foto: $e')),
      );
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  Future<void> _removeProfilePhoto() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _photoLoading = true);
    try {
      await ProfilePhotoService.instance.removePhoto(user.profilePhotoPath);
      await ref.read(userRepositoryProvider).updateUser(
            user.copyWith(clearProfilePhoto: true),
          );
      await ref.read(authProvider.notifier).loadCurrentUser(user.id, silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil eliminada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _photoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider.select((s) => s.user));

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay una sesión activa')),
      );
    }

    final isWide = AppBreakpoints.isLargeScreen(context);
    final roleSection = user.userRole.isEspecialista
        ? _EspecialistaSection(
            worker: _worker,
            jobs: _jobs,
            loading: _loadingExtras,
          )
        : _ClienteSection(
            user: user,
            jobs: _jobs,
            loading: _loadingExtras,
          );

    return Scaffold(
      appBar: const AppGradientAppBar(title: Text('Mi perfil')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(authProvider.notifier)
              .loadCurrentUser(user.id, silent: true);
          await _loadExtras();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: LayoutUtils.scrollPadding(context),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _ProfileIdentityCard(
                        user: user,
                        photoLoading: _photoLoading,
                        onPickFromSource: _updateProfilePhoto,
                        onRemove: _removeProfilePhoto,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: roleSection),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileIdentityCard(
                      user: user,
                      photoLoading: _photoLoading,
                      onPickFromSource: _updateProfilePhoto,
                      onRemove: _removeProfilePhoto,
                    ),
                    const SizedBox(height: 20),
                    roleSection,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.user,
    required this.photoLoading,
    required this.onPickFromSource,
    required this.onRemove,
  });

  final UserModel user;
  final bool photoLoading;
  final Future<void> Function(ImageSource source) onPickFromSource;
  final Future<void> Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final role = user.userRole;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            ProfileAvatarPicker(
              displayName: user.name,
              photoPath: user.profilePhotoPath,
              isLoading: photoLoading,
              onPickFromSource: onPickFromSource,
              onRemove: onRemove,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onCanvasMuted(Theme.of(context).brightness),
                  ),
            ),
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(role.icon, size: 18, color: AppColors.brandOrange),
              label: Text(role.label),
              side: BorderSide(color: AppColors.brandOrange.withValues(alpha: 0.4)),
              backgroundColor: AppColors.brandOrange.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: double.infinity,
              child: SignOutButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClienteSection extends StatelessWidget {
  const _ClienteSection({
    required this.user,
    required this.jobs,
    required this.loading,
  });

  final UserModel user;
  final List<JobModel> jobs;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final completed =
        jobs.where((j) => j.status == AppConstants.jobStatusCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Datos personales',
          child: Column(
            children: [
              _InfoRow(icon: Icons.person_outline, label: 'Nombre', value: user.name),
              const Divider(height: 20),
              _InfoRow(icon: Icons.mail_outline, label: 'Correo', value: user.email),
              const Divider(height: 20),
              _InfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Estado de cuenta',
                value: user.accountStatus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Historial de servicios',
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.handyman_outlined,
                            label: 'Solicitudes',
                            value: '${jobs.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.check_circle_outline,
                            label: 'Completados',
                            value: '$completed',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_rounded),
                      title: const Text('Ver historial completo'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppConstants.routeJobHistory),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: const Text('Editar datos personales'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppConstants.routeUserProfileEdit),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Configuración'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppConstants.routeSettings),
        ),
      ],
    );
  }
}

class _EspecialistaSection extends StatelessWidget {
  const _EspecialistaSection({
    required this.worker,
    required this.jobs,
    required this.loading,
  });

  final WorkerModel? worker;
  final List<JobModel> jobs;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final completed =
        jobs.where((j) => j.status == AppConstants.jobStatusCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Servicios y especialidad',
          child: loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : worker == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aún no completas tu perfil profesional.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () =>
                              context.go(AppConstants.routeWorkerRegister),
                          child: const Text('Completar perfil de especialista'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoRow(
                          icon: Icons.engineering_outlined,
                          label: 'Especialidad',
                          value: worker!.profession,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Categoría',
                          value: worker!.serviceCategory,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.place_outlined,
                          label: 'Zona de trabajo',
                          value: worker!.workZone ?? 'Sin definir',
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.toggle_on_outlined,
                          label: 'Disponibilidad',
                          value: worker!.isAvailable
                              ? 'Disponible'
                              : 'No disponible',
                        ),
                        if (worker!.description != null &&
                            worker!.description!.isNotEmpty) ...[
                          const Divider(height: 20),
                          Text(
                            worker!.description!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (worker!.customServices.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: worker!.customServices
                                .map(
                                  (s) => Chip(
                                    label: Text(s.title),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Actividad',
          child: Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.work_outline,
                  label: 'Trabajos',
                  value: '${jobs.length}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.star_outline,
                  label: 'Calificación',
                  value: worker == null
                      ? '—'
                      : worker!.rating.toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.check_circle_outline,
                  label: 'Completados',
                  value: '$completed',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: const Text('Portafolio, tarifas y zona'),
          subtitle: const Text('Edita tu perfil profesional completo'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppConstants.routeWorkerProfileManage),
        ),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Configuración'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppConstants.routeSettings),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.brandOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
