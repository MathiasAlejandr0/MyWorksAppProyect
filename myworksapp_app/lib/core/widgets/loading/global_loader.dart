import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el loader global
final globalLoaderProvider = StateNotifierProvider<GlobalLoaderNotifier, bool>((ref) {
  return GlobalLoaderNotifier();
});

class GlobalLoaderNotifier extends StateNotifier<bool> {
  GlobalLoaderNotifier() : super(false);

  void show() => state = true;
  void hide() => state = false;
}

/// Widget de loader global bloqueante
class GlobalLoader extends ConsumerWidget {
  final Widget child;

  const GlobalLoader({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(globalLoaderProvider);

    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}

/// Helper para usar el loader global
class GlobalLoaderHelper {
  static void show(WidgetRef ref) {
    ref.read(globalLoaderProvider.notifier).show();
  }

  static void hide(WidgetRef ref) {
    ref.read(globalLoaderProvider.notifier).hide();
  }

  static Future<T> withLoader<T>(
    WidgetRef ref,
    Future<T> Function() action,
  ) async {
    try {
      show(ref);
      return await action();
    } finally {
      hide(ref);
    }
  }
}

