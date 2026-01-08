import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Página de Política de Privacidad
/// 
/// Cumple con GDPR - Artículo 13 (Información a proporcionar)
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidad',
              style: AppTextStyles.displaySmall(),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().toString().split(' ')[0]}',
              style: AppTextStyles.bodySmall(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Información que Recopilamos',
              '''
Recopilamos la siguiente información personal:
• Nombre y dirección de correo electrónico
• Información de perfil (rol: usuario o trabajador)
• Ubicación (cuando solicitas un servicio)
• Mensajes y comunicaciones dentro de la app
• Calificaciones y comentarios
• Fotos relacionadas con trabajos (opcional)
              ''',
            ),
            _buildSection(
              '2. Cómo Usamos tu Información',
              '''
Utilizamos tu información para:
• Proporcionar y mejorar nuestros servicios
• Conectarte con trabajadores o usuarios según tu rol
• Gestionar trabajos y comunicaciones
• Enviar notificaciones relevantes
• Mejorar la seguridad y prevenir fraudes
              ''',
            ),
            _buildSection(
              '3. Compartir Información',
              '''
No vendemos tu información personal. Compartimos información solo:
• Con otros usuarios de la app cuando es necesario para el servicio
• Con proveedores de servicios que nos ayudan a operar (bajo estrictos acuerdos de confidencialidad)
• Cuando es requerido por ley
              ''',
            ),
            _buildSection(
              '4. Tus Derechos (GDPR)',
              '''
Tienes derecho a:
• Acceder a tus datos personales
• Rectificar datos incorrectos
• Solicitar la eliminación de tus datos
• Oponerte al procesamiento
• Portabilidad de datos
• Retirar consentimiento en cualquier momento
              ''',
            ),
            _buildSection(
              '5. Seguridad',
              '''
Protegemos tu información mediante:
• Encriptación de base de datos local
• Hash seguro de contraseñas (bcrypt)
• Almacenamiento seguro de claves
• Acceso restringido a datos personales
              ''',
            ),
            _buildSection(
              '6. Retención de Datos',
              '''
Conservamos tus datos mientras:
• Tu cuenta esté activa
• Sea necesario para proporcionar servicios
• Sea requerido por obligaciones legales

Puedes solicitar la eliminación en cualquier momento.
              ''',
            ),
            _buildSection(
              '7. Contacto',
              '''
Para ejercer tus derechos o hacer preguntas sobre privacidad:
• Email: privacidad@myworksapp.com
• Desde la app: Configuración > Privacidad
              ''',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Entendido'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge(),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: AppTextStyles.bodyMedium(),
          ),
        ],
      ),
    );
  }
}

