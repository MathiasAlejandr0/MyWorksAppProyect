import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Página de Términos y Condiciones
/// 
/// Cumple con GDPR - Consentimiento informado
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones',
              style: AppTextStyles.displaySmall(),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión 1.0 - Última actualización: ${DateTime.now().toString().split(' ')[0]}',
              style: AppTextStyles.bodySmall(),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Aceptación de Términos',
              '''
Al usar MyWorksApp, aceptas estos términos y condiciones.
Si no estás de acuerdo, no uses la aplicación.
              ''',
            ),
            _buildSection(
              '2. Uso del Servicio',
              '''
• Debes ser mayor de 18 años
• Proporcionar información veraz y actualizada
• Usar el servicio de forma legal y ética
• No compartir tu cuenta con otros
• Respetar a otros usuarios
              ''',
            ),
            _buildSection(
              '3. Responsabilidades',
              '''
Como Usuario:
• Describes con precisión el trabajo necesario
• Pagas los servicios acordados
• Calificas de forma honesta

Como Trabajador:
• Cumples con los trabajos aceptados
• Proporcionas servicios de calidad
• Respetas los acuerdos establecidos
              ''',
            ),
            _buildSection(
              '4. Pagos',
              '''
• Los pagos se realizan fuera de la app
• MyWorksApp no es responsable de transacciones
• Cualquier disputa debe resolverse entre las partes
              ''',
            ),
            _buildSection(
              '5. Propiedad Intelectual',
              '''
• El contenido de la app es propiedad de MyWorksApp
• No puedes copiar, modificar o distribuir sin autorización
• Las fotos subidas permanecen propiedad del usuario
              ''',
            ),
            _buildSection(
              '6. Naturaleza de la Plataforma (IMPORTANTE)',
              '''
MyWorksApp actúa ÚNICAMENTE como intermediario tecnológico entre usuarios y trabajadores independientes.

DECLARACIÓN LEGAL:
• MyWorksApp NO presta servicios profesionales ni técnicos regulados
• MyWorksApp NO asume responsabilidad por la calidad, resultado o cumplimiento de los servicios
• Los trabajadores son independientes y no tienen relación laboral con MyWorksApp
• El pago se realiza directamente entre usuario y trabajador (Fase 1)
• MyWorksApp no procesa pagos ni emite boletas en esta etapa

Esta estructura protege a la plataforma frente a:
• Dirección del Trabajo (sin relación laboral)
• SII (sin responsabilidad tributaria directa)
• Responsabilidad civil directa
• Relación laboral encubierta
              ''',
            ),
            _buildSection(
              '7. Limitación de Responsabilidad',
              '''
MyWorksApp actúa como plataforma de conexión.
No somos responsables de:
• Calidad de servicios prestados por trabajadores independientes
• Disputas entre usuarios y trabajadores
• Daños derivados del uso del servicio
• Resultados de trabajos realizados
• Cumplimiento de acuerdos entre partes
• Responsabilidades laborales o tributarias de trabajadores
              ''',
            ),
            _buildSection(
              '8. Modificaciones',
              '''
Nos reservamos el derecho de:
• Modificar estos términos en cualquier momento
• Notificar cambios importantes
• Requerir nueva aceptación si hay cambios sustanciales
              ''',
            ),
            _buildSection(
              '9. Terminación',
              '''
Podemos suspender o terminar tu cuenta si:
• Violas estos términos
• Realizas actividades fraudulentas
• No cumples con tus obligaciones
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

