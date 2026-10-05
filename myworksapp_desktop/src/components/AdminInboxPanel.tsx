import { useQuery } from '@tanstack/react-query';
import { fetchMyNotifications } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export function AdminInboxPanel({
  userId,
  onClose,
}: {
  userId: string;
  onClose: () => void;
}) {
  const query = useQuery({
    queryKey: ['admin-notifications', userId],
    queryFn: () => fetchMyNotifications(supabase, userId),
  });

  return (
    <div
      role="presentation"
      onClick={onClose}
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(8, 16, 32, 0.55)',
        display: 'grid',
        placeItems: 'center',
        zIndex: 40,
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="admin-inbox-title"
        onClick={(event) => event.stopPropagation()}
        style={{
          background: '#0B1F3A',
          color: '#fff',
          padding: 24,
          borderRadius: 16,
          width: 'min(480px, calc(100% - 32px))',
          maxHeight: '70vh',
          overflow: 'auto',
        }}
      >
        <h2 id="admin-inbox-title" style={{ margin: '0 0 12px' }}>Notificaciones</h2>
        {query.isPending && <p>Cargando…</p>}
        {query.isError && <p>No se pudieron leer las notificaciones de esta cuenta.</p>}
        {query.data && query.data.length === 0 && <p>No hay notificaciones para esta cuenta.</p>}
        <ul style={{ listStyle: 'none', padding: 0, margin: 0, display: 'grid', gap: 12 }}>
          {query.data?.map((item) => (
            <li key={item.id}>
              <strong>{item.title}</strong>
              <div>{item.body}</div>
              <small>{item.read ? 'Leída' : 'Sin leer'}</small>
            </li>
          ))}
        </ul>
        <button type="button" className="sidebar-logout-btn" onClick={onClose} style={{ marginTop: 16 }}>
          Cerrar
        </button>
      </div>
    </div>
  );
}
