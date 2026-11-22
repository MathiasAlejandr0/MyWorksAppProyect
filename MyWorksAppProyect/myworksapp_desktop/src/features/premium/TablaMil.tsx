import { useRef } from 'react';
import { useVirtualizer } from '@tanstack/react-virtual';

/** Tabla virtual para comprobar que 10.000 filas no se pintan todas. */
export function TablaMil({ total = 10_000 }: { total?: number }) {
  const padre = useRef<HTMLDivElement>(null);
  const virtual = useVirtualizer({
    count: total,
    getScrollElement: () => padre.current,
    estimateSize: () => 36,
    overscan: 8,
  });
  const visibles = virtual.getVirtualItems();
  return (
    <section className="stack">
      <p className="muted">{total.toLocaleString('es-CL')} filas. En pantalla hay {visibles.length}.</p>
      <div ref={padre} className="virtual-scroll" data-filas={total}>
        <div style={{ height: virtual.getTotalSize(), position: 'relative' }}>
          {visibles.map((item) => (
            <div
              key={item.key}
              className="virtual-row"
              style={{ position: 'absolute', top: 0, transform: `translateY(${item.start}px)`, height: item.size }}
            >
              Fila {item.index + 1}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
