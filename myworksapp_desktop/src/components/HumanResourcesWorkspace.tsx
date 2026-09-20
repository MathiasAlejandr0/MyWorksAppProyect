import { useState } from 'react';

import {

  Users,

  Send,

  Search,

  SlidersHorizontal,

  Bell,

  MoreVertical,

  Shield,

} from 'lucide-react';



type RoleBadge = 'Admin' | 'Soporte' | 'QA';

type StatusBadge = 'Activo' | 'Inactivo';



interface Collaborator {

  id: string;

  name: string;

  title: string;

  email: string;

  area: string;

  role: RoleBadge;

  status: StatusBadge;

  initials: string;

}



const DEMO_COLLABORATORS: Collaborator[] = [

  { id: '1', name: 'Alex Morgan', title: 'Dirección de operaciones', email: 'alex.morgan@myworksapp.com', area: 'Operaciones', role: 'Admin', status: 'Activo', initials: 'AM' },

  { id: '2', name: 'Bruno Demo', title: 'Especialista en Tickets', email: 'bruno.demo@myworksapp.com', area: 'Soporte', role: 'Soporte', status: 'Activo', initials: 'BD' },

  { id: '3', name: 'Carla Demo', title: 'Especialista de calidad', email: 'carla.demo@myworksapp.com', area: 'Ingeniería', role: 'QA', status: 'Activo', initials: 'CD' },

  { id: '4', name: 'Diana Ruiz', title: 'Jefatura de equipo', email: 'diana.ruiz@myworksapp.com', area: 'RRHH', role: 'Admin', status: 'Activo', initials: 'DR' },

  { id: '5', name: 'Eduardo Paz', title: 'Agente de Soporte', email: 'eduardo.paz@myworksapp.com', area: 'Soporte', role: 'Soporte', status: 'Inactivo', initials: 'EP' },

];



export function HumanResourcesWorkspace() {

  // Colaboradores ficticios solo en DEV — en build de producto la lista parte vacía.
  const [collaborators] = useState<Collaborator[]>(
    import.meta.env.DEV ? DEMO_COLLABORATORS : [],
  );

  const [search, setSearch] = useState('');

  const [inviteRole, setInviteRole] = useState<RoleBadge>('Admin');

  const [inviteEmail, setInviteEmail] = useState('');

  const [inviteName, setInviteName] = useState('');

  const [inviteMessage, setInviteMessage] = useState('');



  const filtered = collaborators.filter(

    (c) =>

      c.name.toLowerCase().includes(search.toLowerCase()) ||

      c.email.toLowerCase().includes(search.toLowerCase()),

  );



  const handleInvite = (e: React.FormEvent) => {

    e.preventDefault();

    setInviteEmail('');

    setInviteName('');

    setInviteMessage('');

  };



  return (

    <div className="hr-workspace">

      <header className="hr-header">

        <div>

          <h1 className="hr-title">Mi Trabajo</h1>

          <p className="hr-subtitle">Gestiona tu equipo y colaboradores en un solo lugar.</p>

        </div>

        <div className="hr-header-actions">

          <button type="button" className="icon-btn hr-notify" aria-label="Notificaciones">

            <Bell size={20} />

            <span className="notify-badge">3</span>

          </button>

        </div>

      </header>



      <div className="hr-body">

        <section className="hr-directory card-surface">

          <div className="hr-directory-head">

            <div className="hr-directory-title">

              <Users size={18} className="hr-directory-icon" />

              <div>

                <h2>Directorio de empleados</h2>

                <p>Administra roles, accesos y estado de tu equipo.</p>

              </div>

            </div>

            <div className="hr-directory-tools">

              <div className="hr-search">

                <Search size={14} />

                <input

                  type="search"

                  value={search}

                  onChange={(e) => setSearch(e.target.value)}

                  placeholder="Buscar por nombre…"

                />

              </div>

              <button type="button" className="icon-btn" aria-label="Filtros">

                <SlidersHorizontal size={16} />

              </button>

            </div>

          </div>



          <div className="hr-table-wrap">

            <table className="hr-table">

              <thead>

                <tr>

                  <th>Colaborador</th>

                  <th>Email</th>

                  <th>Área</th>

                  <th>Rol</th>

                  <th>Estado</th>

                  <th aria-label="Acciones" />

                </tr>

              </thead>

              <tbody>

                {filtered.map((c) => (

                  <tr key={c.id}>

                    <td>

                      <div className="hr-person">

                        <span className="hr-avatar">{c.initials}</span>

                        <div>

                          <strong>{c.name}</strong>

                          <span>{c.title}</span>

                        </div>

                      </div>

                    </td>

                    <td className="hr-email">{c.email}</td>

                    <td>{c.area}</td>

                    <td>

                      <span className={`hr-role-badge hr-role-badge--${c.role.toLowerCase()}`}>{c.role}</span>

                    </td>

                    <td>

                      <span className={`hr-status-badge hr-status-badge--${c.status.toLowerCase()}`}>{c.status}</span>

                    </td>

                    <td>

                      <button type="button" className="icon-btn icon-btn--sm" aria-label="Más acciones">

                        <MoreVertical size={16} />

                      </button>

                    </td>

                  </tr>

                ))}

              </tbody>

            </table>

          </div>



          <div className="hr-pagination">

            <span>Mostrando 1 a {filtered.length} de 24 colaboradores</span>

            <div className="hr-pagination-controls">

              <button type="button" disabled>‹</button>

              <button type="button" className="active">1</button>

              <button type="button">2</button>

              <button type="button">3</button>

              <span>…</span>

              <button type="button">5</button>

              <button type="button">›</button>

            </div>

          </div>

        </section>



        <aside className="hr-invite card-surface">

          <div className="hr-invite-head">

            <Send size={18} className="hr-invite-icon" />

            <h2>Invitar colaborador</h2>

          </div>



          <form className="hr-invite-form" onSubmit={handleInvite}>

            <label>

              Correo electrónico

              <input

                type="email"

                value={inviteEmail}

                onChange={(e) => setInviteEmail(e.target.value)}

                placeholder="nombre@empresa.com"

                required

              />

            </label>

            <label>

              Nombre completo

              <input

                type="text"

                value={inviteName}

                onChange={(e) => setInviteName(e.target.value)}

                placeholder="Nombre Apellido"

                required

              />

            </label>

            <fieldset className="hr-role-toggle">

              <legend>Rol</legend>

              {(['Admin', 'Soporte', 'QA'] as RoleBadge[]).map((role) => (

                <button

                  key={role}

                  type="button"

                  className={`hr-role-option${inviteRole === role ? ' active' : ''}`}

                  onClick={() => setInviteRole(role)}

                >

                  {role}

                </button>

              ))}

            </fieldset>

            <label>

              Mensaje (opcional)

              <textarea

                value={inviteMessage}

                onChange={(e) => setInviteMessage(e.target.value)}

                placeholder="Mensaje personalizado para la invitación…"

                rows={3}

              />

            </label>

            <button type="submit" className="hr-invite-submit">

              <Send size={16} /> Enviar invitación

            </button>

          </form>

        </aside>

      </div>



      <footer className="hr-footer">

        <span>Área: RRHH · Rol: Admin</span>

        <span><Shield size={12} /> Seguro y encriptado · Versión 1.4.0</span>

      </footer>

    </div>

  );

}

