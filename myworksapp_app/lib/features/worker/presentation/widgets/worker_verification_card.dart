import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/repositories/worker_repository.dart';
import '../../../../core/database/supabase_db.dart';
import '../../../../core/theme/app_colors.dart';

/// Pide revisión de identidad. El profesional no puede autoaprobarse:
/// la base rechaza `verificado` si no es administrador.
class WorkerVerificationCard extends StatefulWidget {
  const WorkerVerificationCard({super.key, required this.userId});

  final String userId;

  @override
  State<WorkerVerificationCard> createState() => _WorkerVerificationCardState();
}

class _WorkerVerificationCardState extends State<WorkerVerificationCard> {
  final WorkerRepository _workers = WorkerRepository();
  final TextEditingController _note = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _status = 'pendiente';
  bool _loading = true;
  bool _saving = false;
  Uint8List? _preview;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final current = await _workers.fetchVerification(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (current != null) {
        _status = current.status;
        _note.text = current.note ?? '';
      }
    });
  }

  String get _label {
    switch (_status) {
      case 'en_revision':
        return 'En revisión';
      case 'verificado':
        return 'Verificado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return 'Pendiente';
    }
  }

  Future<void> _pickDocument() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _preview = bytes);
  }

  Future<void> _submit() async {
    final note = _note.text.trim();
    if (note.length < 8 && _preview == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe tu RUT y oficio, o adjunta una foto del documento.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    var storedNote = note;
    try {
      if (_preview != null) {
        final path = '${widget.userId}/documento.jpg';
        await supabase.storage.from('verificacion-profesional').uploadBinary(
              path,
              _preview!,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );
        storedNote = storedNote.isEmpty ? 'Documento: $path' : '$storedNote\nDocumento: $path';
      }
      await _workers.submitVerificationReview(
        userId: widget.userId,
        note: storedNote,
      );
      if (!mounted) return;
      setState(() => _status = 'en_revision');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enviamos tu solicitud a revisión.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo enviar. Aplica la migración de verificación en Supabase. $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Verificación', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loading)
              const LinearProgressIndicator(minHeight: 3)
            else
              Text('Estado: $_label'),
            const SizedBox(height: 8),
            const Text(
              'Un administrador revisa tu nota y el documento. '
              'Hasta entonces no apareces como verificado.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              enabled: _status != 'verificado',
              decoration: const InputDecoration(
                labelText: 'RUT, oficio y comuna',
                hintText: 'Ej. 12.345.678-9 · gasfiter · Ñuñoa',
              ),
            ),
            const SizedBox(height: 8),
            if (_preview != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_preview!, height: 120, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _status == 'verificado' || _saving ? null : _pickDocument,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Adjuntar documento'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _status == 'verificado' || _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: AppColors.brandOrange),
              child: Text(_saving ? 'Enviando…' : 'Enviar a revisión'),
            ),
          ],
        ),
      ),
    );
  }
}
