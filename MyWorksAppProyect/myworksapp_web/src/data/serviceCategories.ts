/** Catálogo completo de oficios My Works App (web). */

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
    photo: '/categories/electricidad-instalacion.webp',
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
    photo: '/categories/pintura-rodillo.webp',
    searchQuery: 'pintura',
  },
  {
    id: 'jardineria',
    title: 'Jardinería',
    subtitle: 'Poda, riego y mantención',
    photo: '/categories/jardineria-mantencion.webp',
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
    photo: '/categories/construccion-obra.webp',
    searchQuery: 'construcción',
  },
  {
    id: 'soporte_tecnico',
    title: 'Soporte técnico',
    subtitle: 'PC, redes y dispositivos',
    photo: '/categories/soporte-tecnico-redes.webp',
    searchQuery: 'soporte técnico',
  },
  {
    id: 'mudanza',
    title: 'Mudanza',
    subtitle: 'Traslado y embalaje',
    photo: '/categories/mudanza-cajas.webp',
    searchQuery: 'mudanza',
  },
  {
    id: 'climatizacion',
    title: 'Climatización',
    subtitle: 'Aire acondicionado y calefacción',
    photo: '/categories/climatizacion-aire.webp',
    searchQuery: 'climatización aire acondicionado',
  },
];

/** Categorías destacadas en el home (subset). */
export const FEATURED_CATEGORIES = ALL_SERVICE_CATEGORIES.slice(0, 4);
