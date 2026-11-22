import { createContext, useContext, useMemo, type ReactNode } from 'react';
import { useSearchParams } from 'react-router';

interface Periodo {
  dias: number;
  fijarDias: (dias: number) => void;
}

const PeriodoContext = createContext<Periodo | null>(null);

export function PeriodoProvider({ children }: { children: ReactNode }) {
  const [params, setParams] = useSearchParams();
  const crudo = Number(params.get('dias') ?? '7');
  const dias = [1, 7, 30, 90].includes(crudo) ? crudo : 7;
  const value = useMemo<Periodo>(() => ({
    dias,
    fijarDias: (siguiente) => {
      const next = new URLSearchParams(params);
      next.set('dias', String(siguiente));
      setParams(next);
    },
  }), [dias, params, setParams]);
  return <PeriodoContext.Provider value={value}>{children}</PeriodoContext.Provider>;
}

export function usePeriodo(): Periodo {
  const value = useContext(PeriodoContext);
  if (!value) return { dias: 7, fijarDias: () => {} };
  return value;
}
