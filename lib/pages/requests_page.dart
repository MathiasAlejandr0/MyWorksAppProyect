import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/models.dart';

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Solicitudes')),
      body: FutureBuilder<List<ServiceRequest>>(
        // Simulamos la carga de datos
        future: Future.delayed(
          const Duration(seconds: 1),
          () => [], // Lista vacía por ahora
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar solicitudes: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes solicitudes activas',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/home',
                        arguments: 0,
                      );
                    },
                    child: const Text('Explorar servicios'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: request.service.color.withOpacity(0.2),
                    child: Icon(
                      request.service.icon,
                      color: request.service.color,
                    ),
                  ),
                  title: Text(request.service.name),
                  subtitle: Text(
                    '${request.requestedDate.day}/${request.requestedDate.month}/${request.requestedDate.year} - ${request.status}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Implementar vista detallada de la solicitud
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
