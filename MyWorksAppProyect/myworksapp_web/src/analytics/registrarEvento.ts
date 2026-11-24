import { filaEventoAnalitica, type NombreEventoUso } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export function registrarEventoUso(
  nombre: NombreEventoUso,
  metadatos: Record<string, string> = {},
): void {
  void (async () => {
    try {
      const { data } = await supabase.auth.getSession();
      await supabase.from('eventos_analitica').insert(
        filaEventoAnalitica(nombre, metadatos, data.session?.user.id ?? null),
      );
    } catch {
      return;
    }
  })();
}
