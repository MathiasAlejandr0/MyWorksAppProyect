import { useState } from 'react';
import { Send, CheckCheck, X } from 'lucide-react';

interface Message {
  id: string;
  sender: 'user' | 'worker';
  text: string;
  timestamp: string;
}

interface LiveChatWidgetProps {
  workerName: string;
  workerPhoto: string;
  onClose: () => void;
}

export function LiveChatWidget({ workerName, workerPhoto, onClose }: LiveChatWidgetProps) {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'm1',
      sender: 'worker',
      text: `¡Hola! Soy ${workerName}. Ya recibí la notificación de tu solicitud. ¿En qué lugar específico necesitas la atención?`,
      timestamp: '14:30',
    },
  ]);
  const [inputText, setInputText] = useState('');

  const quickReplies = [
    '📍 Estoy en la dirección indicada',
    '⏰ ¿A qué hora estimas llegar?',
    '🔧 Necesito cotización adicional de materiales',
    '👍 Perfecto, quedo atento',
  ];

  const sendMessage = (text: string) => {
    if (!text.trim()) return;
    const newMsg: Message = {
      id: Date.now().toString(),
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages(prev => [...prev, newMsg]);
    setInputText('');

    // Simular respuesta del profesional tras 1.2 segundos
    setTimeout(() => {
      const replyMsg: Message = {
        id: (Date.now() + 1).toString(),
        sender: 'worker',
        text: 'Entendido. Voy saliendo hacia tu dirección ahora mismo con todo mi equipo técnico.',
        timestamp: new Date().toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages(prev => [...prev, replyMsg]);
    }, 1200);
  };

  return (
    <div style={{ position: 'fixed', bottom: '24px', right: '24px', zIndex: 250, width: '380px', height: '520px', backgroundColor: 'var(--bg-surface-light)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-md)', border: '1px solid var(--border-light)', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {/* Header Chat */}
      <div style={{ padding: '14px 18px', backgroundColor: 'var(--navy-structure)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <img src={workerPhoto} alt={workerName} style={{ width: '36px', height: '36px', borderRadius: '50%', objectFit: 'cover' }} />
          <div>
            <div style={{ fontSize: '14px', fontWeight: 800 }}>{workerName}</div>
            <div style={{ fontSize: '11px', color: '#34C759', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <span style={{ width: '6px', height: '6px', backgroundColor: '#34C759', borderRadius: '50%' }} />
              En línea ahora
            </div>
          </div>
        </div>

        <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer' }}>
          <X size={18} />
        </button>
      </div>

      {/* Cuerpo Mensajes */}
      <div style={{ flex: 1, padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px', backgroundColor: 'var(--bg-elevated-light)' }}>
        {messages.map(m => (
          <div key={m.id} style={{ alignSelf: m.sender === 'user' ? 'flex-end' : 'flex-start', maxWidth: '80%' }}>
            <div style={{ padding: '10px 14px', borderRadius: '16px', backgroundColor: m.sender === 'user' ? '#F0782A' : 'white', color: m.sender === 'user' ? 'white' : 'var(--text-main-light)', boxShadow: '0 2px 6px rgba(0,0,0,0.05)', fontSize: '13px', lineHeight: 1.4 }}>
              {m.text}
            </div>
            <div style={{ fontSize: '10px', color: 'var(--text-muted-light)', marginTop: '2px', textAlign: m.sender === 'user' ? 'right' : 'left' }}>
              {m.timestamp} {m.sender === 'user' && <CheckCheck size={12} color="#F0782A" style={{ display: 'inline', marginLeft: '4px' }} />}
            </div>
          </div>
        ))}
      </div>

      {/* Respuestas Rápidas IA */}
      <div style={{ padding: '8px 12px', backgroundColor: 'white', borderTop: '1px solid var(--border-light)', display: 'flex', gap: '6px', overflowX: 'auto' }}>
        {quickReplies.map((qr, idx) => (
          <button 
            key={idx}
            onClick={() => sendMessage(qr)}
            style={{ padding: '4px 10px', backgroundColor: 'var(--orange-soft)', color: '#F0782A', border: 'none', borderRadius: '12px', fontSize: '11px', fontWeight: 600, whiteSpace: 'nowrap', cursor: 'pointer' }}
          >
            {qr}
          </button>
        ))}
      </div>

      {/* Input de Texto */}
      <div style={{ padding: '12px', backgroundColor: 'white', display: 'flex', gap: '8px', alignItems: 'center' }}>
        <input 
          type="text" 
          value={inputText}
          onChange={e => setInputText(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && sendMessage(inputText)}
          placeholder="Escribe un mensaje..."
          style={{ flex: 1, padding: '10px 14px', borderRadius: 'var(--radius-pill)', border: '1px solid var(--border-light)', fontSize: '13px', outline: 'none' }}
        />
        <button 
          onClick={() => sendMessage(inputText)}
          style={{ width: '36px', height: '36px', borderRadius: '50%', backgroundColor: '#F0782A', color: 'white', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
        >
          <Send size={16} />
        </button>
      </div>
    </div>
  );
}
