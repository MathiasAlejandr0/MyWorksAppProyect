import { listaProfesionalesParecidos, resumenResenasPublico, type ProfesionalParecido } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

type ResumenQuery = {
  from: (table: 'ia_resumen_resenas') => {
    select: (columns: 'resumen') => {
      eq: (column: 'id_profesional', id: string) => {
        maybeSingle: () => Promise<{ data: unknown; error: { message: string } | null }>;
      };
    };
  };
  rpc: (fn: 'profesionales_parecidos', args: { p_id: string; p_limite: number }) => Promise<{
    data: unknown;
    error: { message: string } | null;
  }>;
};

function cliente(): ResumenQuery {
  return supabase as unknown as ResumenQuery;
}

export async function leerResumenResenas(id: string): Promise<string | null> {
  try {
    const { data, error } = await cliente()
      .from('ia_resumen_resenas')
      .select('resumen')
      .eq('id_profesional', id)
      .maybeSingle();
    if (error) return null;
    return resumenResenasPublico(data);
  } catch {
    return null;
  }
}

export async function leerProfesionalesParecidos(id: string): Promise<ProfesionalParecido[]> {
  try {
    const { data, error } = await cliente().rpc('profesionales_parecidos', {
      p_id: id,
      p_limite: 4,
    });
    if (error) return [];
    return listaProfesionalesParecidos(data);
  } catch {
    return [];
  }
}
