import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Lock, MapPin, Phone, User, Mail, X, ExternalLink } from 'lucide-react';
import { transportCheckoutCopy } from '@myworksapp/shared';
import { TurnstileWidget } from './TurnstileWidget';
import { turnstileSiteKey } from './turnstileSite';

export type GuestCheckoutPayload = {
  name: string;
  email: string;
  phone: string;
  address: string;
  turnstileToken?: string;
};

interface GuestCheckoutFormProps {
  workerName: string;
  profession: string;
  basePrice: number;
  transportExtraClp?: number;
  insideRadar?: boolean | null;
  serviceDescription?: string;
  onClose: () => void;
  onSubmit: (data: GuestCheckoutPayload) => Promise<void>;
  onPreferLogin: () => void;
  onPreviewAddress?: (query: string) => Promise<unknown>;
  locatingAddress?: boolean;
}

export function GuestCheckoutForm({
  workerName,
  profession,
  basePrice,
  transportExtraClp = 0,
  insideRadar = null,
  serviceDescription = 'Visita / urgencia a domicilio',
  onClose,
  onSubmit,
  onPreferLogin,
  onPreviewAddress,
  locatingAddress = false,
}: GuestCheckoutFormProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [captchaToken, setCaptchaToken] = useState('');
  const totalAmount = basePrice + Math.max(0, transportExtraClp);
  const previewRef = useRef(onPreviewAddress);
  previewRef.current = onPreviewAddress;

  useEffect(() => {
    const text = address.trim();
    if (text.length < 3 || !previewRef.current) return;
    const timer = window.setTimeout(() => {
      void previewRef.current?.(text);
    }, 700);
    return () => window.clearTimeout(timer);
  }, [address]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!name.trim() || !email.trim() || !phone.trim() || !address.trim()) {
      setError('Completa tus datos personales y la dirección del trabajo.');
      return;
    }
    if (turnstileSiteKey() && !captchaToken) {
      setError('Confirma que no eres un robot');
      return;
    }
    setBusy(true);
    try {
      await onSubmit({
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        turnstileToken: captchaToken || undefined,
      });
    } catch (err) {
      setError(
        err instanceof Error ? err.message : 'No se pudo iniciar el pedido.',
      );
      setBusy(false);
    }
  };

  return (
    <div
      className="checkout-backdrop modal-fade-in"
      role="dialog"
      aria-modal="true"
      aria-labelledby="guest-checkout-title"
    >
      <div className="checkout-card-v2 guest-checkout-card modal-rise">
        <button
          type="button"
          className="modal-close"
          onClick={onClose}
          aria-label="Cerrar"
        >
          <X size={20} />
        </button>

        <div className="checkout-v2-header">
          <p className="checkout-v2-kicker">
            <Lock size={13} /> Pedido sin sesión
          </p>
          <h2 id="guest-checkout-title">Datos para la visita</h2>
          <p className="guest-checkout-lead">
            Sin cuenta te enviamos a Webpay para pagar este pedido. La dirección
            de abajo fija el punto del trabajo y el extra de traslado.
          </p>
        </div>

        <div className="checkout-v2-total-row">
          <span>
            {profession} · {workerName}
          </span>
          <strong>
            {totalAmount.toLocaleString('es-CL')} CLP
            {locatingAddress ? ' · buscando dirección…' : ''}
          </strong>
        </div>
        <p className="guest-checkout-service">
          {serviceDescription}
          {` · ${transportCheckoutCopy({ extraClp: transportExtraClp, insideRadar })}`}
        </p>

        <form className="guest-checkout-form" onSubmit={(e) => void handleSubmit(e)}>
          <label>
            <span>
              <User size={14} /> Nombre completo
            </span>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              autoComplete="name"
              required
              disabled={busy}
            />
          </label>
          <label>
            <span>
              <Mail size={14} /> Correo
            </span>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="email"
              required
              disabled={busy}
            />
          </label>
          <label>
            <span>
              <Phone size={14} /> Teléfono
            </span>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              autoComplete="tel"
              placeholder="+56 9 …"
              required
              disabled={busy}
            />
          </label>
          <label>
            <span>
              <MapPin size={14} /> Dirección del trabajo
            </span>
            <input
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              autoComplete="street-address"
              placeholder="Calle, número, comuna"
              required
              disabled={busy}
            />
          </label>

          <TurnstileWidget onToken={setCaptchaToken} />

          {error ? (
            <p className="toast-error" role="alert">
              {error}
            </p>
          ) : null}

          <button type="submit" className="btn-primary checkout-v2-pay" disabled={busy}>
            <ExternalLink size={16} />
            {busy
              ? 'Creando pedido y abriendo Webpay…'
              : `Continuar a Webpay · CLP ${totalAmount.toLocaleString('es-CL')}`}
          </button>
        </form>

        <button
          type="button"
          className="guest-checkout-login-link"
          onClick={onPreferLogin}
          disabled={busy}
        >
          ¿Ya tienes cuenta? Inicia sesión y paga sin salir del sitio
        </button>
      </div>
    </div>
  );
}
