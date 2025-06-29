// Import condicional para web y nativo
export 'worker_database_helper_web.dart'
    if (dart.library.io) 'worker_database_helper_native.dart';
