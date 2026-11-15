import { useEffect, useRef } from 'react';
import { TURNSTILE_SITE_KEY } from './turnstileSite';

const SITE_KEY = TURNSTILE_SITE_KEY;

type TurnstileApi = {
  render: (
    node: HTMLElement,
    options: { sitekey: string; callback: (token: string) => void },
  ) => string;
  remove: (widgetId: string) => void;
};

function turnstileApi(): TurnstileApi | null {
  return (window as unknown as { turnstile?: TurnstileApi }).turnstile ?? null;
}

/** Oculto si no hay VITE_TURNSTILE_SITE_KEY. El demo de integración sigue sin clave. */
export function TurnstileWidget({ onToken }: { onToken: (token: string) => void }) {
  const host = useRef<HTMLDivElement>(null);
  const onTokenRef = useRef(onToken);
  onTokenRef.current = onToken;

  useEffect(() => {
    if (!SITE_KEY || !host.current) return;
    let widgetId = '';
    let cancelled = false;

    const render = () => {
      const api = turnstileApi();
      if (!api || !host.current || cancelled) return;
      widgetId = api.render(host.current, {
        sitekey: SITE_KEY,
        callback: (token) => onTokenRef.current(token),
      });
    };

    if (turnstileApi()) {
      render();
    } else {
      const script = document.createElement('script');
      script.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit';
      script.async = true;
      script.onload = render;
      document.head.appendChild(script);
    }

    return () => {
      cancelled = true;
      const api = turnstileApi();
      if (widgetId && api) api.remove(widgetId);
    };
  }, []);

  if (!SITE_KEY) return null;
  return <div ref={host} className="turnstile-slot" />;
}
