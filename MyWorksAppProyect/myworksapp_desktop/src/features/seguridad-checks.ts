export interface Hallazgo {
  resultado: 'ok' | 'aviso' | 'fallo';
  severidad: 'baja' | 'media' | 'alta';
  resumen: string;
  recomendacion: string;
  detalle: Record<string, unknown>;
}

const SECRETO = /SERVICE_ROLE|SECRET|PRIVATE_KEY|SB_SECRET/i;

export function evaluarCors(allowOrigin: string | null, status: number): Hallazgo {
  if (status === 0) {
    return {
      resultado: 'aviso',
      severidad: 'baja',
      resumen: 'No se pudo leer la respuesta CORS desde esta ventana.',
      recomendacion: 'Revisa el origen permitido en el gateway cuando la consola apunte a un dominio real.',
      detalle: { status },
    };
  }
  if (allowOrigin === '*') {
    return {
      resultado: 'aviso',
      severidad: 'media',
      resumen: 'El origen permitido es un comodín.',
      recomendacion: 'En producción limita Access-Control-Allow-Origin al dominio de la consola y de la app.',
      detalle: { allowOrigin, status },
    };
  }
  return {
    resultado: 'ok',
    severidad: 'baja',
    resumen: allowOrigin ? `CORS responde con ${allowOrigin}.` : 'La respuesta no trae Access-Control-Allow-Origin.',
    recomendacion: 'Confirma que ese origen es el de la consola y no un sitio de terceros.',
    detalle: { allowOrigin, status },
  };
}

/** No devuelve valores. Solo nombres de variables y si el valor parece un JWT de service role. */
export function evaluarSecretos(env: Record<string, string | undefined>): Hallazgo {
  const nombres = Object.keys(env).filter((key) => SECRETO.test(key));
  const serviceRole = Object.entries(env).filter(([, value]) => pareceServiceRole(value)).map(([key]) => key);
  if (serviceRole.length > 0) {
    return {
      resultado: 'fallo',
      severidad: 'alta',
      resumen: 'Hay una variable del cliente que parece la service role.',
      recomendacion: 'Sácala del frontend. Las Edge Functions la leen solo en el servidor.',
      detalle: { claves: serviceRole },
    };
  }
  if (nombres.length > 0) {
    return {
      resultado: 'aviso',
      severidad: 'media',
      resumen: 'Hay nombres de entorno sensibles en el bundle del cliente.',
      recomendacion: 'Revisa que el valor no sea un secreto. La anon key puede estar; la service role no.',
      detalle: { claves: nombres },
    };
  }
  return {
    resultado: 'ok',
    severidad: 'baja',
    resumen: 'El cliente no expone nombres de service role ni de secretos.',
    recomendacion: 'Mantén VITE_ solo para la URL y la anon key.',
    detalle: { claves: [] },
  };
}

function pareceServiceRole(value: string | undefined): boolean {
  if (!value || value.split('.').length !== 3) return false;
  try {
    const body = value.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = body + '='.repeat((4 - (body.length % 4)) % 4);
    const payload = JSON.parse(atob(padded));
    return payload?.role === 'service_role';
  } catch {
    return false;
  }
}
