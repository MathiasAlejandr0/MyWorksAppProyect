import { useState, useEffect } from 'react';
import { 
  Wrench, 
  Zap, 
  Sparkles, 
  Truck, 
  Laptop, 
  Flower2, 
  Hammer, 
  PackageCheck, 
  ShieldCheck, 
  CheckCircle2, 
  Search, 
  Sun, 
  Moon, 
  ArrowRight, 
  Star, 
  X,
  FileText,
  CreditCard,
  Home
} from 'lucide-react';
import { PaymentCheckoutModal } from './components/PaymentCheckoutModal';
import { LiveChatWidget } from './components/LiveChatWidget';
import { generatePdfCertificate } from './utils/pdfCertificateGenerator';
import { SpatialEmergencyPulse } from './components/SpatialEmergencyPulse';
import { PredictiveTrustMeter } from './components/PredictiveTrustMeter';
import { AmbientShader } from './components/AmbientShader';
import { AppleSpatialBackground } from './components/AppleSpatialBackground';
import { LiveGpsTrackingMap } from './components/LiveGpsTrackingMap';

interface Worker {
  id: string;
  name: string;
  profession: string;
  category: string;
  rating: number;
  jobsDone: number;
  photoUrl: string;
  pricePerVisit: number;
}

interface AiResult {
  category: string;
  categoryName: string;
  problem: string;
  minPrice: number;
  maxPrice: number;
  urgency: string;
  tools: string[];
  workers: Worker[];
}

const DEMO_WORKERS: Worker[] = [
  {
    id: 'w1',
    name: 'Carlos Muñoz',
    profession: 'Gásfiter Certificado SEC',
    category: 'plumbing',
    rating: 4.9,
    jobsDone: 142,
    photoUrl: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500',
    pricePerVisit: 25000,
  },
  {
    id: 'w2',
    name: 'Juan Pérez',
    profession: 'Electricista Autorizado SEC',
    category: 'electrical',
    rating: 4.95,
    jobsDone: 198,
    photoUrl: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=500',
    pricePerVisit: 25000,
  },
  {
    id: 'w3',
    name: 'María José González',
    profession: 'Especialista en Sanitización',
    category: 'cleaning',
    rating: 4.88,
    jobsDone: 87,
    photoUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500',
    pricePerVisit: 30000,
  },
  {
    id: 'w4',
    name: 'Roberto Silva',
    profession: 'Montajista de Muebles Pro',
    category: 'assembly',
    rating: 4.92,
    jobsDone: 115,
    photoUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=500',
    pricePerVisit: 20000,
  },
];

