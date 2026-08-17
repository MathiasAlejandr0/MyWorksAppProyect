import '../database/models/service_model.dart';
import '../database/models/worker_model.dart';
import '../database/repositories/worker_repository.dart';

/// Resultado del análisis semántico del Asistente IA por palabras clave
class AiRecommendationResult {
  final String query;
  final String categoryKey;
  final String categoryName;
  final String detectedProblem;
  final int minPriceEstimate;
  final int maxPriceEstimate;
  final String urgencyLevel; // Baja, Media, Alta (24/7)
  final List<String> recommendedTools;
  final List<WorkerModel> recommendedWorkers;

  AiRecommendationResult({
    required this.query,
    required this.categoryKey,
    required this.categoryName,
    required this.detectedProblem,
    required this.minPriceEstimate,
    required this.maxPriceEstimate,
    required this.urgencyLevel,
    required this.recommendedTools,
    required this.recommendedWorkers,
  });
}

/// Motor Inteligente de Análisis Semántico por Palabras Claves y Recomendación
class AiServiceRecommendationEngine {
  final WorkerRepository _workerRepository = WorkerRepository();

  static final AiServiceRecommendationEngine instance = AiServiceRecommendationEngine._();
  AiServiceRecommendationEngine._();

  /// Analiza texto natural ingresado por el usuario y determina oficio, costo y profesionales
  Future<AiRecommendationResult> analyzeQuery(String text) async {
    final cleanText = text.toLowerCase().trim();

    String categoryKey = ServiceCategories.electrical;
    String categoryName = 'Electricista';
    String problem = 'Diagnóstico y reparación general';
    int minPrice = 25000;
    int maxPrice = 55000;
    String urgency = 'Media';
    List<String> tools = ['Herramientas estándar', 'Tester digital'];

    if (_containsAny(cleanText, ['fuga', 'cañeria', 'cañería', 'sifon', 'sifón', 'agua', 'gotea', 'gasfiter', 'gásfiter', 'inodoro', 'wc', 'llave', 'grifo', 'filtracion', 'filtración'])) {
      categoryKey = ServiceCategories.plumbing;
      categoryName = 'Gásfiter / Plomero';
      problem = 'Filtración y reparación de grifería / tuberías';
      minPrice = 30000;
      maxPrice = 75000;
      tools = ['Soplete', 'Llave francesa', 'Sellante de teflón', 'Goma de estanqueidad'];
      if (_containsAny(cleanText, ['inundacion', 'inundación', 'inundado', 'urgente', 'reventada', 'ahora'])) {
        urgency = 'Alta (Urgencia 24/7)';
      }
    } else if (_containsAny(cleanText, ['luz', 'enchufe', 'tablero', 'automatico', 'automático', 'cortocircuito', 'corto', 'cable', 'lampara', 'lámpara', 'electri'])) {
      categoryKey = ServiceCategories.electrical;
      categoryName = 'Electricista Certificado';
      problem = 'Revisión de circuitos y reparación de falla eléctrica';
      minPrice = 25000;
      maxPrice = 65000;
      tools = ['Multímetro digital', 'Alicate pelacables', 'Cinta aislante 3M', 'Breaker sustituto'];
      if (_containsAny(cleanText, ['chispa', 'humo', 'quemado', 'sin luz', 'oscuro'])) {
        urgency = 'Alta (Urgencia 24/7)';
      }
    } else if (_containsAny(cleanText, ['limpia', 'limpieza', 'aseo', 'casa', 'departamento', 'dpto', 'oficina', 'profundo', 'ventana', 'alfombra'])) {
      categoryKey = ServiceCategories.cleaning;
      categoryName = 'Limpieza del Hogar u Oficina';
      problem = 'Aseo profundo y sanitización de espacios';
      minPrice = 35000;
      maxPrice = 80000;
      urgency = 'Normal';
      tools = ['Insumos biodegradables', 'Aspiradora industrial', 'Limpiavidrios telescópico'];
    } else if (_containsAny(cleanText, ['mueble', 'armado', 'armar', 'closet', 'clóset', 'rack', 'cama', 'escritorio', 'ikea', 'easy', 'sodimac'])) {
      categoryKey = ServiceCategories.assembly;
      categoryName = 'Armado de Muebles';
      problem = 'Montaje e instalación de muebles de kit listo';
      minPrice = 20000;
      maxPrice = 50000;
      urgency = 'Normal';
      tools = ['Atornillador inalámbrico', 'Nivel de gota', 'Juego de llaves Allen'];
    } else if (_containsAny(cleanText, ['mudanza', 'flete', 'traslado', 'caja', 'camion', 'camión', 'carga', 'transporte'])) {
      categoryKey = ServiceCategories.moving;
      categoryName = 'Mudanzas y Fletes Expresos';
      problem = 'Carga, transporte seguro y descarga de enseres';
      minPrice = 45000;
      maxPrice = 140000;
      urgency = 'Planificada';
      tools = ['Camión cerrado 3.5T', 'Mantas protectoras', 'Cinchas de amarre', 'Carro de carga'];
    } else if (_containsAny(cleanText, ['pc', 'computador', 'laptop', 'notebook', 'wifi', 'red', 'router', 'impresora', 'pantalla', 'formatear'])) {
      categoryKey = ServiceCategories.techSupport;
      categoryName = 'Soporte Técnico Informático';
      problem = 'Diagnóstico de hardware, red o software';
      minPrice = 20000;
      maxPrice = 45000;
      urgency = 'Normal';
      tools = ['Pendrive de diagnóstico', 'Probador de red RJ45', 'Pasta térmica artic'];
    } else if (_containsAny(cleanText, ['jardin', 'jardín', 'poda', 'cesped', 'césped', 'pasto', 'arbol', 'árbol', 'planta', 'riego'])) {
      categoryKey = ServiceCategories.gardening;
      categoryName = 'Jardinería y Paisajismo';
      problem = 'Poda de formación, corte de césped y mantenimiento';
      minPrice = 25000;
      maxPrice = 60000;
      urgency = 'Normal';
      tools = ['Cortacésped', 'Tijeras de podar de altura', 'Abono orgánico'];
    } else if (_containsAny(cleanText, ['obra', 'construccion', 'construcción', 'maestro', 'pared', 'muro', 'tabique', 'pintura', 'pintar', 'ceramica', 'cerámica', 'piso'])) {
      categoryKey = ServiceCategories.construction;
      categoryName = 'Maestro Constructor';
      problem = 'Remodelación, tabiquería o pintura';
      minPrice = 40000;
      maxPrice = 180000;
      tools = ['Nivel láser', 'Taladro percutor', 'Rodillos antigota', 'Cortadora de cerámica'];
    }

    // Consultar trabajadores en el repositorio
    final workers = await _workerRepository.getWorkersByServiceCategory(categoryKey);
    final topWorkers = workers.take(3).toList();

    return AiRecommendationResult(
      query: text,
      categoryKey: categoryKey,
      categoryName: categoryName,
      detectedProblem: problem,
      minPriceEstimate: minPrice,
      maxPriceEstimate: maxPrice,
      urgencyLevel: urgency,
      recommendedTools: tools,
      recommendedWorkers: topWorkers,
    );
  }

  bool _containsAny(String source, List<String> keywords) {
    for (final kw in keywords) {
      if (source.contains(kw)) return true;
    }
    return false;
  }
}
