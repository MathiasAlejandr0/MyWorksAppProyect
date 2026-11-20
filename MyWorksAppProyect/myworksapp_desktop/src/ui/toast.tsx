import { useCallback, useMemo, useState, type ReactNode } from 'react';
import { ToastContext } from './toast-store';

interface ToastItem {
  id: number;
  text: string;
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const push = useCallback((text: string) => {
    const id = Date.now() + Math.floor(performance.now());
    setItems((current) => [...current, { id, text }]);
    window.setTimeout(() => {
      setItems((current) => current.filter((item) => item.id !== id));
    }, 4200);
  }, []);
  const value = useMemo(() => push, [push]);
  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="toast-region" aria-live="polite">
        {items.map((item) => (
          <div className="toast" key={item.id} role="status">{item.text}</div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

