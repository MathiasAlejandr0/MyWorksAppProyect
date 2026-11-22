import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { evaluarCors, evaluarSecretos } from './seguridad-checks.ts';

const SERVICE = ['eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9', 'eyJyb2xlIjoic2VydmljZV9yb2xlIn0', 'signature'].join('.');

describe('chequeos de la consola', () => {
  it('marca el comodin CORS como aviso', () => {
    const hallazgo = evaluarCors('*', 200);
    assert.equal(hallazgo.resultado, 'aviso');
    assert.equal(hallazgo.severidad, 'media');
  });

  it('detecta un JWT de service role sin copiar el valor', () => {
    const hallazgo = evaluarSecretos({ VITE_SUPABASE_SERVICE_ROLE_KEY: SERVICE, VITE_SUPABASE_ANON_KEY: 'anon' });
    assert.equal(hallazgo.resultado, 'fallo');
    assert.deepEqual(hallazgo.detalle.claves, ['VITE_SUPABASE_SERVICE_ROLE_KEY']);
    assert.equal(JSON.stringify(hallazgo).includes(SERVICE), false);
  });

  it('acepta el cliente solo con la anon key', () => {
    const hallazgo = evaluarSecretos({ VITE_SUPABASE_URL: 'http://127.0.0.1:54321', VITE_SUPABASE_ANON_KEY: 'anon' });
    assert.equal(hallazgo.resultado, 'ok');
  });
});
