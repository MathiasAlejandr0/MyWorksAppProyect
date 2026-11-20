import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { getSavedCard, passwordPolicyMessage, removeSavedCard, updateAccountPassword } from '@myworksapp/shared';
import { SiteFooter } from '../components/SiteFooter';
import { usePageMeta } from '../hooks/usePageMeta';
import { useAuth } from '../context/useAuth';
import { chileE164 } from '../chilePhone';
import { supabase } from '../supabaseClient';

type Address = { id: string; etiqueta: string; direccion: string };

type Loose = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: string) => Promise<{ data: Address[] | null; error: { message: string } | null }>;
    };
    insert: (row: Record<string, string>) => Promise<{ error: { message: string } | null }>;
    delete: () => { eq: (column: string, value: string) => Promise<{ error: { message: string } | null }> };
    update: (row: Record<string, string | null>) => {
      eq: (column: string, value: string) => Promise<{ error: { message: string } | null }>;
    };
  };
  rpc: (fn: string) => Promise<{ data: unknown; error: { message: string } | null }>;
};

export function AccountPage() {
  const { profile } = useAuth();
  const [name, setName] = useState(profile?.name ?? '');
  const [phone, setPhone] = useState('');
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [label, setLabel] = useState('');
  const [line, setLine] = useState('');
  const [card, setCard] = useState<string | null>(null);
  const [password, setPassword] = useState('');
  const [note, setNote] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  usePageMeta('Mi cuenta', 'Datos de tu cuenta de cliente en MyWorksApp.', true);

  useEffect(() => {
    if (!profile) return;
    const db = supabase as unknown as Loose;
    void db.from('direcciones_cliente').select('id, etiqueta, direccion').eq('id_usuario', profile.id)
      .then(({ data }) => setAddresses(data ?? []));
    void db.from('perfiles').select('telefono').eq('id', profile.id).then(({ data }) => {
      const row = (data ?? [])[0] as { telefono?: string } | undefined;
      if (row?.telefono) setPhone(row.telefono);
    });
    void getSavedCard(supabase).then((saved) => {
      setCard(saved.enrolled ? `Tarjeta •••• ${saved.last4}` : null);
    }).catch(() => setCard(null));
  }, [profile]);

  if (!profile) {
    return (
      <div className="min-h-screen app-shell">
        <main className="container legal-page">
          <h1>Mi cuenta</h1>
          <p>Entra para ver tu nombre, tus direcciones y tus datos.</p>
          <Link to="/">Ir al inicio</Link>
        </main>
        <SiteFooter />
      </div>
    );
  }

  const saveProfile = async (event: FormEvent) => {
    event.preventDefault();
    setError(null);
    const db = supabase as unknown as Loose;
    const normalized = phone.trim() ? chileE164(phone) : null;
    if (phone.trim() && !normalized) {
      setError('El teléfono debe ser de Chile, con +56 y 9 dígitos.');
      return;
    }
    const { error: updateError } = await db.from('perfiles').update({
      nombre: name.trim(),
      telefono: normalized,
    }).eq('id', profile.id);
    setNote(updateError ? null : 'Guardamos tu ficha.');
    setError(updateError ? 'No se pudo guardar la ficha.' : null);
  };

  const addAddress = async (event: FormEvent) => {
    event.preventDefault();
    if (line.trim().length < 8) {
      setError('Escribe la calle y la ciudad.');
      return;
    }
    const db = supabase as unknown as Loose;
    const { error: insertError } = await db.from('direcciones_cliente').insert({
      id: crypto.randomUUID(),
      id_usuario: profile.id,
      etiqueta: label.trim(),
      direccion: line.trim(),
      creado_en: new Date().toISOString(),
    });
    if (insertError) {
      setError('No se pudo guardar la dirección.');
      return;
    }
    setLine('');
    setLabel('');
    const { data } = await db.from('direcciones_cliente').select('id, etiqueta, direccion').eq('id_usuario', profile.id);
    setAddresses(data ?? []);
  };

  const exportData = async () => {
    setError(null);
    const db = supabase as unknown as Loose;
    const { data, error: rpcError } = await db.rpc('exportar_mis_datos');
    if (rpcError || data == null) {
      setError('No se pudo exportar. Si la función aún no está en la base, falta aplicarla.');
      return;
    }
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'mis-datos-myworksapp.json';
    link.click();
    URL.revokeObjectURL(url);
  };

  const erase = async () => {
    setError(null);
    const db = supabase as unknown as Loose;
    const { error: rpcError } = await db.rpc('solicitar_eliminacion_cuenta');
    if (rpcError) {
      setError('No se pudo eliminar la cuenta. Si tienes un pedido abierto, ciérralo primero.');
      return;
    }
    setNote('La cuenta quedó marcada como eliminada. Cierra la sesión.');
  };

  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <h1>Mi cuenta</h1>
        <p>Correo: {profile.email || 'Sin dato'}</p>
        <form onSubmit={(event) => void saveProfile(event)}>
          <label>Nombre <input value={name} onChange={(event) => setName(event.target.value)} required /></label>
          <label>Teléfono <input value={phone} onChange={(event) => setPhone(event.target.value)} placeholder="+569…" /></label>
          <button type="submit" className="btn-primary">Guardar</button>
        </form>
        <h2>Direcciones guardadas</h2>
        {addresses.length === 0 ? <p>Todavía no guardas direcciones.</p> : (
          <ul>{addresses.map((item) => <li key={item.id}>{item.etiqueta ? `${item.etiqueta}: ` : ''}{item.direccion}</li>)}</ul>
        )}
        <form onSubmit={(event) => void addAddress(event)}>
          <input value={label} onChange={(event) => setLabel(event.target.value)} placeholder="Casa, oficina…" aria-label="Etiqueta" />
          <input value={line} onChange={(event) => setLine(event.target.value)} placeholder="Calle y ciudad" aria-label="Dirección" required />
          <button type="submit">Agregar dirección</button>
        </form>
        <h2>Contraseña</h2>
        <form onSubmit={(event) => {
          event.preventDefault();
          const policy = passwordPolicyMessage(password);
          if (policy) {
            setError(policy);
            return;
          }
          void updateAccountPassword(supabase, password).then(() => setNote('Contraseña actualizada.')).catch(() => setError('No se pudo cambiar la contraseña.'));
        }}>
          <input type="password" value={password} onChange={(event) => setPassword(event.target.value)} aria-label="Nueva contraseña" />
          <button type="submit">Cambiar contraseña</button>
        </form>
        <h2>Tarjeta guardada</h2>
        <p>{card ?? 'No hay una tarjeta inscrita.'}</p>
        {card ? (
          <button type="button" onClick={() => void removeSavedCard(supabase).then(() => setCard(null))}>Quitar tarjeta</button>
        ) : null}
        <h2>Tus datos</h2>
        <button type="button" onClick={() => void exportData()}>Exportar en JSON</button>
        <button type="button" onClick={() => void erase()}>Solicitar eliminación</button>
        {note ? <p role="status">{note}</p> : null}
        {error ? <p role="alert">{error}</p> : null}
        <Link to="/">Volver al inicio</Link>
      </main>
      <SiteFooter />
    </div>
  );
}
