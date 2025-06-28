import 'package:flutter/material.dart';

// Modelo de datos para los servicios
class Service {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final IconData icon;
  final Color color;
  final double basePrice;
  final List<String> categories;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.color,
    this.basePrice = 0.0,
    this.categories = const [],
  });
}

// Modelo para profesionales
class Professional {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String profileImage;
  final String bio;
  final List<String> services; // IDs de servicios que ofrece
  final double rating;
  final int totalReviews;
  final int completedJobs;
  final int yearsExperience;
  final bool isVerified;
  final bool isAvailable;
  final String location;
  final List<String> certifications;
  final Map<String, double> servicePrices; // Precios por servicio

  Professional({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImage,
    required this.bio,
    required this.services,
    this.rating = 0.0,
    this.totalReviews = 0,
    this.completedJobs = 0,
    this.yearsExperience = 0,
    this.isVerified = false,
    this.isAvailable = true,
    this.location = '',
    this.certifications = const [],
    this.servicePrices = const {},
  });
}

// Modelo para portafolio de proyectos
class PortfolioItem {
  final String id;
  final String professionalId;
  final String title;
  final String description;
  final List<String> images;
  final DateTime completedDate;
  final String serviceType;
  final double cost;
  final String clientFeedback;

  PortfolioItem({
    required this.id,
    required this.professionalId,
    required this.title,
    required this.description,
    required this.images,
    required this.completedDate,
    required this.serviceType,
    this.cost = 0.0,
    this.clientFeedback = '',
  });
}

// Modelo para evaluaciones
class Review {
  final String id;
  final String professionalId;
  final String clientId;
  final String clientName;
  final double rating; // 1-5 estrellas
  final String comment;
  final DateTime reviewDate;
  final String serviceType;
  final bool isVerified;

  Review({
    required this.id,
    required this.professionalId,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.reviewDate,
    required this.serviceType,
    this.isVerified = false,
  });
}

// Modelo para solicitudes de servicio
class ServiceRequest {
  final String id;
  final String clientId;
  final String professionalId;
  final Service service;
  final String address;
  final String description;
  final DateTime requestedDate;
  final DateTime? scheduledDate;
  final String
  status; // 'pending', 'accepted', 'in_progress', 'completed', 'cancelled'
  final double? estimatedCost;
  final double? finalCost;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceRequest({
    required this.id,
    required this.clientId,
    required this.professionalId,
    required this.service,
    required this.address,
    required this.description,
    required this.requestedDate,
    this.scheduledDate,
    this.status = 'pending',
    this.estimatedCost,
    this.finalCost,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });
}

// Modelo para usuario
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final List<String> addresses;
  final bool isProfessional;
  final String? professionalId; // Si es profesional
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isVerified;
  final String? fcmToken; // Para notificaciones push

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    this.addresses = const [],
    this.isProfessional = false,
    this.professionalId,
    required this.createdAt,
    this.lastLogin,
    this.isVerified = false,
    this.fcmToken,
  });
}

// Modelo para notificaciones
class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // 'request', 'review', 'system', 'chat'
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });
}

// Lista de servicios disponibles
final List<Service> services = [
  Service(
    id: '1',
    name: 'Maestro Constructor',
    description:
        'Servicios de construcción, remodelación y reparaciones estructurales.',
    imageUrl: 'assets/images/constructor.jpg',
    icon: Icons.construction,
    color: Colors.amber,
    basePrice: 50000,
    categories: ['construcción', 'remodelación', 'reparación'],
  ),
  Service(
    id: '2',
    name: 'Gasfiter',
    description:
        'Reparación e instalación de sistemas de agua, gas y alcantarillado.',
    imageUrl: 'assets/images/gasfiter.jpg',
    icon: Icons.plumbing,
    color: Colors.blue,
    basePrice: 30000,
    categories: ['plomería', 'instalación', 'reparación'],
  ),
  Service(
    id: '3',
    name: 'Cerrajero',
    description:
        'Servicios de cerrajería, instalación y reparación de cerraduras.',
    imageUrl: 'assets/images/cerrajero.jpg',
    icon: Icons.lock,
    color: Colors.grey,
    basePrice: 25000,
    categories: ['cerrajería', 'seguridad', 'instalación'],
  ),
  Service(
    id: '4',
    name: 'Electricista',
    description: 'Instalación y reparación de sistemas eléctricos.',
    imageUrl: 'assets/images/electricista.jpg',
    icon: Icons.electrical_services,
    color: Colors.yellow,
    basePrice: 35000,
    categories: ['electricidad', 'instalación', 'reparación'],
  ),
  Service(
    id: '5',
    name: 'Jardinero',
    description: 'Mantenimiento y diseño de jardines y áreas verdes.',
    imageUrl: 'assets/images/jardinero.jpg',
    icon: Icons.grass,
    color: Colors.green,
    basePrice: 20000,
    categories: ['jardinería', 'mantenimiento', 'diseño'],
  ),
];

