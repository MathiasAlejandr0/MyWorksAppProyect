import 'package:flutter/material.dart';

/// Widget para listas paginadas
/// 
/// Maneja:
/// - Carga inicial
/// - Carga de más elementos al hacer scroll
/// - Estados de loading y error
/// - Empty state
class PaginatedList<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int pageSize) loadData;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final int pageSize;
  final ScrollController? scrollController;
  final EdgeInsets? padding;

  const PaginatedList({
    super.key,
    required this.loadData,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.pageSize = 20,
    this.scrollController,
    this.padding,
  });

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  final List<T> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
    });

    await _loadPage(0);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newItems = await widget.loadData(page, widget.pageSize);

      setState(() {
        if (page == 0) {
          _items.clear();
        }
        _items.addAll(newItems);
        _hasMore = newItems.length >= widget.pageSize;
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadPage(_currentPage + 1);
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
    }

    if (!_isLoading && _items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('No hay elementos para mostrar'),
          );
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return widget.loadingWidget ??
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
          }

          return widget.itemBuilder(context, _items[index], index);
        },
      ),
    );
  }
}

