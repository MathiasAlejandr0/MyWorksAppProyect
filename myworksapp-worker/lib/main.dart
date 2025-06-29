import 'package:flutter/material.dart';
import 'pages/worker_login_page.dart';
import 'utils/app_colors.dart';
import 'database/worker_database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Insertar datos de prueba
  final dbHelper = WorkerDatabaseHelper();
  await dbHelper.insertTestData();

  runApp(const MyWorkerApp());
}

class MyWorkerApp extends StatelessWidget {
  const MyWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyWorks - Trabajador',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppColors.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
      ),
      home: const WorkerLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
