import { useEffect, useState } from 'react';
import { Send, X } from 'lucide-react';
import {
  fetchJobMessages,
  formatDbDateTime,
  sendJobMessage,
  type JobMessage,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface LiveChatWidgetProps {
  workerName: string;
  workerPhoto: string;
  jobId: string | null;
  senderId: string | null;
  receiverId: string | null;
  onClose: () => void;
}

export function LiveChatWidget({
  workerName,
  workerPhoto,
  jobId,
  senderId,
  receiverId,
  onClose,
}: LiveChatWidgetProps) {
  const canSend = Boolean(jobId && senderId && receiverId);
  const [messages, setMessages] = useState<JobMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(canSend);
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    if (!jobId || !senderId) {
      setLoading(false);
      return;
    }
    let cancelled = false;
    setLoading(true);
    void fetchJobMessages(supabase, jobId)
      .then((rows) => {
        if (!cancelled) {
          setMessages(rows);
          setError(null);
        }
      })
      .catch(() => {
        if (!cancelled) setError('No se pudieron cargar los mensajes.');
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    const channel = supabase
      .channel(`mensajes-${jobId}`)
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'mensajes', filter: `id_trabajo=eq.${jobId}` },
        () => {
          void fetchJobMessages(supabase, jobId)
            .then((rows) => {
              if (!cancelled) setMessages(rows);
            })
            .catch(() => undefined);
        },
      )
      .subscribe();

    const poll = window.setInterval(() => {
      void fetchJobMessages(supabase, jobId)
        .then((rows) => {
          if (!cancelled) setMessages(rows);
        })
        .catch(() => undefined);
    }, 12000);

    return () => {
      cancelled = true;
      window.clearInterval(poll);
      void supabase.removeChannel(channel);
    };
  }, [jobId, senderId]);

  const sendMessage = async (text: string) => {
    if (!canSend || !jobId || !senderId || !receiverId) return;
    const content = text.trim();
    if (!content || sending) return;
    setSending(true);
    setError(null);
    try {
      await sendJobMessage(supabase, {
        id: crypto.randomUUID(),
        jobId,
        senderId,
        receiverId,
        content,
      });
      setInputText('');
      const rows = await fetchJobMessages(supabase, jobId);
      setMessages(rows);
    } catch {
      setError('No se envió. Inicia sesión con la cuenta del pedido.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="chat-widget modal-rise">
      <div className="chat-widget-header">
        <div className="chat-widget-user">
          <img src={workerPhoto} alt="" />
          <div>
            <strong>{workerName}</strong>
            <span className="chat-widget-online">
              {canSend ? 'Llega al profesional de este trabajo' : 'Inicia sesión para escribir'}
            </span>
          </div>
        </div>
        <button type="button" onClick={onClose} className="chat-widget-close" aria-label="Cerrar chat">
          <X size={18} />
        </button>
      </div>

      <div className="chat-widget-body">
        {loading && <p>Cargando mensajes…</p>}
        {!loading && messages.length === 0 && (
          <p>
            {canSend
              ? 'Todavía no hay mensajes en este trabajo.'
              : 'El chat del sitio guarda mensajes en el pedido. Entra con tu cuenta de cliente para escribirle al profesional.'}
          </p>
        )}
        {messages.map((message) => {
          const mine = message.senderId === senderId;
          return (
            <div key={message.id} className={`chat-bubble-row chat-bubble-row--${mine ? 'user' : 'worker'}`}>
              <div className={`chat-bubble chat-bubble--${mine ? 'user' : 'worker'}`}>{message.content}</div>
              <div className="chat-bubble-meta">
                {formatDbDateTime(message.createdAt)}
              </div>
            </div>
          );
        })}
        {error && <p role="alert">{error}</p>}
      </div>

      <div className="chat-widget-input">
        <input
          type="text"
          value={inputText}
          disabled={!canSend || sending}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') void sendMessage(inputText);
          }}
          placeholder={canSend ? 'Escribe un mensaje...' : 'Disponible al iniciar sesión'}
          maxLength={2000}
        />
        <button
          type="button"
          onClick={() => void sendMessage(inputText)}
          className="chat-send-btn"
          aria-label="Enviar"
          disabled={!canSend || sending}
        >
          <Send size={16} />
        </button>
      </div>
    </div>
  );
}
