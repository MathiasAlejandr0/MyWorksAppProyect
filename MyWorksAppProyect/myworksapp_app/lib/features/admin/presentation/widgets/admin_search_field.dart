import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_spacing.dart';

class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onSearch,
    this.debounceMs = 350,
  });

  final String hint;
  final ValueChanged<String> onSearch;
  final int debounceMs;

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: widget.debounceMs), () {
      widget.onSearch(value.trim());
    });
  }

  void _clear() {
    _controller.clear();
    setState(() {});
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          isDense: true,
        ),
      ),
    );
  }
}
