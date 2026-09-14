import React, { useState } from 'react';
import { Users, UserPlus, ShieldCheck, CheckCircle2, XCircle, Search } from 'lucide-react';

interface Collaborator {
  id: string;
  name: string;
  email: string;
  demoId: string;
  department: string;
  role: string;
  status: 'ACTIVE' | 'INACTIVE';
}

/** Directorio ficticio — sin RUTs ni PII reales. */
const DEMO_COLLABORATORS: Collaborator[] = [
  { id: 'HR-DEMO-01', name: 'Ana Demo', email: 'ana.demo@example.com', demoId: 'DEMO-ID-001', department: 'Dirección General', role: 'Administrador General', status: 'ACTIVE' },
  { id: 'HR-DEMO-02', name: 'Bruno Demo', email: 'bruno.demo@example.com', demoId: 'DEMO-ID-002', department: 'Soporte & Mediación', role: 'Especialista en Tickets', status: 'ACTIVE' },
  { id: 'HR-DEMO-03', name: 'Carla Demo', email: 'carla.demo@example.com', demoId: 'DEMO-ID-003', department: 'Ingeniería & QA', role: 'DevSecOps Specialist', status: 'ACTIVE' },
];

export function HumanResourcesWorkspace() {
  const [collaborators, setCollaborators] = useState<Collaborator[]>(DEMO_COLLABORATORS);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch] = useState('');

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [demoId, setDemoId] = useState('');
  const [department, setDepartment] = useState('Soporte & Mediación');
  const [role, setRole] = useState('Agente de Soporte');

  const addCollaborator = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email || !demoId) return;

    const newCollab: Collaborator = {
      id: `HR-DEMO-${Date.now().toString().slice(-3)}`,
      name,
      email,
      demoId,
      department,
      role,
      status: 'ACTIVE',
    };

    setCollaborators((prev) => [newCollab, ...prev]);
    setName('');
    setEmail('');
    setDemoId('');
    setShowModal(false);
  };

  const toggleStatus = (id: string) => {
    setCollaborators((prev) => prev.map((c) => (c.id === id ? { ...c, status: c.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' } : c)));
  };

  const filtered = collaborators.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.email.toLowerCase().includes(search.toLowerCase()) ||
      c.department.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '16px', gap: '16px', flexWrap: 'wrap' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            <h1 style={{ fontSize: '22px', fontWeight: 900 }}>Recursos humanos</h1>
            <span className="demo-badge">DEMO</span>
          </div>
          <p style={{ fontSize: '13.5px', color: '#98989D', marginTop: '4px' }}>
            Directorio de ejemplo para la demo académica. No son empleados reales ni contiene RUTs/PII sensibles.
          </p>
        </div>
        <button onClick={() => setShowModal(true)} className="btn-action-primary">
          <UserPlus size={16} /> Agregar colaborador (demo)
        </button>
      </div>

      <div className="demo-banner" style={{ marginBottom: '20px' }}>
        Datos de demostración — los cambios solo viven en memoria de esta sesión.
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#007AFF', marginBottom: '6px' }}>
            <Users size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>TOTAL (DEMO)</span>
          </div>
          <div style={{ fontSize: '26px', fontWeight: 900 }}>{collaborators.length}</div>
        </div>

        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#34C759', marginBottom: '6px' }}>
            <ShieldCheck size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>ACTIVOS (DEMO)</span>
          </div>
          <div style={{ fontSize: '26px', fontWeight: 900 }}>{collaborators.filter((c) => c.status === 'ACTIVE').length}</div>
        </div>
      </div>

      <div className="card-3d" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px', gap: '12px', flexWrap: 'wrap' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Directorio demo</h3>
          <div style={{ position: 'relative', width: 'min(280px, 100%)' }}>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar por nombre, email o departamento..."
              style={{ width: '100%', padding: '8px 12px 8px 36px', borderRadius: '8px', border: '1px solid rgba(255,255,255,0.12)', background: 'rgba(255,255,255,0.03)', color: 'white', fontSize: '13px', outline: 'none' }}
            />
            <Search size={16} style={{ position: 'absolute', left: '12px', top: '10px', color: '#98989D' }} />
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
            <thead>
              <tr style={{ backgroundColor: 'rgba(255,255,255,0.04)', borderBottom: '1px solid rgba(255,255,255,0.08)' }}>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ID</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>COLABORADOR</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ID DEMO</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>DEPARTAMENTO</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ROL</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ESTADO</th>
                <th style={{ padding: '12px 16px', color: '#98989D' }}>ACCIÓN</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((c) => (
                <tr key={c.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <td style={{ padding: '12px 16px', fontWeight: 800, color: '#F0782A' }}>{c.id}</td>
                  <td style={{ padding: '12px 16px' }}>
                    <div style={{ fontWeight: 700 }}>{c.name}</div>
                    <div style={{ fontSize: '11px', color: '#98989D' }}>{c.email}</div>
                  </td>
                  <td style={{ padding: '12px 16px', fontFamily: 'monospace' }}>{c.demoId}</td>
                  <td style={{ padding: '12px 16px', fontWeight: 600 }}>{c.department}</td>
                  <td style={{ padding: '12px 16px' }}>{c.role}</td>
                  <td style={{ padding: '12px 16px' }}>
                    <span className={c.status === 'ACTIVE' ? 'badge badge-success' : 'badge badge-error'}>
                      {c.status === 'ACTIVE' ? 'Activo' : 'Inactivo'}
                    </span>
                  </td>
                  <td style={{ padding: '12px 16px' }}>
                    <button
                      onClick={() => toggleStatus(c.id)}
                      className={c.status === 'ACTIVE' ? 'btn-action-danger' : 'btn-action-success'}
                      style={{ padding: '4px 10px', fontSize: '11px' }}
                    >
                      {c.status === 'ACTIVE' ? <XCircle size={12} /> : <CheckCircle2 size={12} />}
                      {c.status === 'ACTIVE' ? 'Desactivar' : 'Activar'}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999, padding: '20px' }}>
          <div style={{ maxWidth: '480px', width: '100%', backgroundColor: '#121E33', borderRadius: '18px', padding: '28px', color: '#F5F5F7', boxShadow: '0 20px 50px rgba(0,0,0,0.55)', border: '1px solid rgba(240,120,42,0.22)', position: 'relative' }}>
            <button onClick={() => setShowModal(false)} style={{ position: 'absolute', right: '20px', top: '20px', background: 'none', border: 'none', color: '#98989D', cursor: 'pointer', fontSize: '16px' }}>✕</button>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '6px' }}>
              <h3 style={{ fontSize: '20px', fontWeight: 900, color: '#FFFFFF' }}>Nuevo colaborador</h3>
              <span className="demo-badge">DEMO</span>
            </div>
            <p style={{ fontSize: '13px', color: '#98989D', marginBottom: '20px' }}>Solo memoria local. No uses RUTs reales ni datos personales.</p>

            <form onSubmit={addCollaborator} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '4px', display: 'block' }}>Nombre</label>
                <input type="text" value={name} onChange={(e) => setName(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }} placeholder="Ej: Persona Demo" />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '4px', display: 'block' }}>Email (ejemplo)</label>
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }} placeholder="persona.demo@example.com" />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '4px', display: 'block' }}>ID demo (no RUT)</label>
                <input type="text" value={demoId} onChange={(e) => setDemoId(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }} placeholder="DEMO-ID-004" />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '4px', display: 'block' }}>Departamento</label>
                  <select value={department} onChange={(e) => setDepartment(e.target.value)} style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #1E2A3B', fontSize: '13px', outline: 'none', backgroundColor: '#090D16', color: 'white' }}>
                    <option value="Soporte & Mediación">Soporte & Mediación</option>
                    <option value="Operaciones & Finanzas">Operaciones & Finanzas</option>
                    <option value="Ingeniería & QA">Ingeniería & QA</option>
                    <option value="Dirección General">Dirección General</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '4px', display: 'block' }}>Rol</label>
                  <select value={role} onChange={(e) => setRole(e.target.value)} style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #1E2A3B', fontSize: '13px', outline: 'none', backgroundColor: '#090D16', color: 'white' }}>
                    <option value="Especialista de Soporte">Soporte</option>
                    <option value="DevSecOps Specialist">DevSecOps / QA</option>
                    <option value="Administrador General">Admin</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn-action-secondary">Cancelar</button>
                <button type="submit" className="btn-action-primary">Guardar (demo)</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
