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
      text: `Hola, soy ${workerName}. Recibí tu solicitud. ¿En qué parte del domicilio necesitas la atención?`,
      timestamp: '14:30',
    },
  ]);
  const [inputText, setInputText] = useState('');

  const quickReplies = [
    'Estoy en la dirección indicada',
    '¿A qué hora estimas llegar?',
    'Necesito cotización adicional',
    'Perfecto, quedo atento',
  ];

  const sendMessage = (text: string) => {
    if (!text.trim()) return;
    const newMsg: Message = {
      id: Date.now().toString(),
      sender: 'user',
      text,
      timestamp: new Date().toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages((prev) => [...prev, newMsg]);
    setInputText('');

    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        {
          id: (Date.now() + 1).toString(),
          sender: 'worker',
          text: 'Gracias. En la app real el profesional confirmaría horario y detalles por aquí.',
          timestamp: new Date().toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' }),
        },
      ]);
    }, 1200);
  };

  return (
    <div className="chat-widget modal-rise">
      <div className="chat-widget-header">
        <div className="chat-widget-user">
          <img src={workerPhoto} alt="" />
          <div>
            <strong>{workerName}</strong>
            <span className="chat-widget-online">
              <span className="chat-online-dot" /> En línea
            </span>
          </div>
        </div>
        <button type="button" onClick={onClose} className="chat-widget-close" aria-label="Cerrar chat">
          <X size={18} />
        </button>
      </div>

      <div className="chat-widget-body">
        {messages.map((m) => (
          <div key={m.id} className={`chat-bubble-row chat-bubble-row--${m.sender}`}>
            <div className={`chat-bubble chat-bubble--${m.sender}`}>{m.text}</div>
            <div className="chat-bubble-meta">
              {m.timestamp}
              {m.sender === 'user' && <CheckCheck size={12} color="var(--orange-accent)" />}
            </div>
          </div>
        ))}
      </div>

      <div className="chat-widget-quick">
        {quickReplies.map((qr) => (
          <button key={qr} type="button" onClick={() => sendMessage(qr)} className="chat-quick-btn">
            {qr}
          </button>
        ))}
      </div>

      <div className="chat-widget-input">
        <input
          type="text"
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && sendMessage(inputText)}
          placeholder="Escribe un mensaje..."
        />
        <button type="button" onClick={() => sendMessage(inputText)} className="chat-send-btn" aria-label="Enviar">
          <Send size={16} />
        </button>
      </div>
    </div>
  );
}
