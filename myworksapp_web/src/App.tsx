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
  Home,
  LogIn,
  LogOut,
} from 'lucide-react';
import { PaymentCheckoutModal } from './components/PaymentCheckoutModal';
import { LiveChatWidget } from './components/LiveChatWidget';
import { generatePdfCertificate } from './utils/pdfCertificateGenerator';
import { LiveGpsTrackingMap } from './components/LiveGpsTrackingMap';
import { AuthModal } from './components/AuthModal';
import { useAuth } from './context/AuthContext';
import { supabase } from './supabaseClient';
import {
  createPendingJob,
  fetchServiceByCategory,
  fetchWorkersByCategory,
  toWebWorkerCard,
} from '@myworksapp/shared';

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

const CATEGORIES = [
  { id: 'plomeria', title: 'Gásfiter / Plomería', icon: Wrench, photo: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=600' },
  { id: 'electricidad', title: 'Electricidad SEC', icon: Zap, photo: 'https://images.unsplash.com/photo-1581092918056-0c4c3acd3789?w=600' },
  { id: 'limpieza', title: 'Limpieza e Higiene', icon: Sparkles, photo: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600' },
  { id: 'ensamblaje', title: 'Armado Muebles', icon: PackageCheck, photo: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=600' },
  { id: 'mudanza', title: 'Mudanzas y Fletes', icon: Truck, photo: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600' },
  { id: 'soporte_tecnico', title: 'Soporte PC / WiFi', icon: Laptop, photo: 'https://images.unsplash.com/photo-1588702547919-26089e690ecc?w=600' },
  { id: 'jardinera', title: 'Jardines y Poda', icon: Flower2, photo: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=600' },
  { id: 'construccion', title: 'Maestro Albañil', icon: Hammer, photo: 'https://images.unsplash.com/photo-1541888946425-d0fbb186a5b7?w=600' },
];

export function App() {
  const { profile, logout, error: authError, clearError } = useAuth();
  const [darkMode, setDarkMode] = useState(false);
  const [query, setQuery] = useState('');
  const [aiResult, setAiResult] = useState<AiResult | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [selectedWorker, setSelectedWorker] = useState<Worker | null>(null);
  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);
  const [bookingConfirmed, setBookingConfirmed] = useState(false);
  const [showCheckout, setShowCheckout] = useState(false);
  const [showChat, setShowChat] = useState(false);
  const [showAuth, setShowAuth] = useState(false);
  const [bookingError, setBookingError] = useState<string | null>(null);

  useEffect(() => {
    if (darkMode) {
      document.body.classList.add('dark');
    } else {
      document.body.classList.remove('dark');
    }
  }, [darkMode]);

  const analyzeQuery = async (text: string) => {
    if (!text.trim()) return;
    setIsAnalyzing(true);
    setQuery(text);

    const lower = text.toLowerCase();
    let category = 'electricidad';
    let categoryName = 'Electricista Certificado';
    let problem = 'Diagnóstico y reparación de falla eléctrica';
    let minPrice = 25000;
    let maxPrice = 60000;
    let urgency = 'Media';
    let tools = ['Tester digital', 'Alicate pelacables', 'Breaker sustituto'];

    if (lower.includes('fuga') || lower.includes('agua') || lower.includes('lavaplatos') || lower.includes('llave') || lower.includes('gasfiter')) {
      category = 'plomeria';
      categoryName = 'Gásfiter / Plomero SEC';
      problem = 'Reparación de fuga de agua y cambio de llaves o grifería';
      minPrice = 30000;
      maxPrice = 75000;
      urgency = 'Alta';
      tools = ['Soplete', 'Llave francesa', 'Sellante de teflón'];
    } else if (lower.includes('mueble') || lower.includes('armar') || lower.includes('closet') || lower.includes('rack')) {
      category = 'ensamblaje';
      categoryName = 'Armado de Muebles';
      problem = 'Montaje e instalación de mueble listo para armar';
      minPrice = 20000;
      maxPrice = 45000;
      urgency = 'Normal';
      tools = ['Atornillador inalámbrico', 'Nivel de gota', 'Juego Allen'];
    } else if (
      lower.includes('limpieza') ||
      lower.includes('limpia') ||
      lower.includes('aseo') ||
      lower.includes('higien') ||
      lower.includes('departamento')
    ) {
      category = 'limpieza';
      categoryName = 'Limpieza e Higiene';
      problem = 'Servicio de limpieza residencial u oficina';
      minPrice = 25000;
      maxPrice = 55000;
      urgency = 'Normal';
      tools = ['Aspiradora industrial', 'Químicos certificados'];
    } else if (lower.includes('mudanza') || lower.includes('flete')) {
      category = 'mudanza';
      categoryName = 'Mudanzas y Fletes';
      problem = 'Traslado de enseres y mobiliario';
      minPrice = 40000;
      maxPrice = 120000;
      urgency = 'Media';
      tools = ['Camión', 'Cintas', 'Frazadas'];
    } else if (lower.includes('jardín') || lower.includes('jardin') || lower.includes('poda')) {
      category = 'jardinera';
      categoryName = 'Jardines y Poda';
      problem = 'Mantención de áreas verdes';
      minPrice = 20000;
      maxPrice = 50000;
      urgency = 'Normal';
      tools = ['Tijera de poda', 'Cortacésped'];
    } else if (lower.includes('pc') || lower.includes('wifi') || lower.includes('computador')) {
      category = 'soporte_tecnico';
      categoryName = 'Soporte PC / WiFi';
      problem = 'Diagnóstico de red o equipo';
      minPrice = 20000;
      maxPrice = 45000;
      urgency = 'Media';
      tools = ['Laptop diagnóstico', 'Cable tester'];
    } else if (lower.includes('albañ') || lower.includes('muro') || lower.includes('cemento')) {
      category = 'construccion';
      categoryName = 'Maestro Albañil';
      problem = 'Trabajo de albañilería y terminaciones';
      minPrice = 35000;
      maxPrice = 90000;
      urgency = 'Media';
      tools = ['Nivel', 'Paleta', 'Mezcladora'];
    }

    try {
      const [service, workersRaw] = await Promise.all([
        fetchServiceByCategory(supabase, category),
        fetchWorkersByCategory(supabase, category),
      ]);
      setSelectedServiceId(service?.id ?? null);
      const workers = workersRaw.map((worker) => toWebWorkerCard(worker));

      setAiResult({
        category,
        categoryName,
        problem,
        minPrice,
        maxPrice,
        urgency,
        tools,
        workers,
      });
    } catch {
      setSelectedServiceId(null);
      setAiResult({
        category,
        categoryName,
        problem,
        minPrice,
        maxPrice,
        urgency,
        tools,
        workers: [],
      });
    } finally {
      setIsAnalyzing(false);
    }
  };

  const requestWorker = (worker: Worker) => {
    if (!profile) {
      setShowAuth(true);
      return;
    }
    setSelectedWorker(worker);
    setBookingConfirmed(false);
    setBookingError(null);
  };

  const confirmBooking = async () => {
    if (!profile || !selectedWorker) return;
    if (!selectedServiceId) {
      setBookingError('No hay un servicio activo en Supabase para esta categoría.');
      return;
    }

    try {
      await createPendingJob(supabase, {
        userId: profile.id,
        workerId: selectedWorker.id,
        serviceId: selectedServiceId,
        description: aiResult?.problem ?? query,
      });
      setBookingConfirmed(true);
      setBookingError(null);
    } catch {
      setBookingError('No se pudo crear la solicitud en Supabase. Verifica tu sesión.');
    }
  };

  return (
    <div className="min-h-screen app-shell">
      <nav className="glass-nav" style={{ position: 'relative', zIndex: 10 }}>
        <div className="container nav-inner">
          <div className="nav-brand">
            <div className="nav-logo" aria-hidden>
              <Home size={32} color={darkMode ? '#FFFFFF' : '#0B192C'} />
              <Wrench size={14} color="#F0782A" className="nav-logo-wrench" />
            </div>
            <div>
              <span className="nav-title">My Works App</span>
              <span className="nav-chip">Cliente</span>
            </div>
          </div>

          <div className="nav-actions">
            {profile ? (
              <>
                <span className="nav-hello">Hola, {profile.name.split(' ')[0]}</span>
                <button type="button" className="btn-ghost" onClick={() => void logout()}>
                  <LogOut size={16} /> Salir
                </button>
              </>
            ) : (
              <button type="button" className="btn-ghost" onClick={() => setShowAuth(true)}>
                <LogIn size={16} /> Entrar
              </button>
            )}

            <button type="button" className="btn-ghost" onClick={() => setDarkMode(!darkMode)} aria-label="Cambiar tema">
              {darkMode ? <Sun size={16} /> : <Moon size={16} />}
              <span className="nav-theme-label">{darkMode ? 'Claro' : 'Oscuro'}</span>
            </button>
          </div>
        </div>
      </nav>

      {authError && (
        <div className="auth-banner container" role="alert">
          <p>{authError}</p>
          <button
            type="button"
            className="btn-ghost"
            onClick={() => {
              clearError();
              setShowAuth(true);
            }}
          >
            Entendido
          </button>
        </div>
      )}

      <section className="hero-section">
        <div className="container">
          <div className="hero-rise hero-copy">
            <p className="badge-tag badge-orange">Marketplace de oficios · Chile</p>
            <h1 className="brand-display hero-brand">My Works App</h1>
            <p className="hero-lead">
              Encuentra profesionales verificados cerca de ti y reserva en minutos.
            </p>
            <div className="hero-cta-row">
              <button
                type="button"
                className="btn-primary"
                onClick={() => document.getElementById('search-box')?.scrollIntoView({ behavior: 'smooth', block: 'center' })}
              >
                Buscar un oficio
              </button>
              {!profile && (
                <button type="button" className="btn-ghost" onClick={() => setShowAuth(true)}>
                  Crear cuenta
                </button>
              )}
            </div>
          </div>

          <div id="search-box" className="card-3d search-card">
            <div className="search-row">
              <div className="search-input-wrap">
                <input
                  type="text"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && void analyzeQuery(query)}
                  placeholder='Ej: "Fuga de agua en el lavaplatos"'
                  className="search-input"
                  style={{ background: darkMode ? 'var(--bg-elevated-dark)' : 'var(--bg-elevated-light)', color: 'inherit' }}
                />
                <Search size={20} className="search-icon" />
              </div>

              <button
                type="button"
                onClick={() => void analyzeQuery(query)}
                disabled={isAnalyzing}
                className="btn-primary search-submit"
              >
                {isAnalyzing ? 'Buscando…' : 'Buscar'}
              </button>
            </div>

            <div className="chip-row">
              <span className="chip-label">Sugerencias:</span>
              {[
                'Fuga de agua en lavaplatos',
                'Enchufe quemado en la cocina',
                'Armado de clóset 3 puertas',
                'Limpieza profunda departamento',
              ].map((prompt) => (
                <button
                  key={prompt}
                  type="button"
                  onClick={() => void analyzeQuery(prompt)}
                  className="chip-btn"
                  style={{ background: darkMode ? 'var(--bg-elevated-dark)' : 'var(--orange-soft)' }}
                >
                  {prompt}
                </button>
              ))}
            </div>

            {aiResult && (
              <div className="result-panel">
                <div className="result-header">
                  <div className="result-title-row">
                    <CheckCircle2 color="#2F9E64" size={22} />
                    <h3>{aiResult.categoryName}</h3>
                  </div>
                  <span className="badge-tag badge-orange">{aiResult.urgency}</span>
                </div>

                <p className="result-problem">
                  <strong>Problema:</strong> {aiResult.problem}
                </p>
                <p className="result-price">
                  Estimado: ${aiResult.minPrice.toLocaleString('es-CL')} – ${aiResult.maxPrice.toLocaleString('es-CL')} CLP
                </p>

                <h4 className="result-workers-label">Profesionales disponibles</h4>
                {aiResult.workers.length === 0 ? (
                  <p className="muted-note">No hay profesionales disponibles para esta categoría por ahora.</p>
                ) : (
                  <div className="workers-grid">
                    {aiResult.workers.map((w) => (
                      <div key={w.id} className="worker-card" style={{ backgroundColor: darkMode ? 'var(--bg-surface-dark)' : 'white' }}>
                        <img src={w.photoUrl} alt={w.name} className="worker-photo" />
                        <div className="worker-meta">
                          <h5>{w.name}</h5>
                          <div className="worker-rating">
                            <Star size={12} fill="#F0782A" /> {w.rating} ({w.jobsDone} trabajos)
                          </div>
                        </div>
                        <button type="button" className="btn-ask" onClick={() => requestWorker(w)}>
                          Pedir
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </section>

      <section className="categories-section">
        <div className="container">
          <div className="section-head">
            <h2>Oficios disponibles</h2>
            <p>Explora categorías y conecta con profesionales verificados</p>
          </div>

          <div className="categories-grid">
            {CATEGORIES.map((cat) => {
              const IconComp = cat.icon;
              return (
                <button
                  key={cat.id}
                  type="button"
                  className="card-3d category-card"
                  onClick={() => void analyzeQuery(`Necesito un ${cat.title}`)}
                >
                  <div className="category-media">
                    <img src={cat.photo} alt={cat.title} />
                    <div className="category-media-fade" />
                    <div className="category-media-label">
                      <span className="category-icon">
                        <IconComp size={18} />
                      </span>
                      <span>{cat.title}</span>
                    </div>
                  </div>
                  <div className="category-footer">
                    <span>Ver profesionales</span>
                    <ArrowRight size={16} color="#F0782A" />
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </section>

      {selectedWorker && (
        <div className="modal-backdrop">
          <div className="card-3d modal-card">
            <button
              type="button"
              className="modal-close"
              onClick={() => {
                setSelectedWorker(null);
                setBookingConfirmed(false);
              }}
              aria-label="Cerrar"
            >
              <X size={20} />
            </button>

            {!bookingConfirmed ? (
              <>
                <h3 className="modal-title">Solicitar servicio</h3>
                <div className="booking-worker" style={{ backgroundColor: darkMode ? 'var(--bg-elevated-dark)' : 'var(--bg-elevated-light)' }}>
                  <img src={selectedWorker.photoUrl} alt={selectedWorker.name} />
                  <div>
                    <h4>{selectedWorker.name}</h4>
                    <p>{selectedWorker.profession}</p>
                    <span>Visita inicial: ${selectedWorker.pricePerVisit.toLocaleString('es-CL')} CLP</span>
                  </div>
                </div>

                <div className="demo-note">
                  <ShieldCheck color="#F0782A" size={22} />
                  <div>
                    <h5>Pago en escrow (próximamente)</h5>
                    <p>
                      El checkout actual es una <strong>simulación / demo</strong>: no hay cobro real ni retención de fondos.
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => setShowCheckout(true)}
                  className="btn-primary"
                  style={{ width: '100%', justifyContent: 'center', marginBottom: '10px' }}
                >
                  <CreditCard size={18} /> Continuar al checkout demo
                </button>
                {bookingError && <p className="error-text">{bookingError}</p>}
              </>
            ) : (
              <div className="booking-done">
                <CheckCircle2 color="#2F9E64" size={56} />
                <h3>Solicitud creada</h3>
                <p>
                  {selectedWorker.name} fue notificado. El pago simulado fue de ${selectedWorker.pricePerVisit.toLocaleString('es-CL')} CLP
                  (sin cobro real).
                </p>

                <div className="tracking-wrap">
                  <LiveGpsTrackingMap
                    workerName={selectedWorker.name}
                    workerProfession={selectedWorker.profession}
                    etaMinutes={7}
                  />
                </div>

                <div className="booking-actions">
                  <button
                    type="button"
                    onClick={() =>
                      generatePdfCertificate({
                        certificateId: 'CERT-DEMO-9901',
                        clientName: profile?.name ?? 'Cliente MyWorks',
                        workerName: selectedWorker.name,
                        profession: selectedWorker.profession,
                        serviceDate: new Date().toLocaleDateString('es-CL'),
                        totalAmount: selectedWorker.pricePerVisit,
                        pinCode: '7482',
                        transactionHash: 'demo-tx-9021a88b',
                      })
                    }
                    className="btn-primary"
                    style={{ backgroundColor: 'var(--navy-structure)' }}
                  >
                    <FileText size={16} /> Comprobante PDF
                  </button>

                  <button type="button" onClick={() => setShowChat(true)} className="btn-primary" style={{ backgroundColor: '#1A2740' }}>
                    Abrir chat
                  </button>

                  <button
                    type="button"
                    onClick={() => {
                      setSelectedWorker(null);
                      setBookingConfirmed(false);
                    }}
                    className="btn-primary"
                  >
                    Finalizar
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {showCheckout && selectedWorker && (
        <PaymentCheckoutModal
          workerName={selectedWorker.name}
          profession={selectedWorker.profession}
          basePrice={selectedWorker.pricePerVisit}
          onClose={() => setShowCheckout(false)}
          onSuccess={() => {
            setShowCheckout(false);
            void confirmBooking();
          }}
        />
      )}

      {showChat && selectedWorker && (
        <LiveChatWidget
          workerName={selectedWorker.name}
          workerPhoto={selectedWorker.photoUrl}
          onClose={() => setShowChat(false)}
        />
      )}

      <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />
    </div>
  );
}

export default App;
