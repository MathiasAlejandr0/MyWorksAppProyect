import { useEffect, useState } from 'react';
import { isTauriRuntime } from '../lib/redirect';

/** Avisa si GitHub Releases publicó una versión más nueva. */
export function DesktopUpdateNotice() {
  const [version, setVersion] = useState<string | null>(null);
  const [install, setInstall] = useState<(() => Promise<void>) | null>(null);
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!isTauriRuntime()) return;
    let cancelled = false;
    void import('@tauri-apps/plugin-updater').then(async ({ check }) => {
      try {
        const update = await check();
        if (cancelled || !update) return;
        setVersion(update.version);
        setInstall(() => () => update.downloadAndInstall());
      } catch {
        // Sin feed publicado la consola sigue usable.
      }
    }).catch(() => {});
    return () => {
      cancelled = true;
    };
  }, []);

  if (!version) return null;
  return (
    <p className="warn-banner update-banner" role="status">
      Hay una versión nueva ({version}).
      {message ? ` ${message}` : ' Puedes descargarla ahora y abrir la app de nuevo al terminar.'}
      {install ? (
        <>
          {' '}
          <button
            type="button"
            className="btn btn-secondary"
            disabled={busy}
            onClick={() => {
              setBusy(true);
              setMessage(null);
              void install()
                .then(() => setMessage('Actualización descargada. Cierra la app y ábrela de nuevo.'))
                .catch(() => setMessage('No se pudo descargar la actualización.'))
                .finally(() => setBusy(false));
            }}
          >
            {busy ? 'Descargando…' : 'Descargar e instalar'}
          </button>
        </>
      ) : null}
    </p>
  );
}
