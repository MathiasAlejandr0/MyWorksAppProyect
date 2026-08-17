import React, { useState } from 'react';
import { Users, UserPlus, ShieldCheck, CheckCircle2, XCircle, Search } from 'lucide-react';

interface Collaborator {
  id: string;
  name: string;
  email: string;
  rut: string;
  department: string;
  role: string;
  status: 'ACTIVE' | 'INACTIVE';
}

const INITIAL_COLLABORATORS: Collaborator[] = [
  { id: 'HR-101', name: 'Mathias Alejandro', email: 'mathias@myworksapp.cl', rut: '19.482.110-5', department: 'Dirección General', role: 'Administrador General', status: 'ACTIVE' },
  { id: 'HR-102', name: 'Carolina Mendoza', email: 'carolina.soporte@myworksapp.cl', rut: '17.892.401-K', department: 'Soporte & Mediación', role: 'Especialista en Tickets', status: 'ACTIVE' },
  { id: 'HR-103', name: 'Roberto Godoy', email: 'roberto.dev@myworksapp.cl', rut: '16.512.903-8', department: 'Ingeniería & QA', role: 'DevSecOps Specialist', status: 'ACTIVE' },
];

export function HumanResourcesWorkspace() {
  const [collaborators, setCollaborators] = useState<Collaborator[]>(INITIAL_COLLABORATORS);
  const [showModal, setShowModal] = useState(false);
  const [search, setSearch] = useState('');

  // Form State
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [rut, setRut] = useState('');
  const [department, setDepartment] = useState('Soporte & Mediación');
  const [role, setRole] = useState('Agente de Soporte');

  const addCollaborator = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !email || !rut) return;

    const newCollab: Collaborator = {
      id: `HR-${Date.now().toString().slice(-3)}`,
      name,
      email,
      rut,
      department,
      role,
      status: 'ACTIVE',
    };

    setCollaborators(prev => [newCollab, ...prev]);
    setName('');
    setEmail('');
    setRut('');
    setShowModal(false);
  };

  const toggleStatus = (id: string) => {
    setCollaborators(prev => prev.map(c => c.id === id ? { ...c, status: c.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE' } : c));
  };

  const filtered = collaborators.filter(c => 
    c.name.toLowerCase().includes(search.toLowerCase()) || 
    c.email.toLowerCase().includes(search.toLowerCase()) ||
    c.department.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 900 }}>Recursos Humanos & Colaboradores Internos</h1>
          <p style={{ fontSize: '13.5px', color: '#98989D' }}>Gestión del equipo corporativo, inscripción de personal y asignación de accesos.</p>
        </div>
        <button onClick={() => setShowModal(true)} className="btn-action-primary">
          <UserPlus size={16} /> Inscribir Nuevo Colaborador
        </button>
      </div>

      {/* Grid de Resumen de Personal */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '24px' }}>
        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#007AFF', marginBottom: '6px' }}>
            <Users size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>TOTAL COLABORADORES</span>
          </div>
          <div style={{ fontSize: '26px', fontWeight: 900 }}>{collaborators.length} Miembros</div>
        </div>

        <div className="card-3d">
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#34C759', marginBottom: '6px' }}>
            <ShieldCheck size={18} />
            <span style={{ fontSize: '12px', fontWeight: 800 }}>CUENTAS ACTIVAS</span>
          </div>
          <div style={{ fontSize: '26px', fontWeight: 900 }}>{collaborators.filter(c => c.status === 'ACTIVE').length} Activos</div>
        </div>
      </div>

      {/* Tabla de Colaboradores */}
      <div className="card-3d" style={{ padding: '20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 800 }}>Directorio del Equipo Corporativo</h3>
          <div style={{ position: 'relative', width: '280px' }}>
            <input 
              type="text" 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar por nombre, email o departamento..."
              style={{ width: '100%', padding: '8px 12px 8px 36px', borderRadius: '8px', border: '1px solid #E2E8F0', fontSize: '13px', outline: 'none' }}
            />
            <Search size={16} style={{ position: 'absolute', left: '12px', top: '10px', color: '#98989D' }} />
          </div>
        </div>

        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ backgroundColor: '#F8FAFC', borderBottom: '1px solid #E2E8F0' }}>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>ID</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>COLABORADOR</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>RUT</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>DEPARTAMENTO</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>ROL ASIGNADO</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>ESTADO</th>
              <th style={{ padding: '12px 16px', color: '#6E6E73' }}>ACCIÓN</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.id} style={{ borderBottom: '1px solid #F1F5F9' }}>
                <td style={{ padding: '12px 16px', fontWeight: 800, color: '#F0782A' }}>{c.id}</td>
                <td style={{ padding: '12px 16px' }}>
                  <div style={{ fontWeight: 700 }}>{c.name}</div>
                  <div style={{ fontSize: '11px', color: '#98989D' }}>{c.email}</div>
                </td>
                <td style={{ padding: '12px 16px', fontFamily: 'monospace' }}>{c.rut}</td>
                <td style={{ padding: '12px 16px', fontWeight: 600 }}>{c.department}</td>
                <td style={{ padding: '12px 16px' }}>{c.role}</td>
                <td style={{ padding: '12px 16px' }}>
                  <span className={c.status === 'ACTIVE' ? "badge badge-success" : "badge badge-error"}>
                    {c.status === 'ACTIVE' ? 'Activo' : 'Inactivo'}
                  </span>
                </td>
                <td style={{ padding: '12px 16px' }}>
                  <button 
                    onClick={() => toggleStatus(c.id)} 
                    className={c.status === 'ACTIVE' ? "btn-action-danger" : "btn-action-success"}
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

      {/* Modal de Inscripción de Nuevo Colaborador */}
      {showModal && (
        <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(9, 13, 22, 0.85)', backdropFilter: 'blur(12px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 999, padding: '20px' }}>
          <div style={{ maxWidth: '480px', width: '100%', backgroundColor: 'white', borderRadius: '18px', padding: '28px', color: '#1D1D1F', boxShadow: '0 20px 50px rgba(0,0,0,0.4)', position: 'relative' }}>
            <button onClick={() => setShowModal(false)} style={{ position: 'absolute', right: '20px', top: '20px', background: 'none', border: 'none', color: '#98989D', cursor: 'pointer', fontSize: '16px' }}>✕</button>

            <h3 style={{ fontSize: '20px', fontWeight: 900, marginBottom: '6px', color: '#0B192C' }}>Inscribir Nuevo Colaborador</h3>
            <p style={{ fontSize: '13px', color: '#6E6E73', marginBottom: '20px' }}>Registra un nuevo miembro del equipo interno para otorgarle accesos al Desktop Hub.</p>

            <form onSubmit={addCollaborator} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#6E6E73', marginBottom: '4px', display: 'block' }}>Nombre Completo</label>
                <input type="text" value={name} onChange={e => setName(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '13.5px', outline: 'none' }} placeholder="Ej: Ana María Torres" />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#6E6E73', marginBottom: '4px', display: 'block' }}>Email Corporativo</label>
                <input type="email" value={email} onChange={e => setEmail(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '13.5px', outline: 'none' }} placeholder="ana.torres@myworksapp.cl" />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#6E6E73', marginBottom: '4px', display: 'block' }}>RUT</label>
                <input type="text" value={rut} onChange={e => setRut(e.target.value)} required style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '13.5px', outline: 'none' }} placeholder="18.390.112-9" />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#6E6E73', marginBottom: '4px', display: 'block' }}>Departamento</label>
                  <select value={department} onChange={e => setDepartment(e.target.value)} style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '13px', outline: 'none', backgroundColor: 'white' }}>
                    <option value="Soporte & Mediación">Soporte & Mediación</option>
                    <option value="Operaciones & Finanzas">Operaciones & Finanzas</option>
                    <option value="Ingeniería & QA">Ingeniería & QA</option>
                    <option value="Dirección General">Dirección General</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#6E6E73', marginBottom: '4px', display: 'block' }}>Rol de Acceso</label>
                  <select value={role} onChange={e => setRole(e.target.value)} style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #CBD5E1', fontSize: '13px', outline: 'none', backgroundColor: 'white' }}>
                    <option value="Especialista de Soporte">Soporte</option>
                    <option value="DevSecOps Specialist">DevSecOps / QA</option>
                    <option value="Administrador General">Admin</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
                <button type="button" onClick={() => setShowModal(false)} className="btn-action-secondary">Cancelar</button>
                <button type="submit" className="btn-action-primary">Guardar Colaborador</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
