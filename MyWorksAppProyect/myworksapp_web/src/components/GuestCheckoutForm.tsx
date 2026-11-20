import { useEffect, useRef, useState, type FormEvent } from 'react';
import { Lock, MapPin, Phone, User, Mail, X, ExternalLink } from 'lucide-react';
import { reservedEmailMessage } from '@myworksapp/shared';
import { TurnstileWidget } from './TurnstileWidget';
import { turnstileCanRender } from './turnstileSite';
import { useDialogA11y } from '../hooks/useDialogA11y';
import { AcademicInlineNote } from './AcademicInlineNote';
import { chileE164 } from '../chilePhone';

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
  /** Total del servidor. Null: aún no se puede pagar ni se muestra otro monto. */
  payableTotalClp?: number | null;
  quoteError?: string | null;
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
  payableTotalClp = null,
  quoteError = null,
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
  const totalAmount = payableTotalClp != null && payableTotalClp > 0
    ? payableTotalClp
    : null;
  const previewRef = useRef(onPreviewAddress);
  const dialogRef = useRef<HTMLDivElement>(null);
  previewRef.current = onPreviewAddress;
  useDialogA11y(true, onClose, dialogRef);

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
    const phoneE164 = chileE164(phone);
    if (!phoneE164) {
      setError('Usa un teléfono de Chile: +56 y 9 dígitos.');
      return;
    }
    const reserved = reservedEmailMessage(email);
    if (reserved) {
      setError(reserved);
      return;
    }
    if (turnstileCanRender() && !captchaToken) {
      setError('Confirma que no eres un robot');
      return;
    }
    setBusy(true);
    try {
      await onSubmit({
        name: name.trim(),
        email: email.trim(),
        phone: phoneE164,
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
      <div className="checkout-card-v2 guest-checkout-card modal-rise" ref={dialogRef}>
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
            o el pin del mapa fijan el traslado: se cobra el punto que ves en
            el total.
          </p>
        </div>

        <div className="checkout-v2-total-row">
          <span>
            {profession} · {workerName}
          </span>
          <strong>
            {totalAmount == null
              ? 'Calculando tarifa y traslado…'
              : `${totalAmount.toLocaleString('es-CL')} CLP`}
            {locatingAddress ? ' · buscando dirección…' : ''}
          </strong>
        </div>
        <p className="guest-checkout-service">
          {serviceDescription}
          {payableTotalClp == null
            ? ''
            : ' · Traslado incluido en el total'}
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

          {quoteError ? (
            <p className="toast-error" role="alert">{quoteError}</p>
          ) : null}
          {error ? (
            <p className="toast-error" role="alert">
              {error}
            </p>
          ) : null}

          <AcademicInlineNote />
          <button
            type="submit"
            className="btn-primary checkout-v2-pay"
            disabled={busy || totalAmount == null}
          >
            <ExternalLink size={16} />
            {busy
              ? 'Creando pedido y abriendo Webpay…'
              : totalAmount == null
                ? 'Calculando el total…'
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
