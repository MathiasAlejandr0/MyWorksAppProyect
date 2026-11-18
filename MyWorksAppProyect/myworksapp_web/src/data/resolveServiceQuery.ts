import { foldSearchText } from '@myworksapp/shared';

export type ResolvedServiceQuery = {
  category: string;
  categoryName: string;
  problem: string;
  minPrice: number;
  maxPrice: number;
  urgency: 'Media' | 'Alta';
};

export function resolveCategory(text: string): ResolvedServiceQuery | null {
  // Sin tildes ni mayúsculas: «electrico» y «Eléctrico» dan la misma categoría.
  const lower = foldSearchText(text);

  if (
    lower.includes('fuga') ||
    lower.includes('agua') ||
    lower.includes('lavaplatos') ||
    lower.includes('llave') ||
    lower.includes('plomer')
  ) {
    return {
      category: 'plomeria',
      categoryName: 'Plomería',
      problem: 'Reparación de fuga de agua y cambio de llaves o grifería',
      minPrice: 30000,
      maxPrice: 75000,
      urgency: 'Media',
    };
  }

  if (lower.includes('gasfiter') || lower.includes('gas ')) {
    return {
      category: 'gasfiteria',
      categoryName: 'Gasfitería (gas)',
      problem: 'Conexiones, revisiones y mantención de gas',
      minPrice: 30000,
      maxPrice: 80000,
      urgency: 'Media',
    };
  }

  if (
    lower.includes('mueble') ||
    lower.includes('armar') ||
    lower.includes('closet') ||
    lower.includes('rack') ||
    lower.includes('armado') ||
    lower.includes('ensamblaje')
  ) {
    return {
      category: 'ensamblaje',
      categoryName: 'Armado de Muebles',
      problem: 'Montaje e instalación de mueble listo para armar',
      minPrice: 20000,
      maxPrice: 45000,
      urgency: 'Media',
    };
  }

  if (lower.includes('limpieza') || lower.includes('aseo')) {
    return {
      category: 'limpieza',
      categoryName: 'Limpieza',
      problem: 'Limpieza del hogar u oficina',
      minPrice: 18000,
      maxPrice: 45000,
      urgency: 'Media',
    };
  }

  if (lower.includes('pintura') || lower.includes('pintor')) {
    return {
      category: 'pintura',
      categoryName: 'Pintura',
      problem: 'Pintura de interiores o exteriores',
      minPrice: 25000,
      maxPrice: 70000,
      urgency: 'Media',
    };
  }

  if (lower.includes('jardin') || lower.includes('poda')) {
    return {
      category: 'jardineria',
      categoryName: 'Jardinería',
      problem: 'Poda, riego y mantención de áreas verdes',
      minPrice: 20000,
      maxPrice: 55000,
      urgency: 'Media',
    };
  }

  if (lower.includes('cerraj') || lower.includes('chapa')) {
    return {
      category: 'cerrajeria',
      categoryName: 'Cerrajería',
      problem: 'Apertura o cambio de chapas',
      minPrice: 22000,
      maxPrice: 60000,
      urgency: 'Alta',
    };
  }

  if (
    lower.includes('construc') ||
    lower.includes('remodel') ||
    lower.includes('maestro')
  ) {
    return {
      category: 'construccion',
      categoryName: 'Construcción',
      problem: 'Obras menores y remodelaciones',
      minPrice: 40000,
      maxPrice: 120000,
      urgency: 'Media',
    };
  }

  if (lower.includes('soporte') || lower.includes('comput') || lower.includes('pc ')) {
    return {
      category: 'soporte_tecnico',
      categoryName: 'Soporte técnico',
      problem: 'Diagnóstico y reparación de equipos',
      minPrice: 20000,
      maxPrice: 50000,
      urgency: 'Media',
    };
  }

  if (lower.includes('mudanza') || lower.includes('traslado')) {
    return {
      category: 'mudanza',
      categoryName: 'Mudanza',
      problem: 'Traslado y embalaje',
      minPrice: 50000,
      maxPrice: 150000,
      urgency: 'Media',
    };
  }

  if (
    lower.includes('climat') ||
    lower.includes('aire acondicionado') ||
    lower.includes('calefacc')
  ) {
    return {
      category: 'climatizacion',
      categoryName: 'Climatización',
      problem: 'Instalación o mantención de climatización',
      minPrice: 35000,
      maxPrice: 90000,
      urgency: 'Media',
    };
  }

  if (lower.includes('electric') || lower.includes('electricista')) {
    return {
      category: 'electricidad',
      categoryName: 'Electricidad',
      problem: 'Instalaciones y reparaciones eléctricas',
      minPrice: 25000,
      maxPrice: 60000,
      urgency: 'Media',
    };
  }

  return null;
}

export type MapSite = { latitude: number; longitude: number };

export function finiteMapSite(
  latitude?: number | null,
  longitude?: number | null,
): MapSite | null {
  if (
    typeof latitude === 'number' &&
    typeof longitude === 'number' &&
    Number.isFinite(latitude) &&
    Number.isFinite(longitude)
  ) {
    return { latitude, longitude };
  }
  return null;
}
