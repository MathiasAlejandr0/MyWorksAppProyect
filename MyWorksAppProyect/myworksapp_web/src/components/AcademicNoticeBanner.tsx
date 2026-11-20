import { useEffect, useRef, useState } from 'react';
import { ACADEMIC_BANNER_TEXT, ACADEMIC_INDICATOR } from '../legal/academicCopy';

const STORAGE_KEY = 'mwa-academic-notice';

export function AcademicNoticeBanner() {
  const [open, setOpen] = useState(() => {
    try {
      return localStorage.getItem(STORAGE_KEY) !== 'closed';
    } catch {
      return true;
    }
  });
  const barRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const bar = barRef.current;
    if (!bar) return;
    const apply = () => {
      document.documentElement.style.setProperty('--academic-banner-h', `${bar.offsetHeight}px`);
    };
    apply();
    const observer = new ResizeObserver(apply);
    observer.observe(bar);
    return () => {
      observer.disconnect();
      document.documentElement.style.removeProperty('--academic-banner-h');
    };
  }, [open]);

  const toggle = () => {
    setOpen((current) => {
      const next = !current;
      try {
        localStorage.setItem(STORAGE_KEY, next ? 'open' : 'closed');
      } catch {
        // Sin almacenamiento el aviso sigue visible en esta visita.
      }
      return next;
    });
  };

  return (
    <div
      ref={barRef}
      className={`academic-banner${open ? '' : ' is-collapsed'}`}
      role="region"
      aria-label="Aviso de proyecto académico"
    >
      <div className="academic-banner-inner">
        <p>{open ? ACADEMIC_BANNER_TEXT : ACADEMIC_INDICATOR}</p>
        <button type="button" onClick={toggle} aria-expanded={open}>
          {open ? 'Ocultar aviso' : 'Ver aviso'}
        </button>
      </div>
    </div>
  );
}
