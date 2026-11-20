import { useRef, useState } from 'react';
import { groupNoticesByJob, type AppNotification } from '@myworksapp/shared';
import { useDialogA11y } from '../hooks/useDialogA11y';

interface NotificationInboxProps {
  notices: AppNotification[];
  jobTitles?: Record<string, string>;
  onClose: () => void;
  onOpen: (notice: AppNotification) => void;
}

export function NotificationInbox({
  notices,
  jobTitles = {},
  onClose,
  onOpen,
}: NotificationInboxProps) {
  const folders = groupNoticesByJob(notices, jobTitles);
  const [openKey, setOpenKey] = useState<string | null>(folders[0]?.key ?? null);
  const dialogRef = useRef<HTMLDivElement>(null);
  useDialogA11y(true, onClose, dialogRef);

  return (
    <div className="notice-inbox" role="dialog" aria-modal="true" aria-label="Notificaciones" ref={dialogRef}>
      <div className="notice-inbox-head">
        <strong>Notificaciones</strong>
        <button type="button" onClick={onClose}>Cerrar</button>
      </div>
      {folders.length === 0 ? (
        <p>No tienes notificaciones.</p>
      ) : (
        folders.map((folder) => {
          const open = openKey === folder.key;
          return (
            <section key={folder.key} className="notice-folder">
              <button
                type="button"
                className="notice-folder-toggle"
                aria-expanded={open}
                onClick={() => setOpenKey(open ? null : folder.key)}
              >
                <span>{folder.title}</span>
                <small>
                  {folder.unreadCount > 0
                    ? `${folder.unreadCount} sin leer · ${folder.items.length}`
                    : `${folder.items.length} avisos`}
                </small>
              </button>
              {open ? (
                <ul>
                  {folder.items.map((notice) => (
                    <li key={notice.id}>
                      <button
                        type="button"
                        className={notice.read ? 'notice-read' : 'notice-unread'}
                        onClick={() => onOpen(notice)}
                      >
                        <strong>{notice.title}</strong>
                        <span>{notice.body}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              ) : null}
            </section>
          );
        })
      )}
    </div>
  );
}
