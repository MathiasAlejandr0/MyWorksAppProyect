import { useState } from 'react';
import {
  ShieldCheck,
  Lock,
  Mail,
  Monitor,
  BarChart3,
  Users,
  Eye,
  EyeOff,
  UserCircle,
  Shield,
  BadgeCheck,
  LogIn,
} from 'lucide-react';
import { AuthError, useAuth } from '../context/AuthContext';

type LoginRole = 'admin' | 'support';

export function DesktopLoginScreen() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<LoginRole>('admin');
  const [showPassword, setShowPassword] = useState(false);
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
    <div className="login-screen">
      <aside className="login-brand-panel">
        <div className="login-brand-map" aria-hidden />
        <div className="login-brand-content">
          <div className="login-brand-logo">
            <div className="login-brand-logo-icon">
              <img src="/brand/mark.svg" alt="" width={28} height={28} />
            </div>
            <div>
              <span className="login-brand-name">My Works App</span>
              <span className="login-brand-kicker">Consola</span>
            </div>
          </div>

          <div className="login-hero-icon">
            <Monitor size={34} />
          </div>
          <h1 className="login-hero-title">Consola operativa</h1>
          <p className="login-hero-tagline">Supervisa. Gestiona. Resuelve.</p>

          <ul className="login-feature-list">
            <li className="login-feature-item">
              <span className="login-feature-icon"><ShieldCheck size={18} /></span>
              Seguridad empresarial
            </li>
            <li className="login-feature-item">
              <span className="login-feature-icon"><BarChart3 size={18} /></span>
              Visibilidad en tiempo real
            </li>
            <li className="login-feature-item">
              <span className="login-feature-icon"><Users size={18} /></span>
              Control de acceso basado en roles
            </li>
          </ul>
        </div>
      </aside>

      <section className="login-form-panel">
        <div className="login-form-card">
          <p className="login-form-kicker">— ACCESO A CONSOLA —</p>
          <h2 className="login-form-title">Inicia sesión para continuar</h2>
          <p className="login-form-subtitle">
            Ingresa tus credenciales para acceder a la consola operativa.
          </p>

          <form onSubmit={handleSubmit}>
            <label className="login-field-label" htmlFor="login-email">
              CORREO ELECTRÓNICO
            </label>
            <div className="login-field-wrap">
              <Mail size={16} className="login-field-icon" />
              <input
                id="login-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="username"
                placeholder="tu.correo@myworksapp.com"
                className="login-input"
                required
              />
            </div>

            <label className="login-field-label" htmlFor="login-password">
              CONTRASEÑA
            </label>
            <div className="login-field-wrap">
              <Lock size={16} className="login-field-icon" />
              <input
                id="login-password"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
                placeholder="Ingresa tu contraseña"
                className="login-input login-input-password"
                required
              />
              <button
                type="button"
                className="login-eye-btn"
                onClick={() => setShowPassword((v) => !v)}
                aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
              >
                {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>

            <label className="login-field-label">SELECCIONA TU ROL</label>
            <div className="login-role-grid">
              <button
                type="button"
                className={`login-role-card${role === 'admin' ? ' active' : ''}`}
                onClick={() => setRole('admin')}
              >
                <UserCircle size={22} />
                <span className="login-role-title">Administrador</span>
                <span className="login-role-desc">Acceso completo a la consola</span>
              </button>
              <button
                type="button"
                className={`login-role-card${role === 'support' ? ' active' : ''}`}
                onClick={() => setRole('support')}
              >
                <Shield size={22} />
                <span className="login-role-title">Soporte</span>
                <span className="login-role-desc">Acceso limitado a incidentes.</span>
              </button>
            </div>

            {error && <p className="login-error">{error}</p>}

            <button type="submit" className="login-submit" disabled={submitting}>
              <LogIn size={18} />
              {submitting ? 'Validando…' : 'Entrar'}
            </button>
          </form>

          <p className="login-forgot">
            ¿Olvidaste tu contraseña? <a href="#">Recupérala aquí</a>
          </p>

          <div className="login-security-footer">
            <p className="login-security-title">SEGURIDAD EMPRESARIAL</p>
            <div className="login-security-grid">
              <div className="login-security-item">
                <Lock size={16} />
                <span>Conexión cifrada TLS 1.3</span>
              </div>
              <div className="login-security-item">
                <ShieldCheck size={16} />
                <span>Autenticación de múltiples factores</span>
              </div>
              <div className="login-security-item">
                <BadgeCheck size={16} />
                <span>Sesión protegida</span>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
