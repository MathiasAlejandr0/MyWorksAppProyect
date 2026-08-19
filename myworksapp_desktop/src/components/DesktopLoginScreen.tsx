import { useState } from 'react';
import { ShieldCheck, Lock, Mail, Home, Wrench } from 'lucide-react';
import { AuthError, useAuth } from '../context/AuthContext';

export function DesktopLoginScreen() {
  const { login } = useAuth();
  const [email, setEmail] = useState('admin@demo.com');
  const [password, setPassword] = useState('demo123');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await login(email, password);
    } catch (e) {
      setError(e instanceof AuthError ? e.message : 'No se pudo iniciar sesión.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', width: '100vw', backgroundColor: '#090D16', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px', fontFamily: 'sans-serif' }}>
      <div style={{ maxWidth: '440px', width: '100%', backgroundColor: '#121826', border: '1px solid #1E2A3B', borderRadius: '24px', padding: '36px', boxShadow: '0 25px 60px rgba(0,0,0,0.6)', color: 'white' }}>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '28px' }}>
          <div style={{ position: 'relative', width: '56px', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '12px' }}>
            <Home size={50} color="#FFFFFF" />
            <div style={{ position: 'absolute', bottom: '2px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Wrench size={20} color="#F0782A" />
            </div>
          </div>
          <h1 style={{ fontSize: '22px', fontWeight: 900, color: 'white', letterSpacing: '0.2px' }}>My Works App</h1>
          <span style={{ fontSize: '11px', color: '#F0782A', fontWeight: 800, backgroundColor: 'rgba(240,120,42,0.15)', padding: '3px 10px', borderRadius: '12px', marginTop: '4px' }}>ENTERPRISE MANAGEMENT HUB</span>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '6px', display: 'block' }}>Email corporativo (rol admin)</label>
            <div style={{ position: 'relative' }}>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ width: '100%', padding: '12px 14px 12px 40px', borderRadius: '10px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }}
                required
              />
              <Mail size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: '#98989D' }} />
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '6px', display: 'block' }}>Contraseña</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ width: '100%', padding: '12px 14px 12px 40px', borderRadius: '10px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }}
                required
              />
              <Lock size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: '#98989D' }} />
            </div>
          </div>

          {error && (
            <div style={{ color: '#FF3B30', fontSize: '13px', fontWeight: 700 }}>{error}</div>
          )}

          <button
            type="submit"
            disabled={submitting}
            style={{ marginTop: '8px', padding: '14px', borderRadius: '9999px', border: 'none', background: 'linear-gradient(135deg, #FF6B00, #F0782A)', color: 'white', fontWeight: 800, fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', boxShadow: '0 4px 15px rgba(240, 120, 42, 0.4)' }}
          >
            <ShieldCheck size={18} /> {submitting ? 'Validando...' : 'Iniciar sesión con Supabase'}
          </button>
        </form>

        <div style={{ marginTop: '24px', textAlign: 'center', fontSize: '11.5px', color: '#98989D' }}>
          Solo cuentas con rol <strong>admin</strong> en Supabase pueden acceder al hub.
        </div>
      </div>
    </div>
  );
}
