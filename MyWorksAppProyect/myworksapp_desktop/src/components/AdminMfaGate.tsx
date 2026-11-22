import { useEffect, useState } from 'react';
import { useAuth } from '../context/auth-store';
import { supabase } from '../supabaseClient';
import { Button } from '../ui/kit';
import { makeScannableTotpQr } from '../lib/totpQr';

/** Segundo factor TOTP obligatorio para entrar a la consola. */
export function AdminMfaGate() {
  const { completeMfa, logout } = useAuth();
  const [factorId, setFactorId] = useState<string | null>(null);
  const [qr, setQr] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const prepare = async () => {
      const listed = await supabase.auth.mfa.listFactors();
      if (cancelled) return;
      if (listed.error) {
        setError('No se pudo revisar el segundo factor.');
        return;
      }
      const verified = listed.data.totp.find((factor) => factor.status === 'verified');
      if (verified) {
        setFactorId(verified.id);
        return;
      }
      const pending = listed.data.all.filter((factor) => factor.factor_type === 'totp' && factor.status !== 'verified');
      for (const factor of pending) {
        const removed = await supabase.auth.mfa.unenroll({ factorId: factor.id });
        if (cancelled) return;
        if (removed.error) {
          setError('No se pudo preparar la aplicación de autenticación.');
          return;
        }
      }
      const enrolled = await supabase.auth.mfa.enroll({ factorType: 'totp', friendlyName: 'Consola MyWorksApp' });
      if (cancelled) return;
      if (enrolled.error || !enrolled.data) {
        setError('No se pudo preparar la aplicación de autenticación.');
        return;
      }
      setFactorId(enrolled.data.id);
      const qrSrc = await makeScannableTotpQr(enrolled.data.totp);
      if (cancelled) return;
      setQr(qrSrc);
    };
    void prepare();
    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <div className="login-screen">
      <section className="login-panel">
        <form
          className="login-card stack"
          onSubmit={(event) => {
            event.preventDefault();
            if (!factorId || code.trim().length < 6) return;
            setBusy(true);
            setError(null);
            void (async () => {
              const challenge = await supabase.auth.mfa.challenge({ factorId });
              if (challenge.error || !challenge.data) {
                setBusy(false);
                setError('No se pudo iniciar la verificación.');
                return;
              }
              const verified = await supabase.auth.mfa.verify({
                factorId,
                challengeId: challenge.data.id,
                code: code.trim(),
              });
              setBusy(false);
              if (verified.error) {
                setError('El código no es válido.');
                return;
              }
              await completeMfa();
            })();
          }}
        >
          <h1>Segundo factor</h1>
          <p className="muted">La consola pide un código de tu aplicación de autenticación.</p>
          {qr ? <img className="totp-qr" src={qr} alt="Código QR para configurar el segundo factor" width={240} height={240} /> : null}
          <label className="field">
            <span>Código de 6 dígitos</span>
            <input inputMode="numeric" autoComplete="one-time-code" value={code} onChange={(event) => setCode(event.target.value)} />
          </label>
          {error ? <p role="alert">{error}</p> : null}
          <Button type="submit" busy={busy} disabled={!factorId}>Entrar</Button>
          <Button variant="secondary" onClick={() => void logout()}>Cerrar sesión</Button>
        </form>
      </section>
    </div>
  );
}
