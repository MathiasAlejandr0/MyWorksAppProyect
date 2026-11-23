import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { describe, it } from 'node:test';
import { OPEN_DISPUTE_STATES, isOpenDispute } from './disputes.ts';
import { classifyLoadError, describeLoadError, friendlyError } from './errors.ts';

describe('mensajes de error', () => {
  it('traduce la sesión ausente y otros textos de Auth en inglés', () => {
    assert.equal(
      friendlyError({ message: 'Auth session missing!' }),
      'No hay una sesión activa. Abre otra vez el enlace del correo.',
    );
    assert.match(friendlyError({ message: 'Password should be at least 6 characters' }), /8 caracteres/);
    assert.match(friendlyError({ message: 'Failed to fetch' }), /No se pudo conectar/);
    assert.equal(
      friendlyError({ message: 'New password should be different from the old password.' }),
      'La nueva contraseña debe ser distinta de la anterior.',
    );
  });

  it('conserva un motivo que ya viene en español', () => {
    assert.equal(
      friendlyError({ message: 'La contraseña debe tener al menos 8 caracteres' }),
      'La contraseña debe tener al menos 8 caracteres',
    );
    assert.equal(
      friendlyError({ message: 'No puedes quitar al último administrador' }),
      'No puedes quitar al último administrador',
    );
  });

  it('no muestra un error de red como si el registro no existiera', () => {
    const network = { message: 'Failed to fetch', code: '503' };
    const missing = { message: 'JSON object requested, multiple (or no) rows returned', code: 'PGRST116' };
    assert.equal(classifyLoadError(network), 'network');
    assert.equal(classifyLoadError(missing), 'not_found');
    assert.match(describeLoadError(network, 'No se encontró el pedido.'), /Revisa la red/);
    assert.equal(describeLoadError(missing, 'No se encontró el pedido.'), 'No se encontró el pedido.');
    assert.equal(classifyLoadError({ message: 'permission denied for table trabajadores', code: '42501' }), 'forbidden');
    assert.equal(classifyLoadError({ message: 'Could not find the function public.consola_leer_config', code: 'PGRST202' }), 'missing_migration');
  });
});

describe('estados de disputa en la cola', () => {
  it('incluye abierta y los estados que cuenta el resumen', () => {
    assert.equal(isOpenDispute('abierta'), true);
    assert.equal(isOpenDispute('en_revision'), true);
    assert.equal(isOpenDispute('requiere_humano'), true);
    assert.equal(isOpenDispute('reembolso_pendiente'), true);
    assert.equal(isOpenDispute('resuelta'), false);
    assert.equal(isOpenDispute(null), false);
  });

  it('la migración usa la cola activa y exige admin para leer ajustes', () => {
    const sql = readFileSync(
      new URL(
        '../../../myworksapp_app/supabase/migrations/20261123032058_consola_lectura_config_y_disputas.sql',
        import.meta.url,
      ),
      'utf8',
    );
    const activa = readFileSync(
      new URL(
        '../../../myworksapp_app/supabase/migrations/20261112000001_soporte_automatico.sql',
        import.meta.url,
      ),
      'utf8',
    );
    const body = activa.slice(activa.indexOf('FUNCTION public.disputa_esta_activa'));
    for (const estado of OPEN_DISPUTE_STATES) {
      assert.match(body, new RegExp(`'${estado}'`));
    }
    assert.match(sql, /disputa_esta_activa\(d\.estado\)/);
    assert.doesNotMatch(sql, /'resuelta'/);
    assert.match(sql, /IF NOT public\.is_admin\(\)/);
    assert.match(sql, /GRANT EXECUTE ON FUNCTION public\.consola_leer_config\(\) TO authenticated/);
    assert.doesNotMatch(sql, /GRANT EXECUTE ON FUNCTION public\.consola_leer_config\(\) TO anon/);
    assert.doesNotMatch(sql, /demo_modo\s*=/);
  });
});
