import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../database/worker_database_helper.dart';
import '../models/portfolio_item.dart';
import '../utils/app_colors.dart';

class WorkerPortfolioPage extends StatefulWidget {
  final int workerId;
  const WorkerPortfolioPage({super.key, required this.workerId});

  @override
  State<WorkerPortfolioPage> createState() => _WorkerPortfolioPageState();
}

class _WorkerPortfolioPageState extends State<WorkerPortfolioPage> {
  final _dbHelper = WorkerDatabaseHelper();
  List<PortfolioItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final items = await _dbHelper.getPortfolioByWorker(widget.workerId);
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _addPortfolioItem() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final description = await _showDescriptionDialog();
      if (description != null) {
        final item = PortfolioItem(
          workerId: widget.workerId,
          imagePath: picked.path,
          description: description,
          createdAt: DateTime.now(),
        );
        await _dbHelper.insertPortfolioItem(item);
        _loadPortfolio();
      }
    }
  }

  Future<String?> _showDescriptionDialog() async {
    String desc = '';
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descripción del trabajo'),
        content: TextField(
          onChanged: (value) => desc = value,
          decoration:
              const InputDecoration(hintText: 'Describe el trabajo realizado'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(desc),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePortfolioItem(int id) async {
    await _dbHelper.deletePortfolioItem(id);
    _loadPortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Portafolio'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No tienes trabajos en tu portafolio.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        leading: Image.file(File(item.imagePath),
                            width: 60, height: 60, fit: BoxFit.cover),
                        title: Text(item.description ?? ''),
                        subtitle: Text(
                            'Subido: ${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deletePortfolioItem(item.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPortfolioItem,
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
