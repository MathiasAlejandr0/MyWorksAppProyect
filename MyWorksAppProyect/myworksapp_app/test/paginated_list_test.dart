// PaginatedList (sin uso en lib/). Documenta el bug B9: _loadInitialData marca
// _isLoading = true y luego _loadPage(0) retorna de inmediato por esa misma
// bandera, así que loadData nunca se llama y la lista queda cargando.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/paginated_list.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('B9: nunca llama a loadData y queda en el indicador', (t) async {
    var llamadas = 0;
    await t.pumpWidget(_app(PaginatedList<int>(
      loadData: (page, size) async {
        llamadas++;
        return [1, 2, 3];
      },
      itemBuilder: (_, item, __) => Text('Elemento $item'),
    )));
    await t.pump(const Duration(milliseconds: 500));
    expect(llamadas, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Elemento 1'), findsNothing);
  });

  testWidgets('scroll y refresco tampoco cargan (controlador externo)',
      (t) async {
    var llamadas = 0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await t.pumpWidget(_app(PaginatedList<String>(
      scrollController: controller,
      padding: const EdgeInsets.all(8),
      loadData: (page, size) async {
        llamadas++;
        return ['a'];
      },
      itemBuilder: (_, item, __) => Text('Fila $item'),
      loadingWidget: const SizedBox(height: 3000, child: Text('Cargando más')),
    )));
    await t.pump();
    expect(find.text('Cargando más'), findsOneWidget);
    await t.drag(find.byType(ListView), const Offset(0, -2900));
    await t.pump(const Duration(milliseconds: 300));
    controller.jumpTo(0);
    await t.pump();
    await t.drag(find.byType(ListView), const Offset(0, 400));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(llamadas, 0);
    await t.pumpWidget(_app(const SizedBox()));
  });
}
