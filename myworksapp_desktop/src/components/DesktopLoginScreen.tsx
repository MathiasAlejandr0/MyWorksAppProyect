import React, { useState } from 'react';
import { ShieldCheck, Lock, Mail, Home, Wrench } from 'lucide-react';

interface DesktopLoginScreenProps {
  onLogin: (role: 'ADMIN' | 'SUPPORT' | 'DEVSECOPS') => void;
}

export function DesktopLoginScreen({ onLogin }: DesktopLoginScreenProps) {
  const [email, setEmail] = useState('admin@myworksapp.cl');
  const [password, setPassword] = useState('••••••••');
  const [selectedRole, setSelectedRole] = useState<'ADMIN' | 'SUPPORT' | 'DEVSECOPS'>('ADMIN');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onLogin(selectedRole);
  };

  return (
    <div style={{ minHeight: '100vh', width: '100vw', backgroundColor: '#090D16', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px', fontFamily: 'sans-serif' }}>
      <div style={{ maxWidth: '440px', width: '100%', backgroundColor: '#121826', border: '1px solid #1E2A3B', borderRadius: '24px', padding: '36px', boxShadow: '0 25px 60px rgba(0,0,0,0.6)', color: 'white' }}>
        
        {/* Brand Header */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: '28px' }}>
          <div style={{ position: 'relative', width: '56px', height: '56px', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '12px' }}>
            <Home size={50} color="#FFFFFF" />
            <div style={{ position: 'absolute', bottom: '2px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Wrench size={20} color="#F0782A" />
            </div>
          </div>
          <h1 style={{ fontSize: '22px', fontWeight: 900, color: 'white', letterSpacing: '0.2px' }}>My Works App</h1>
          <span style={{ fontSize: '11px', color: '#F0782A', fontWeight: 800, backgroundColor: 'rgba(240,120,42,0.15)', padding: '3px 10px', borderRadius: '12px', marginTop: '4px' }}>ENTERPRISE MANAGEMENT HUB</span>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Selector de Rol Corporativo */}
          <div>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', textTransform: 'uppercase', marginBottom: '6px', display: 'block' }}>Perfil de Ingreso Corporativo:</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '8px' }}>
              <button 
                type="button" 
                onClick={() => { setSelectedRole('ADMIN'); setEmail('admin@myworksapp.cl'); }}
                style={{ padding: '10px 4px', borderRadius: '10px', border: selectedRole === 'ADMIN' ? '2px solid #F0782A' : '1px solid #1E2A3B', backgroundColor: selectedRole === 'ADMIN' ? 'rgba(240,120,42,0.15)' : '#090D16', color: selectedRole === 'ADMIN' ? '#F0782A' : '#98989D', fontWeight: 800, fontSize: '11px', cursor: 'pointer' }}
              >
                👑 Admin
              </button>
              <button 
                type="button" 
                onClick={() => { setSelectedRole('SUPPORT'); setEmail('soporte@myworksapp.cl'); }}
                style={{ padding: '10px 4px', borderRadius: '10px', border: selectedRole === 'SUPPORT' ? '2px solid #FF3B30' : '1px solid #1E2A3B', backgroundColor: selectedRole === 'SUPPORT' ? 'rgba(255,59,48,0.15)' : '#090D16', color: selectedRole === 'SUPPORT' ? '#FF3B30' : '#98989D', fontWeight: 800, fontSize: '11px', cursor: 'pointer' }}
              >
                🎧 Soporte
              </button>
              <button 
                type="button" 
                onClick={() => { setSelectedRole('DEVSECOPS'); setEmail('devsecops@myworksapp.cl'); }}
                style={{ padding: '10px 4px', borderRadius: '10px', border: selectedRole === 'DEVSECOPS' ? '2px solid #007AFF' : '1px solid #1E2A3B', backgroundColor: selectedRole === 'DEVSECOPS' ? 'rgba(0,122,255,0.15)' : '#090D16', color: selectedRole === 'DEVSECOPS' ? '#007AFF' : '#98989D', fontWeight: 800, fontSize: '11px', cursor: 'pointer' }}
              >
                🛡️ Devs/QA
              </button>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '6px', display: 'block' }}>Email Corporativo</label>
            <div style={{ position: 'relative' }}>
              <input 
                type="email" 
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                style={{ width: '100%', padding: '12px 14px 12px 40px', borderRadius: '10px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }}
                required
              />
              <Mail size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: '#98989D' }} />
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#98989D', marginBottom: '6px', display: 'block' }}>Contraseña de Seguridad</label>
            <div style={{ position: 'relative' }}>
              <input 
                type="password" 
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                style={{ width: '100%', padding: '12px 14px 12px 40px', borderRadius: '10px', border: '1px solid #1E2A3B', backgroundColor: '#090D16', color: 'white', fontSize: '13.5px', outline: 'none' }}
                required
              />
              <Lock size={16} style={{ position: 'absolute', left: '14px', top: '14px', color: '#98989D' }} />
            </div>
          </div>

          <button 
            type="submit" 
            style={{ marginTop: '8px', padding: '14px', borderRadius: '9999px', border: 'none', background: 'linear-gradient(135deg, #FF6B00, #F0782A)', color: 'white', fontWeight: 800, fontSize: '14px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', boxShadow: '0 4px 15px rgba(240, 120, 42, 0.4)' }}
          >
            <ShieldCheck size={18} /> Iniciar Sesión en Desktop
          </button>
        </form>

        <div style={{ marginTop: '24px', textAlign: 'center', fontSize: '11.5px', color: '#98989D' }}>
          Conexión segura cifrada con Supabase Enterprise Auth
        </div>
      </div>
    </div>
  );
}
