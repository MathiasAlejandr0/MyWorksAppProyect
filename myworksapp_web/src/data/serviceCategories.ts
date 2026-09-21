/** Catálogo completo de oficios My Works App (web). */

const U = 'https://images.unsplash.com';
const img = (id: string) =>
  `${U}/photo-${id}?auto=format&fit=crop&w=900&h=560&q=80`;

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
    photo: '/categories/armado.png',
    searchQuery: 'armado muebles',
  },
  {
    id: 'electricidad',
    title: 'Electricidad',
    subtitle: 'Instalaciones, reparaciones y más',
    photo: img('1621905251189-08b45d6a269e'),
    searchQuery: 'electricidad',
  },
  {
    id: 'plomeria',
    title: 'Plomería',
    subtitle: 'Fugas, instalaciones y más',
    photo: '/categories/plomeria.png',
    searchQuery: 'plomería',
  },
  {
    id: 'gasfiteria',
    title: 'Gasfitería',
    subtitle: 'Conexiones, revisiones y más',
    photo: '/categories/gasfiteria.png',
    searchQuery: 'gasfitería',
  },
  {
    id: 'limpieza',
    title: 'Limpieza',
    subtitle: 'Hogar, oficina y profunda',
    photo: '/categories/limpieza.png',
    searchQuery: 'limpieza',
  },
  {
    id: 'pintura',
    title: 'Pintura',
    subtitle: 'Interiores y exteriores',
    photo: img('1562259949-e8e7689d7828'),
    searchQuery: 'pintura',
  },
  {
    id: 'jardineria',
    title: 'Jardinería',
    subtitle: 'Poda, riego y mantención',
    photo: img('1416879595882-3373a0480b5b'),
    searchQuery: 'jardinería',
  },
  {
    id: 'cerrajeria',
    title: 'Cerrajería',
    subtitle: 'Aperturas y cambio de chapas',
    photo: '/categories/cerrajeria.png',
    searchQuery: 'cerrajería',
  },
  {
    id: 'construccion',
    title: 'Construcción',
    subtitle: 'Remodelaciones y obras menores',
    photo: img('1504307651254-35680f356dfd'),
    searchQuery: 'construcción',
  },
  {
    id: 'soporte_tecnico',
    title: 'Soporte técnico',
    subtitle: 'PC, redes y dispositivos',
    photo: img('1516321318423-f06f85e504b3'),
    searchQuery: 'soporte técnico',
  },
  {
    id: 'mudanza',
    title: 'Mudanza',
    subtitle: 'Traslado y embalaje',
    photo: img('1600518464441-9154a4dea21b'),
    searchQuery: 'mudanza',
  },
  {
    id: 'climatizacion',
    title: 'Climatización',
    subtitle: 'Aire acondicionado y calefacción',
    photo: img('1558618666-fcd25c85cd64'),
    searchQuery: 'climatización aire acondicionado',
  },
];

/** Categorías destacadas en el home (subset). */
export const FEATURED_CATEGORIES = ALL_SERVICE_CATEGORIES.slice(0, 4);
