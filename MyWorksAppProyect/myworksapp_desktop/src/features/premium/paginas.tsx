import { Banda } from './Banda';
import { TablaMil } from './TablaMil';
import { Button } from '../../ui/kit';
import { ProfesionalesPage } from '../screens';

export function VerificacionesPage() {
  return <ProfesionalesPage soloCola />;
}

export function InformesPage() {
  return (
    <section className="stack">
      <div className="spread">
        <div>
          <h1>Reportes</h1>
          <p className="muted">Informe del período. Imprimir guarda un PDF con la fecha de hoy.</p>
        </div>
        <Button variant="secondary" onClick={() => window.print()}>Exportar PDF</Button>
      </div>
      <Banda seccion="reportes" />
    </section>
  );
}

export function SistemaDisenoPage() {
  return (
    <section className="stack">
      <h1>Sistema de diseño</h1>
      <p className="muted">Componentes de la consola. Sin efectos de vidrio ni desenfoque de fondo.</p>
      <Banda seccion="inicio" />
      <h2>Tabla de 10.000 filas</h2>
      <TablaMil />
    </section>
  );
}
