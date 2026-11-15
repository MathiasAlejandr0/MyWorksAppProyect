import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/models/rating_model.dart';
import '../../../../core/database/repositories/rating_repository.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/design_system/app_gradient_app_bar.dart';
import '../../../../core/widgets/design_system/empty_state_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MyRatingsPage extends ConsumerStatefulWidget {
  const MyRatingsPage({super.key});

  @override
  ConsumerState<MyRatingsPage> createState() => _MyRatingsPageState();
}

class _MyRatingsPageState extends ConsumerState<MyRatingsPage> {
  final _repo = RatingRepository();
  List<RatingModel> _received = [];
  List<RatingModel> _given = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final received = await _repo.listReceived(user.id);
      final given = await _repo.getRatingsByUserId(user.id);
      if (!mounted) return;
      setState(() {
        _received = received;
        _given = given;
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppGradientAppBar(
          title: const Text('Mis calificaciones'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recibidas'),
              Tab(text: 'Entregadas'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'No se pudieron cargar',
                    message: _error!,
                    actionLabel: 'Reintentar',
                    onAction: _load,
                  )
                : TabBarView(
                    children: [
                      _RatingList(
                          items: _received,
                          empty: 'Todavía no recibes calificaciones.'),
                      _RatingList(
                          items: _given, empty: 'Todavía no has calificado.'),
                    ],
                  ),
      ),
    );
  }
}

class _RatingList extends StatelessWidget {
  const _RatingList({required this.items, required this.empty});

  final List<RatingModel> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.star_outline,
        title: 'Sin calificaciones',
        message: empty,
      );
    }
    final date = DateFormat('d MMM y', 'es_CL');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final rating = items[index];
        final who = rating.direction == 'trabajador_a_cliente'
            ? 'Profesional → cliente'
            : 'Cliente → profesional';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${rating.score} / 5 · $who'),
          subtitle: Text(
            [
              if (rating.comment != null && rating.comment!.trim().isNotEmpty)
                rating.comment!.trim(),
              date.format(rating.createdAt.toLocal()),
            ].join('\n'),
          ),
          isThreeLine:
              rating.comment != null && rating.comment!.trim().isNotEmpty,
        );
      },
    );
  }
}
