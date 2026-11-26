// PaginatedList (sin uso en lib/). Regresión del bug B9: antes la carga
// inicial marcaba _isLoading y _loadPage(0) retornaba sin llamar a loadData.
// Ahora carga la primera página, pagina al hacer scroll y refresca.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myworksapp/core/widgets/paginated_list.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('B9: la carga inicial llama a loadData y muestra la página',
      (t) async {
    final paginas = <int>[];
    await t.pumpWidget(_app(PaginatedList<int>(
      pageSize: 3,
      loadData: (page, size) async {
        paginas.add(page);
        expect(size, 3);
        return [1, 2, 3];
      },
      itemBuilder: (_, item, __) => Text('Elemento $item'),
    )));
    await t.pump();
    expect(paginas, [0]);
    expect(find.text('Elemento 1'), findsOneWidget);
    expect(find.text('Elemento 3'), findsOneWidget);
    // Página completa: queda la fila de "cargando más".
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('scroll pide la página siguiente y refrescar recarga',
      (t) async {
    final paginas = <int>[];
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await t.pumpWidget(_app(PaginatedList<String>(
      scrollController: controller,
      pageSize: 20,
      padding: const EdgeInsets.all(8),
      loadData: (page, size) async {
        paginas.add(page);
        if (page == 0) return List.generate(size, (i) => 'p0-$i');
        return ['ultima'];
      },
      itemBuilder: (_, item, __) =>
          SizedBox(height: 80, child: Text('Fila $item')),
    )));
    await t.pump();
    expect(paginas, [0]);
    controller.jumpTo(controller.position.maxScrollExtent);
    await t.pump();
    await t.pump();
    expect(paginas, [0, 1]);
    controller.jumpTo(controller.position.maxScrollExtent);
    await t.pump();
    expect(find.text('Fila ultima'), findsOneWidget);
    // Última página incompleta: ya no pide más.
    controller.jumpTo(controller.position.maxScrollExtent);
    await t.pump();
    expect(paginas, [0, 1]);
    controller.jumpTo(0);
    await t.pump();
    await t.fling(find.byType(ListView), const Offset(0, 600), 1000);
    await t.pumpAndSettle();
    expect(paginas, [0, 1, 0]);
    expect(find.text('Fila p0-0'), findsOneWidget);
    await t.pumpWidget(_app(const SizedBox()));
  });

  testWidgets('lista vacía y error con reintento', (t) async {
    var falla = true;
    await t.pumpWidget(_app(PaginatedList<int>(
      loadData: (page, size) async {
        if (falla) throw Exception('sin red');
        return [];
      },
      itemBuilder: (_, item, __) => Text('Elemento $item'),
    )));
    await t.pump();
    expect(find.text('Reintentar'), findsOneWidget);
    falla = false;
    await t.tap(find.text('Reintentar'));
    await t.pump();
    expect(find.text('No hay elementos para mostrar'), findsOneWidget);
  });
}
