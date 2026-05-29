import 'package:flutter/material.dart';
import 'package:myworksapp/core/widgets/design_system/app_gradient_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';

/// Página de centro de ayuda
/// 
/// Incluye:
/// - FAQ por rol (usuario / trabajador)
/// - Contacto de soporte
class HelpCenterPage extends StatefulWidget {
  final String? userRole;

  const HelpCenterPage({super.key, this.userRole});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.userRole ?? AppConstants.roleUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppGradientAppBar(
        title: const Text('Centro de Ayuda'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de rol
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Soy:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Usuario'),
                            selected: _selectedRole == AppConstants.roleUser,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = AppConstants.roleUser);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Trabajador'),
                            selected: _selectedRole == AppConstants.roleWorker,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = AppConstants.roleWorker);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQ
            Text(
              'Preguntas Frecuentes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...(_selectedRole == AppConstants.roleUser
                ? _buildUserFAQ()
                : _buildWorkerFAQ()),
            
            const SizedBox(height: 32),
            
            // Contacto de soporte
            Text(
              'Contacto de Soporte',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email, color: AppColors.primaryLight),
                    title: const Text('Email'),
                    subtitle: const Text('soporte@myworksapp.com'),
                    onTap: () => _launchEmail(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chat, color: AppColors.primaryLight),
                    title: const Text('WhatsApp'),
                    subtitle: const Text('+56 9 1234 5678'),
                    onTap: () => _launchWhatsApp(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildUserFAQ() {
    return [
      _buildFAQItem(
        question: '¿Cómo creo un trabajo?',
        answer: 'Selecciona un servicio desde la pantalla principal, completa los detalles '
            'y envía la solicitud. Los trabajadores disponibles recibirán una notificación.',
      ),
      _buildFAQItem(
        question: '¿Cómo elijo un trabajador?',
        answer: 'Puedes elegir automáticamente el mejor trabajador disponible o seleccionar '
            'uno manualmente desde la lista de trabajadores disponibles.',
      ),
      _buildFAQItem(
        question: '¿Cómo pago por el servicio?',
        answer: 'El pago se autoriza cuando aceptas el trabajo y se libera cuando el trabajador '
            'completa el servicio satisfactoriamente.',
      ),
      _buildFAQItem(
        question: '¿Puedo cancelar un trabajo?',
        answer: 'Sí, puedes cancelar un trabajo antes de que sea aceptado. Si ya fue aceptado, '
            'puede haber políticas de cancelación según el servicio.',
      ),
      _buildFAQItem(
        question: '¿Cómo califico a un trabajador?',
        answer: 'Después de que un trabajo se completa, recibirás una notificación para calificar '
            'al trabajador. Puedes dejar una calificación de 1 a 5 estrellas y un comentario opcional.',
      ),
    ];
  }

  List<Widget> _buildWorkerFAQ() {
    return [
      _buildFAQItem(
        question: '¿Cómo completo mi perfil?',
        answer: 'Ve a tu perfil y completa: descripción profesional (mín. 150 caracteres), '
            'al menos una foto en tu portafolio, y selecciona tu servicio principal. '
            'Solo los trabajadores con perfil completo reciben trabajos.',
      ),
      _buildFAQItem(
        question: '¿Cómo recibo trabajos?',
        answer: 'Una vez que tu perfil esté completo, recibirás notificaciones automáticas '
            'cuando haya trabajos disponibles en tu área y servicio.',
      ),
      _buildFAQItem(
        question: '¿Cómo acepto un trabajo?',
        answer: 'Revisa los detalles del trabajo en la notificación o en la lista de trabajos '
            'pendientes. Si estás disponible, puedes aceptarlo directamente.',
      ),
      _buildFAQItem(
        question: '¿Cuándo recibo el pago?',
        answer: 'El pago se autoriza cuando el usuario acepta tu oferta y se libera cuando '
            'completas el trabajo y el usuario lo confirma.',
      ),
      _buildFAQItem(
        question: '¿Qué pasa si no puedo completar un trabajo?',
        answer: 'Si no puedes completar un trabajo aceptado, puedes cancelarlo. Sin embargo, '
            'las cancelaciones frecuentes pueden afectar tu calificación.',
      ),
    ];
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(color: AppColors.grayDark),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final email = 'soporte@myworksapp.com';
    final subject = 'Soporte My Works App';
    final uri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el cliente de email')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = '56912345678'; // Sin + ni espacios
    final message = 'Hola, necesito ayuda con My Works App';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }
}