// Datos de ejemplo para profesionales
final List<Professional> professionals = [
  Professional(
    id: 'prof_1',
    name: 'Carlos Mendoza',
    email: 'carlos.mendoza@email.com',
    phone: '+56 9 1234 5678',
    profileImage: 'assets/images/professional_1.jpg',
    bio:
        'Maestro constructor con más de 15 años de experiencia en construcción y remodelación de viviendas. Especializado en proyectos residenciales y comerciales.',
    services: ['1', '4'], // Constructor y Electricista
    rating: 4.8,
    totalReviews: 47,
    completedJobs: 156,
    yearsExperience: 15,
    isVerified: true,
    isAvailable: true,
    location: 'Santiago Centro',
    certifications: ['Licencia de construcción', 'Certificación eléctrica'],
    servicePrices: {
      '1': 55000, // Constructor
      '4': 40000, // Electricista
    },
  ),
  Professional(
    id: 'prof_2',
    name: 'María González',
    email: 'maria.gonzalez@email.com',
    phone: '+56 9 2345 6789',
    profileImage: 'assets/images/professional_2.jpg',
    bio:
        'Gasfitera profesional con amplia experiencia en instalaciones residenciales y comerciales. Trabajo limpio y garantizado.',
    services: ['2'], // Gasfiter
    rating: 4.9,
    totalReviews: 89,
    completedJobs: 234,
    yearsExperience: 8,
    isVerified: true,
    isAvailable: true,
    location: 'Providencia',
    certifications: ['Licencia de gasfitería', 'Certificación de seguridad'],
    servicePrices: {
      '2': 32000, // Gasfiter
    },
  ),
  Professional(
    id: 'prof_3',
    name: 'Roberto Silva',
    email: 'roberto.silva@email.com',
    phone: '+56 9 3456 7890',
    profileImage: 'assets/images/professional_3.jpg',
    bio:
        'Cerrajero experto en sistemas de seguridad modernos. Instalación y reparación de cerraduras, candados y sistemas de acceso.',
    services: ['3'], // Cerrajero
    rating: 4.7,
    totalReviews: 34,
    completedJobs: 89,
    yearsExperience: 12,
    isVerified: true,
    isAvailable: true,
    location: 'Las Condes',
    certifications: ['Licencia de cerrajería', 'Certificación de seguridad'],
    servicePrices: {
      '3': 28000, // Cerrajero
    },
  ),
  Professional(
    id: 'prof_4',
    name: 'Ana Rodríguez',
    email: 'ana.rodriguez@email.com',
    phone: '+56 9 4567 8901',
    profileImage: 'assets/images/professional_4.jpg',
    bio:
        'Jardinera paisajista con experiencia en diseño y mantenimiento de jardines residenciales y comerciales. Especializada en plantas nativas.',
    services: ['5'], // Jardinero
    rating: 4.6,
    totalReviews: 56,
    completedJobs: 123,
    yearsExperience: 6,
    isVerified: true,
    isAvailable: true,
    location: 'Ñuñoa',
    certifications: ['Técnico en jardinería', 'Paisajismo'],
    servicePrices: {
      '5': 22000, // Jardinero
    },
  ),
];

// Datos de ejemplo para portafolios
final List<PortfolioItem> portfolioItems = [
  PortfolioItem(
    id: 'port_1',
    professionalId: 'prof_1',
    title: 'Remodelación Casa Familiar',
    description:
        'Remodelación completa de una casa de 120m² en Las Condes. Incluyó renovación de cocina, baños y ampliación de living.',
    images: [
      'assets/images/portfolio_1_1.jpg',
      'assets/images/portfolio_1_2.jpg',
    ],
    completedDate: DateTime(2024, 3, 15),
    serviceType: 'Maestro Constructor',
    cost: 8500000,
    clientFeedback:
        'Excelente trabajo, muy profesional y puntual. Recomendado 100%.',
  ),
  PortfolioItem(
    id: 'port_2',
    professionalId: 'prof_2',
    title: 'Instalación Sistema de Agua',
    description:
        'Instalación completa del sistema de agua potable en edificio residencial de 8 pisos.',
    images: ['assets/images/portfolio_2_1.jpg'],
    completedDate: DateTime(2024, 4, 20),
    serviceType: 'Gasfiter',
    cost: 1200000,
    clientFeedback: 'Trabajo impecable, muy satisfecho con el resultado.',
  ),
];

// Datos de ejemplo para evaluaciones
final List<Review> reviews = [
  Review(
    id: 'rev_1',
    professionalId: 'prof_1',
    clientId: 'client_1',
    clientName: 'Juan Pérez',
    rating: 5.0,
    comment:
        'Excelente trabajo, muy profesional y puntual. La remodelación quedó perfecta.',
    reviewDate: DateTime(2024, 3, 20),
    serviceType: 'Maestro Constructor',
    isVerified: true,
  ),
  Review(
    id: 'rev_2',
    professionalId: 'prof_1',
    clientId: 'client_2',
    clientName: 'María López',
    rating: 4.5,
    comment: 'Muy buen trabajo, aunque se retrasó un poco en la entrega final.',
    reviewDate: DateTime(2024, 2, 15),
    serviceType: 'Maestro Constructor',
    isVerified: true,
  ),
  Review(
    id: 'rev_3',
    professionalId: 'prof_2',
    clientId: 'client_3',
    clientName: 'Carlos Ruiz',
    rating: 5.0,
    comment:
        'Increíble trabajo, resolvió el problema rápidamente y con mucha profesionalidad.',
    reviewDate: DateTime(2024, 4, 25),
    serviceType: 'Gasfiter',
    isVerified: true,
  ),
];