const CATEGORIES = [
  { id: 'plumbing', title: 'Gásfiter / Plomería', icon: Wrench, photo: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600' },
  { id: 'electrical', title: 'Electricidad SEC', icon: Zap, photo: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=600' },
  { id: 'cleaning', title: 'Limpieza e Higiene', icon: Sparkles, photo: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600' },
  { id: 'assembly', title: 'Armado Muebles', icon: PackageCheck, photo: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600' },
  { id: 'moving', title: 'Mudanzas y Fletes', icon: Truck, photo: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600' },
  { id: 'tech', title: 'Soporte PC / WiFi', icon: Laptop, photo: 'https://images.unsplash.com/photo-1588702547919-26089e690ecc?w=600' },
  { id: 'gardening', title: 'Jardines y Poda', icon: Flower2, photo: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=600' },
  { id: 'construction', title: 'Maestro Albañil', icon: Hammer, photo: 'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?w=600' },
];

export function App() {
  const [darkMode, setDarkMode] = useState(false);
  const [query, setQuery] = useState('');
  const [aiResult, setAiResult] = useState<AiResult | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState<Worker | null>(null);
  const [bookingConfirmed, setBookingConfirmed] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [showEmergencyPulse, setShowEmergencyPulse] = useState(false);

  useEffect(() => {
    if (darkMode) {
      document.body.classList.add('dark');
    } else {
      document.body.classList.remove('dark');
    }
  }, [darkMode]);

  const analyzeQuery = (text: string) => {
    if (!text.trim()) return;
    setIsAnalyzing(true);
    setQuery(text);

    setTimeout(() => {
      const lower = text.toLowerCase();
      let category = 'electrical';
      let categoryName = 'Electricista Certificado';
      let problem = 'Diagnóstico y reparación de falla eléctrica';
      let minPrice = 25000;
      let maxPrice = 60000;
      let urgency = 'Media';
      let tools = ['Tester digital', 'Alicate pelacables', 'Breaker sustituto'];

      if (lower.includes('fuga') || lower.includes('agua') || lower.includes('lavaplatos') || lower.includes('llave') || lower.includes('gasfiter')) {
        category = 'plumbing';
        categoryName = 'Gásfiter / Plomero SEC';
        problem = 'Reparación de fuga de agua y cambio de llaves o grifería';
        minPrice = 30000;
        maxPrice = 75000;
        urgency = 'Alta (Urgencia 24/7)';
        tools = ['Soplete', 'Llave francesa', 'Sellante de teflón'];
      } else if (lower.includes('mueble') || lower.includes('armar') || lower.includes('closet') || lower.includes('rack')) {
        category = 'assembly';
        categoryName = 'Armado de Muebles';
        problem = 'Montaje e instalación de mueble listo para armar';
        minPrice = 20000;
        maxPrice = 45000;
        urgency = 'Normal';
        tools = ['Atornillador inalámbrico', 'Nivel de gota', 'Juego Allen'];
      } else if (lower.includes('limpia') || lower.includes('aseo') || lower.includes('departamento')) {
        category = 'cleaning';
        categoryName = 'Limpieza de Hogar u Oficina';
        problem = 'Aseo profundo y desinfección de superficies';
        minPrice = 35000;
        maxPrice = 80000;
        urgency = 'Normal';
        tools = ['Aspiradora industrial', 'Insumos sanitizantes'];
      }

      const matchingWorkers = DEMO_WORKERS.filter(w => w.category === category || category === 'electrical');

      setAiResult({
        category,
        categoryName,
        problem,
        minPrice,
        maxPrice,
        urgency,
        tools,
        workers: matchingWorkers.length > 0 ? matchingWorkers : [DEMO_WORKERS[0]],
      });
      setIsAnalyzing(false);
    }, 600);
  };

  return (
    <div className="min-h-screen">
      {/* Fondo de Malla Kinética Apple Spatial */}
      <AppleSpatialBackground />

      {/* Ambient Shader por Categoría */}
      <AmbientShader category={aiResult?.category || 'general'} />

      {/* 1. Translucent Apple Nav */}
      <nav className="glass-nav" style={{ position: 'relative', zIndex: 10 }}>
        <div className="container" style={{ height: '72px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            {/* Logo Idéntico a App Móvil: Casa + Herramienta */}
            <div style={{ position: 'relative', width: '42px', height: '42px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Home size={38} color={darkMode ? '#FFFFFF' : '#0B192C'} />
              <div style={{ position: 'absolute', bottom: '2px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Wrench size={16} color="#F0782A" />
              </div>
            </div>
            <div>
              <span style={{ fontSize: '20px', fontWeight: 800, letterSpacing: '0.2px', color: darkMode ? '#FFFFFF' : '#0B192C' }}>My Works App</span>
              <span style={{ fontSize: '11px', fontWeight: 800, color: '#F0782A', marginLeft: '6px', backgroundColor: 'rgba(240,120,42,0.12)', padding: '2px 8px', borderRadius: '12px' }}>WEB</span>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <button 
              onClick={() => setShowEmergencyPulse(true)}
              style={{ backgroundColor: 'rgba(255, 59, 48, 0.15)', color: '#FF3B30', border: '1px solid #FF3B30', padding: '8px 16px', borderRadius: 'var(--radius-pill)', fontWeight: 800, fontSize: '12.5px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <Sparkles size={16} /> Urgencia 24/7 (3s)
            </button>

            <button 
              onClick={() => setDarkMode(!darkMode)}
              style={{ background: 'transparent', border: '1px solid var(--border-light)', padding: '8px 14px', borderRadius: '20px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', color: 'inherit' }}
            >
              {darkMode ? <Sun size={16} /> : <Moon size={16} />}
              <span style={{ fontSize: '13px', fontWeight: 600 }}>{darkMode ? 'Claro' : 'Oscuro'}</span>
            </button>
          </div>
        </div>
      </nav>

      {/* 2. Hero Section con Buscador Inteligente por Palabras Clave */}
      <section style={{ padding: '60px 0 40px', position: 'relative', zIndex: 1 }}>
        <div className="container">
          {/* Predictive Trust Meter (Fiabilidad & Transparencia) */}
          <PredictiveTrustMeter />
          <div style={{ textAlign: 'center', maxWidth: '800px', margin: '0 auto 40px' }}>
            <div className="badge-tag badge-orange" style={{ marginBottom: '16px' }}>
              <Sparkles size={14} /> Buscador Inteligente por Palabras Claves (Web Exclusivo sin fotos)
            </div>
            <h1 style={{ fontSize: '42px', fontWeight: 900, lineHeight: 1.15, marginBottom: '16px', letterSpacing: '-1px' }}>
              Encuentra el profesional verificado en segundos con el <span style={{ background: 'linear-gradient(135deg, #FF6B00, #F0782A)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>Buscador Inteligente</span>
            </h1>
            <p style={{ fontSize: '17px', color: darkMode ? 'var(--text-muted-dark)' : 'var(--text-muted-light)' }}>
              Describe en lenguaje natural lo que necesitas reparar en tu hogar u oficina. El motor evaluará el costo estimado de mercado y te recomendará a los especialistas mejor calificados sin pedir fotos.
            </p>
          </div>

          {/* Caja de Consulta Buscador Inteligente */}
          <div className="card-3d" style={{ maxWidth: '860px', margin: '0 auto', border: '2px solid rgba(240, 120, 42, 0.3)', boxShadow: 'var(--shadow-glow)' }}>
            <div style={{ display: 'flex', gap: '12px', marginBottom: '16px' }}>
              <div style={{ flex: 1, position: 'relative' }}>
                <input 
                  type="text" 
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && analyzeQuery(query)}
                  placeholder='Ej: "Tengo una fuga de agua en el lavaplatos y gotea el sifón..."'
                  style={{ width: '100%', padding: '16px 20px 16px 48px', borderRadius: 'var(--radius-pill)', border: '1px solid var(--border-light)', fontSize: '15px', outline: 'none', background: darkMode ? 'var(--bg-elevated-dark)' : 'var(--bg-elevated-light)', color: 'inherit' }}
                />
                <Search size={20} style={{ position: 'absolute', left: '16px', top: '16px', color: '#F0782A' }} />
              </div>

              <button 
                onClick={() => analyzeQuery(query)}
                disabled={isAnalyzing}
                className="btn-primary"
                style={{ padding: '16px 32px' }}
              >
                {isAnalyzing ? 'Diagnosticando...' : 'Diagnosticar Servicio'}
              </button>
            </div>

            {/* Chips Rápidos */}
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '8px', alignItems: 'center' }}>
              <span style={{ fontSize: '12px', fontWeight: 700, color: 'var(--text-muted-light)' }}>Sugerencias rápidas:</span>
              {[
                '🔧 Fuga de agua en lavaplatos',
                '⚡ Enchufe quemado en la cocina',
                '🪛 Armado de clóset 3 puertas',
                '🧹 Limpieza profunda departamento',
              ].map((prompt, idx) => (
                <button
                  key={idx}
                  onClick={() => analyzeQuery(prompt.substring(3))}
                  style={{ background: darkMode ? 'var(--bg-elevated-dark)' : 'var(--orange-soft)', color: '#F0782A', border: 'none', padding: '6px 14px', borderRadius: 'var(--radius-pill)', fontSize: '12px', fontWeight: 600, cursor: 'pointer' }}
                >
                  {prompt}
                </button>
              ))}
            </div>

            {/* Resultado del Diagnóstico de Servicio */}
            {aiResult && (
              <div style={{ marginTop: '24px', padding: '20px', borderRadius: 'var(--radius-md)', backgroundColor: darkMode ? 'rgba(52, 199, 89, 0.1)' : '#E8F8EE', border: '1px solid #34C759' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <CheckCircle2 color="#34C759" size={22} />
                    <h3 style={{ fontSize: '18px', fontWeight: 800 }}>Diagnóstico de Servicio: {aiResult.categoryName}</h3>
                  </div>
                  <span className="badge-tag badge-orange">{aiResult.urgency}</span>
                </div>

                <p style={{ fontSize: '14px', fontWeight: 600, marginBottom: '6px' }}>
                  <strong>Problema Detectado:</strong> {aiResult.problem}
                </p>

                <p style={{ fontSize: '16px', fontWeight: 800, color: '#34C759', marginBottom: '16px' }}>
                  Presupuesto Estimado: ${aiResult.minPrice.toLocaleString('es-CL')} - ${aiResult.maxPrice.toLocaleString('es-CL')} CLP
                </p>

                <h4 style={{ fontSize: '14px', fontWeight: 700, marginBottom: '10px' }}>Profesionales Verificados Recomendados:</h4>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '12px' }}>
                  {aiResult.workers.map(w => (
                    <div key={w.id} style={{ padding: '12px', borderRadius: 'var(--radius-md)', backgroundColor: darkMode ? 'var(--bg-surface-dark)' : 'white', border: '1px solid var(--border-light)', display: 'flex', alignItems: 'center', gap: '12px' }}>
                      <img src={w.photoUrl} alt={w.name} style={{ width: '48px', height: '48px', borderRadius: '50%', objectFit: 'cover' }} />
                      <div style={{ flex: 1 }}>
                        <h5 style={{ fontSize: '14px', fontWeight: 700 }}>{w.name}</h5>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: '#F0782A' }}>
                          <Star size={12} fill="#F0782A" /> {w.rating} ({w.jobsDone} trabajos)
                        </div>
                      </div>
                      <button 
                        onClick={() => setSelectedWorker(w)}
                        style={{ padding: '6px 12px', backgroundColor: '#F0782A', color: 'white', border: 'none', borderRadius: 'var(--radius-pill)', fontWeight: 700, fontSize: '12px', cursor: 'pointer' }}
                      >
                        Pedir
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* 3. Categorías de Servicio en 3D */}
      <section style={{ padding: '40px 0 60px' }}>
        <div className="container">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '24px' }}>
            <div>
              <h2 style={{ fontSize: '28px', fontWeight: 800 }}>Oficios Disponibles</h2>
              <p style={{ fontSize: '14px', color: 'var(--text-muted-light)' }}>Explora los profesionales verificados listos para tu servicio</p>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: '20px' }}>
            {CATEGORIES.map(cat => {
              const IconComp = cat.icon;
              return (
                <div key={cat.id} className="card-3d" style={{ overflow: 'hidden', padding: 0, cursor: 'pointer' }} onClick={() => analyzeQuery(`Necesito un ${cat.title}`)}>
                  <div style={{ height: '140px', position: 'relative', overflow: 'hidden' }}>
                    <img src={cat.photo} alt={cat.title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                    <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(to top, rgba(0,0,0,0.7), transparent)' }} />
                    <div style={{ position: 'absolute', bottom: '12px', left: '16px', display: 'flex', alignItems: 'center', gap: '8px', color: 'white' }}>
                      <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: '#F0782A', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <IconComp size={18} />
                      </div>
                      <span style={{ fontWeight: 800, fontSize: '16px' }}>{cat.title}</span>
                    </div>
                  </div>
                  <div style={{ padding: '14px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: 'var(--text-muted-light)' }}>Atención Inmediata</span>
                    <ArrowRight size={16} color="#F0782A" />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Modal de Reserva Rápida */}
      {selectedWorker && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 200, backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(8px)', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
          <div className="card-3d" style={{ maxWidth: '500px', width: '100%', position: 'relative' }}>
            <button onClick={() => { setSelectedWorker(null); setBookingConfirmed(false); }} style={{ position: 'absolute', right: '16px', top: '16px', background: 'none', border: 'none', cursor: 'pointer', color: 'inherit' }}>
              <X size={20} />
            </button>

            {!bookingConfirmed ? (
              <>
                <h3 style={{ fontSize: '20px', fontWeight: 800, marginBottom: '16px' }}>Solicitar Servicio Web</h3>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px', padding: '12px', backgroundColor: darkMode ? 'var(--bg-elevated-dark)' : 'var(--bg-elevated-light)', borderRadius: 'var(--radius-md)' }}>
                  <img src={selectedWorker.photoUrl} alt={selectedWorker.name} style={{ width: '56px', height: '56px', borderRadius: '50%', objectFit: 'cover' }} />
                  <div>
                    <h4 style={{ fontSize: '16px', fontWeight: 800 }}>{selectedWorker.name}</h4>
                    <p style={{ fontSize: '13px', color: '#F0782A', fontWeight: 600 }}>{selectedWorker.profession}</p>
                    <span style={{ fontSize: '12px', color: 'var(--text-muted-light)' }}>Visita inicial: ${selectedWorker.pricePerVisit.toLocaleString('es-CL')} CLP</span>
                  </div>
                </div>

                <div style={{ marginBottom: '20px', padding: '14px', backgroundColor: 'rgba(52, 199, 89, 0.12)', border: '1px solid #34C759', borderRadius: 'var(--radius-md)', display: 'flex', gap: '10px' }}>
                  <ShieldCheck color="#34C759" size={24} />
                  <div>
                    <h5 style={{ fontSize: '13px', fontWeight: 800, color: '#34C759' }}>Garantía 100% Escrow MyWorks Protect</h5>
                    <p style={{ fontSize: '11px', color: 'var(--text-muted-light)' }}>El pago queda retenido de forma segura hasta que confirmes la entrega conforme.</p>
                  </div>
                </div>

                <button 
                  onClick={() => setShowCheckout(true)}
                  className="btn-primary" 
                  style={{ width: '100%', justifyContent: 'center', marginBottom: '10px' }}
                >
                  <CreditCard size={18} /> Pagar vía Webpay / Mercado Pago
                </button>
              </>
            ) : (
              <div style={{ textAlign: 'center', padding: '20px 0' }}>
                <CheckCircle2 color="#34C759" size={56} style={{ margin: '0 auto 16px' }} />
                <h3 style={{ fontSize: '22px', fontWeight: 900, marginBottom: '8px' }}>¡Solicitud y Pago Confirmados!</h3>
                <p style={{ fontSize: '14px', color: 'var(--text-muted-light)', marginBottom: '20px' }}>
                  {selectedWorker.name} ha sido notificado y tus fondos de ${selectedWorker.pricePerVisit.toLocaleString('es-CL')} CLP están resguardados en Escrow.
                </p>

                {/* Mapa de Seguimiento GPS en Tiempo Real ETA */}
                <div style={{ marginTop: '20px', marginBottom: '20px' }}>
                  <LiveGpsTrackingMap 
                    workerName={selectedWorker.name}
                    workerProfession={selectedWorker.profession}
                    etaMinutes={7}
                  />
                </div>

                <div style={{ display: 'flex', gap: '12px', marginTop: '20px', flexWrap: 'wrap', justifyContent: 'center' }}>
                  <button 
                    onClick={() => generatePdfCertificate({
                      certificateId: 'CERT-2026-9901',
                      clientName: 'Cliente MyWorks',
                      workerName: selectedWorker.name,
                      profession: selectedWorker.profession,
                      serviceDate: new Date().toLocaleDateString('es-CL'),
                      totalAmount: selectedWorker.pricePerVisit,
                      pinCode: '7482',
                      transactionHash: '0x9021a88b1f22e89',
                    })}
                    className="btn-primary"
                    style={{ backgroundColor: 'var(--navy-structure)' }}
                  >
                    <FileText size={16} /> Certificado PDF
                  </button>

                  <button 
                    onClick={() => setShowChat(true)}
                    className="btn-primary"
                    style={{ backgroundColor: '#007AFF' }}
                  >
                    Abrir Chat en Vivo
                  </button>

                  <button onClick={() => { setSelectedWorker(null); setBookingConfirmed(false); }} className="btn-primary">
                    Finalizar
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Modal Checkout Webpay */}
      {showCheckout && selectedWorker && (
        <PaymentCheckoutModal
          workerName={selectedWorker.name}
          profession={selectedWorker.profession}
          basePrice={selectedWorker.pricePerVisit}
          onClose={() => setShowCheckout(false)}
          onSuccess={() => {
            setShowCheckout(false);
            setBookingConfirmed(true);
          }}
        />
      )}

      {/* Widget Chat en Vivo */}
      {showChat && selectedWorker && (
        <LiveChatWidget
          workerName={selectedWorker.name}
          workerPhoto={selectedWorker.photoUrl}
          onClose={() => setShowChat(false)}
        />
      )}

      {/* Spatial Emergency Pulse 3s */}
      {showEmergencyPulse && (
        <SpatialEmergencyPulse
          onClose={() => setShowEmergencyPulse(false)}
          onDispatch={() => {
            setShowEmergencyPulse(false);
            analyzeQuery('Fuga de agua en lavaplatos');
          }}
        />
      )}
    </div>
  );
}

export default App;
