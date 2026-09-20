import { useState, type FormEvent } from 'react';
import { Lock, MapPin, Phone, User, Mail, X, ExternalLink } from 'lucide-react';

export type GuestCheckoutPayload = {
  name: string;
  email: string;
  phone: string;
  address: string;
};

interface GuestCheckoutFormProps {
  workerName: string;
  profession: string;
  basePrice: number;
  serviceDescription?: string;
  onClose: () => void;
  onSubmit: (data: GuestCheckoutPayload) => Promise<void>;
  onPreferLogin: () => void;
}

export function GuestCheckoutForm({
  workerName,
  profession,
  basePrice,
  serviceDescription = 'Visita / urgencia a domicilio',
  onClose,
  onSubmit,
  onPreferLogin,
}: GuestCheckoutFormProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!name.trim() || !email.trim() || !phone.trim() || !address.trim()) {
      setError('Completa tus datos personales y la dirección del trabajo.');
      return;
    }
    setBusy(true);
    try {
      await onSubmit({
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
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
            <Lock size={13} /> PEDIDO SIN SESIÓN · URGENCIA
          </p>
          <h2 id="guest-checkout-title">Datos para la visita</h2>
          <p className="guest-checkout-lead">
            Sin iniciar sesión puedes agendar. Pediremos tus datos y el pago se
            completa en Transbank (redirección).
          </p>
        </div>

        <div className="checkout-v2-total-row">
          <span>
            {profession} · {workerName}
          </span>
          <strong>{basePrice.toLocaleString('es-CL')} CLP</strong>
        </div>
        <p className="guest-checkout-service">{serviceDescription}</p>

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

          {error ? (
            <p className="toast-error" role="alert">
              {error}
            </p>
          ) : null}

          <button type="submit" className="btn-primary checkout-v2-pay" disabled={busy}>
            <ExternalLink size={16} />
            {busy
              ? 'Creando pedido y abriendo Webpay…'
              : `Continuar a Webpay · CLP ${basePrice.toLocaleString('es-CL')}`}
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
