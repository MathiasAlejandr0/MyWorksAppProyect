import { useEffect, useState } from 'react';
import { ShieldCheck } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../supabaseClient';

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
      // Un QR abandonado deja un factor sin verificar con el mismo nombre y el
      // siguiente enroll falla. Se borra antes de pedir un QR nuevo.
      const pending = listed.data.all.filter(
        (factor) => factor.factor_type === 'totp' && factor.status !== 'verified',
      );
      for (const factor of pending) {
        const removed = await supabase.auth.mfa.unenroll({ factorId: factor.id });
        if (cancelled) return;
        if (removed.error) {
          setError('No se pudo preparar la aplicación de autenticación.');
          return;
        }
      }
      const enrolled = await supabase.auth.mfa.enroll({
        factorType: 'totp',
        friendlyName: 'Consola administrador',
      });
      if (cancelled) return;
      if (enrolled.error || !enrolled.data) {
        setError('No se pudo preparar la aplicación de autenticación.');
        return;
      }
      setFactorId(enrolled.data.id);
      setQr(enrolled.data.totp.qr_code);
    };
    void prepare();
    return () => {
      cancelled = true;
    };
  }, []);

  const confirm = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!factorId || code.trim().length < 6) return;
    setBusy(true);
    setError(null);
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
  };

  return (
    <div className="login-screen">
      <form className="login-card" onSubmit={(event) => void confirm(event)}>
        <p className="login-security-title">
          <ShieldCheck size={16} /> Segundo factor
        </p>
        <h1>Confirma que eres el administrador</h1>
        <p>
          {qr
            ? 'Escanea el código con tu aplicación de autenticación y escribe el código de 6 dígitos.'
            : 'Escribe el código de 6 dígitos de tu aplicación de autenticación.'}
        </p>
        {qr ? (
          <img src={qr} alt="Código QR para activar el segundo factor" width={180} height={180} />
        ) : null}
        <label className="login-field-label" htmlFor="mfa-code">
          CÓDIGO
        </label>
        <input
          id="mfa-code"
          className="login-input"
          inputMode="numeric"
          autoComplete="one-time-code"
          value={code}
          onChange={(event) => setCode(event.target.value)}
          required
        />
        {error ? <p className="login-error">{error}</p> : null}
        <button type="submit" className="login-submit" disabled={busy || !factorId}>
          {busy ? 'Verificando…' : 'Entrar'}
        </button>
        <button type="button" className="btn-ghost" onClick={() => void logout()}>
          Cerrar sesión
        </button>
      </form>
    </div>
  );
}
