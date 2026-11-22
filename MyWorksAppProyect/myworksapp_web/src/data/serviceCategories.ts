/** Catálogo completo de oficios My Works App (web). */

/** Helper para rutas de imágenes locales en /categories/ */
const local = (name: string) => `/categories/${name}.webp`;

export type ServiceCategory = {
  id: string;
  title: string;
  subtitle: string;
  photo: string;
  /** Texto de búsqueda / matching con backend */
  searchQuery: string;
};

export const ALL_SERVICE_CATEGORIES: ServiceCategory[] = [
  {
    id: 'ensamblaje',
    title: 'Armado',
    subtitle: 'Muebles, estanterías y más',
    photo: '/categories/armado.webp',
    searchQuery: 'armado muebles',
  },
  {
    id: 'electricidad',
    title: 'Electricidad',
    subtitle: 'Instalaciones, reparaciones y más',
    photo: '/categories/electricidad-1795386019.webp',
    searchQuery: 'electricidad',
  },
  {
    id: 'plomeria',
    title: 'Plomería',
    subtitle: 'Fugas de agua, cañerías y grifería',
    photo: '/categories/plomeria.webp',
    searchQuery: 'plomería',
  },
  {
    id: 'gasfiteria',
    title: 'Gasfitería (gas)',
    subtitle: 'Calefont, cocinas y conexiones de gas',
    photo: '/categories/gasfiteria.webp',
    searchQuery: 'gasfitería',
  },
  {
    id: 'limpieza',
    title: 'Limpieza',
    subtitle: 'Hogar, oficina y profunda',
    photo: '/categories/limpieza.webp',
    searchQuery: 'limpieza',
  },
  {
    id: 'pintura',
    title: 'Pintura',
    subtitle: 'Interiores y exteriores',
    photo: '/categories/pintura.webp',
    searchQuery: 'pintura',
  },
  {
    id: 'jardineria',
    title: 'Jardinería',
    subtitle: 'Poda, riego y mantención',
    photo: '/categories/jardineria.webp',
    searchQuery: 'jardinería',
  },
  {
    id: 'cerrajeria',
    title: 'Cerrajería',
    subtitle: 'Aperturas y cambio de chapas',
    photo: '/categories/cerrajeria.webp',
    searchQuery: 'cerrajería',
  },
  {
    id: 'construccion',
    title: 'Construcción',
    subtitle: 'Remodelaciones y obras menores',
    photo: local('construccion'),
    searchQuery: 'construcción',
  },
  {
    id: 'soporte_tecnico',
    title: 'Soporte técnico',
    subtitle: 'PC, redes y dispositivos',
    photo: local('soporte-tecnico'),
    searchQuery: 'soporte técnico',
  },
  {
    id: 'mudanza',
    title: 'Mudanza',
    subtitle: 'Traslado y embalaje',
    photo: local('mudanza'),
    searchQuery: 'mudanza',
  },
  {
    id: 'climatizacion',
    title: 'Climatización',
    subtitle: 'Aire acondicionado y calefacción',
    photo: local('climatizacion'),
    searchQuery: 'climatización aire acondicionado',
  },
];

/** Categorías destacadas en el home (subset). */
export const FEATURED_CATEGORIES = ALL_SERVICE_CATEGORIES.slice(0, 4);
