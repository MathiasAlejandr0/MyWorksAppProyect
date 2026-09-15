import { useState, useEffect } from 'react';

import {
  ShieldCheck,
  LogOut,
  Play,
  UserPlus,
  Search as SearchIcon,
  Lock,
  ArrowRight,
} from 'lucide-react';

import { PaymentCheckoutModal } from './components/PaymentCheckoutModal';

import { LiveChatWidget } from './components/LiveChatWidget';

import { AuthModal } from './components/AuthModal';

import { CategoryCard } from './components/CategoryCard';

import { BrandLogo } from './components/BrandLogo';

import { SearchResultsView, type SearchWorker } from './components/SearchResultsView';

import { QuickBookingBar } from './components/QuickBookingBar';

import { TrackingDashboard } from './components/TrackingDashboard';

import { useAuth } from './context/AuthContext';

import { supabase } from './supabaseClient';

import {

  createPendingJob,

  fetchServiceByCategory,

  fetchWorkersByCategory,

  toWebWorkerCard,

} from '@myworksapp/shared';



type AppView = 'landing' | 'search' | 'tracking';



const U = 'https://images.unsplash.com';

const img = (id: string) =>

  `${U}/photo-${id}?auto=format&fit=crop&w=900&h=560&q=80`;



const CATEGORIES = [

  {

    id: 'ensamblaje',

    title: 'Armado',

    subtitle: 'Muebles, estanterías y más',

    photo: img('1555041469-a586c61e8bc7'),

  },

  {

    id: 'electricidad',

    title: 'Electricidad',

    subtitle: 'Instalaciones, reparaciones y más',

    photo: img('1621905251189-08b45d6a269e'),

  },

  {

    id: 'plomeria',

    title: 'Plomería',

    subtitle: 'Fugas, instalaciones y más',

    photo: img('1585703903930-0b8e341a0895'),

  },

  {

    id: 'gasfiteria',

    title: 'Gasfitería',

    subtitle: 'Conexiones, revisiones y más',

    photo: img('1581578731548-c64695cc6952'),

  },

];



interface ServiceMatch {

  category: string;

  categoryName: string;

  problem: string;

  minPrice: number;

  maxPrice: number;

  urgency: string;

  workers: SearchWorker[];

}



function resolveCategory(text: string) {

  const lower = text.toLowerCase();

  let category = 'electricidad';

  let categoryName = 'Electricista Certificado';

  let problem = 'Diagnóstico y reparación de falla eléctrica';

  let minPrice = 25000;

  let maxPrice = 60000;



  if (

    lower.includes('fuga') ||

    lower.includes('agua') ||

    lower.includes('lavaplatos') ||

    lower.includes('llave') ||

    lower.includes('gasfiter') ||

    lower.includes('plomer')

  ) {

    category = 'plomeria';

    categoryName = 'Gásfiter / Plomero SEC';

    problem = 'Reparación de fuga de agua y cambio de llaves o grifería';

    minPrice = 30000;

    maxPrice = 75000;

  } else if (

    lower.includes('mueble') ||

    lower.includes('armar') ||

    lower.includes('closet') ||

    lower.includes('rack') ||

    lower.includes('armado')

  ) {

    category = 'ensamblaje';

    categoryName = 'Armado de Muebles';

    problem = 'Montaje e instalación de mueble listo para armar';

    minPrice = 20000;

    maxPrice = 45000;

  } else if (lower.includes('electric')) {

    category = 'electricidad';

    categoryName = 'Electricista Certificado';

    problem = 'Instalaciones y reparaciones eléctricas';

  }



  return { category, categoryName, problem, minPrice, maxPrice, urgency: 'Media' as const };

}



export function App() {

  const { profile, logout, error: authError, clearError } = useAuth();

  const [view, setView] = useState<AppView>('landing');

  const [query, setQuery] = useState('');

  const [serviceMatch, setServiceMatch] = useState<ServiceMatch | null>(null);

  const [isSearching, setIsSearching] = useState(false);

  const [selectedWorker, setSelectedWorker] = useState<SearchWorker | null>(null);

  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);

  const [showCheckout, setShowCheckout] = useState(false);

  const [showChat, setShowChat] = useState(false);

  const [showAuth, setShowAuth] = useState(false);

  const [bookingError, setBookingError] = useState<string | null>(null);

  const [activeNav, setActiveNav] = useState<'servicios' | 'como-funciona'>('servicios');



  useEffect(() => {

    document.body.classList.add('dark');

    localStorage.setItem('mwa-dark-mode', '1');

  }, []);



  const searchService = async (text: string) => {

    if (!text.trim()) return;

    setIsSearching(true);

    setServiceMatch(null);

    setQuery(text);

    setView('search');

    setSelectedWorker(null);



    const meta = resolveCategory(text);



    try {

      const [service, workersRaw] = await Promise.all([

        fetchServiceByCategory(supabase, meta.category),

        fetchWorkersByCategory(supabase, meta.category),

      ]);

      setSelectedServiceId(service?.id ?? null);

      const workers: SearchWorker[] = workersRaw.map((worker) => ({

        ...toWebWorkerCard(worker),

        availableNow: true,

      }));



      setServiceMatch({ ...meta, workers });

    } catch {

      setSelectedServiceId(null);

      setServiceMatch({ ...meta, workers: [] });

    } finally {

      setIsSearching(false);

    }

  };



  const requestWorker = (worker: SearchWorker) => {

    if (!profile) {

      setShowAuth(true);

      return;

    }

    setSelectedWorker(worker);

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

        description: serviceMatch?.problem ?? query,

      });

      setBookingError(null);

      setShowCheckout(false);

      setView('tracking');

    } catch {

      setBookingError('No se pudo crear la solicitud. Verifica tu sesión.');

    }

  };



  const goToSearch = () => {

    setView('search');

    if (!query) setQuery('electricistas');

    if (!serviceMatch) void searchService(query || 'electricistas');

  };



  if (view === 'tracking' && selectedWorker) {

    return (

      <div className="min-h-screen app-shell">

        <TrackingDashboard

          workerName={selectedWorker.name}

          workerProfession={selectedWorker.profession}

          workerPhoto={selectedWorker.photoUrl}

          workerRating={selectedWorker.rating}

          workerJobs={selectedWorker.jobsDone}

          serviceTitle={serviceMatch?.categoryName ?? 'Instalación Eléctrica'}

          serviceLocation={`Casa Particular • Las Condes, Santiago`}

          orderId="MW-7821"

          etaMinutes={18}

          distanceKm={4.2}

          profileName={profile?.name}

          onBack={() => setView('search')}

          onOpenChat={() => setShowChat(true)}

        />

        {showChat && (

          <LiveChatWidget

            workerName={selectedWorker.name}

            workerPhoto={selectedWorker.photoUrl}

            onClose={() => setShowChat(false)}

          />

        )}

      </div>

    );

  }



  if (view === 'search') {

    return (

      <div className="min-h-screen app-shell app-shell--search">

        <SearchResultsView

          query={query}

          workers={serviceMatch?.workers ?? []}

          isLoading={isSearching}

          profileName={profile?.name}

          selectedWorkerId={selectedWorker?.id ?? null}

          onQueryChange={setQuery}

          onSearch={searchService}

          onSelectWorker={requestWorker}

          onBack={() => {

            setView('landing');

            setSelectedWorker(null);

          }}

          onShowAuth={() => setShowAuth(true)}

        />



        {selectedWorker && (

          <QuickBookingBar

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            pricePerHour={Math.round(selectedWorker.pricePerVisit / 1000) * 1000 || 35000}

            onContinue={() => setShowCheckout(true)}

            onClose={() => setSelectedWorker(null)}

          />

        )}



        {showCheckout && selectedWorker && (

          <PaymentCheckoutModal

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            basePrice={selectedWorker.pricePerVisit}

            serviceDescription={serviceMatch?.problem}

            onClose={() => setShowCheckout(false)}

            onSuccess={() => void confirmBooking()}

          />

        )}



        {bookingError && (

          <div className="toast-error" role="alert">

            {bookingError}

          </div>

        )}



        <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />

      </div>

    );

  }



  return (

    <div className="min-h-screen app-shell">

      <nav className="glass-nav">

        <div className="container nav-inner">

          <BrandLogo size={36} />



          <div className="nav-links-center">

            <a

              href="#categorias"

              className={`nav-link${activeNav === 'servicios' ? ' is-active' : ''}`}

              onClick={() => setActiveNav('servicios')}

            >

              Servicios

            </a>

            <a

              href="#como-funciona"

              className={`nav-link${activeNav === 'como-funciona' ? ' is-active' : ''}`}

              onClick={() => setActiveNav('como-funciona')}

            >

              Cómo funciona

            </a>

            {!profile && (

              <button type="button" className="nav-link nav-link-btn" onClick={() => setShowAuth(true)}>

                Ingresar

              </button>

            )}

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

              <button type="button" className="btn-outline-orange" onClick={() => setShowAuth(true)}>

                Registrarse

              </button>

            )}

          </div>

        </div>

      </nav>



      {authError && (

        <div className="auth-banner container page-fade-in" role="alert">

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



      <section className="hero-section page-fade-in">

        <div className="container hero-split">

          <div className="hero-rise hero-copy">

            <h1 className="brand-display hero-brand">

              My Works App

              <br />

              <span className="hero-accent">Profesionales de confianza</span>

              <br />

              para tu hogar

            </h1>

            <p className="hero-lead">

              Conectamos tu hogar con técnicos verificados, calificados y cercanos. Rápido, seguro y sin complicaciones.

            </p>

            <div className="hero-cta-row">

              <button type="button" className="btn-primary" onClick={goToSearch}>

                Buscar servicio <ArrowRight size={18} />

              </button>

              <a href="#como-funciona" className="btn-ghost hero-ghost">

                <span className="hero-play" aria-hidden>

                  <Play size={12} fill="currentColor" />

                </span>

                Cómo funciona

              </a>

            </div>

          </div>



          <div className="hero-visual">

            <img

              className="hero-photo"

              src={img('1621905251189-08b45d6a269e')}

              alt="Técnico profesional en domicilio"

            />

            <div className="hero-float-card hero-float-trust">

              <div className="hero-float-head">

                <ShieldCheck size={16} color="var(--orange-accent)" />

                <span>Confianza verificada</span>

              </div>

              <strong className="hero-float-metric">99.4%</strong>

              <p>Calificación promedio de profesionales</p>

              <div className="hero-progress"><span /></div>

            </div>

            <div className="hero-float-card hero-float-eta">

              <div className="hero-float-head">

                <span>Llegada estimada</span>

              </div>

              <strong className="hero-float-metric white">18 min</strong>

              <p>Técnico en camino</p>

              <div className="hero-mini-map" aria-hidden>

                <div className="hero-mini-route" />

                <div className="hero-mini-pin" />

              </div>

            </div>

          </div>

        </div>

      </section>



      <section id="categorias" className="categories-section section-fade-in">

        <div className="container">

          <div className="section-head section-head--center">

            <p className="section-kicker">CATEGORÍAS POPULARES</p>

          </div>



          <div className="categories-grid">

            {CATEGORIES.map((cat) => (

              <CategoryCard

                key={cat.id}

                title={cat.title}

                subtitle={cat.subtitle}

                photo={cat.photo}

                onClick={() => void searchService(`Necesito ${cat.title.toLowerCase()}`)}

              />

            ))}

          </div>

        </div>

      </section>



      <section id="como-funciona" className="how-section-v2 section-fade-in">

        <div className="container">

          <div className="how-section-v2-head">

            <div>

              <p className="section-kicker">CÓMO FUNCIONA</p>

              <h2>

                Simple. Seguro. Confiable.

                <br />

                Consigue lo que necesitas.

              </h2>

              <p className="how-section-v2-lead">

                My Works App conecta tu hogar con profesionales verificados, con pago protegido y seguimiento en tiempo real.

              </p>

              <div className="how-trust-row">

                <ShieldCheck size={16} color="var(--orange-accent)" />

                <span>Profesionales verificados • Pago en escrow • Tú tienes el control</span>

              </div>

            </div>



            <div className="how-steps-row">

              {[

                {

                  num: '01',

                  icon: UserPlus,

                  title: 'CREA TU CUENTA',

                  text: 'Regístrate en segundos y accede a profesionales verificados cerca de ti.',

                },

                {

                  num: '02',

                  icon: SearchIcon,

                  title: 'BUSCA Y COMPARA',

                  text: 'Explora técnicos calificados. Revisa ratings, precios y disponibilidad.',

                },

                {

                  num: '03',

                  icon: Lock,

                  title: 'RESERVA Y RECIBE',

                  text: 'Paga con escrow protegido. Sigue el servicio hasta la entrega.',

                },

              ].map((step, i) => {

                const Icon = step.icon;

                return (

                  <div key={step.num} className="how-step-card">

                    {i > 0 && <span className="how-step-arrow" aria-hidden>→</span>}

                    <span className="how-step-num">{step.num}</span>

                    <div className="how-step-icon">

                      <Icon size={22} />

                    </div>

                    <h3>{step.title}</h3>

                    <p>{step.text}</p>

                  </div>

                );

              })}

            </div>

          </div>



          <div className="categories-v2-header">

            <div>

              <p className="section-kicker">CATEGORÍAS</p>

              <h2>Premium Services. Curated for You.</h2>

            </div>

            <button type="button" className="categories-v2-link" onClick={goToSearch}>

              VER TODAS LAS CATEGORÍAS <ArrowRight size={14} />

            </button>

          </div>



          <div className="categories-grid categories-grid--8">

            {[

              ...CATEGORIES,

              {

                id: 'limpieza',

                title: 'Limpieza',

                subtitle: 'Hogar, oficina y profunda',

                photo: img('1581578749516-86a3a74134a8'),

              },

              {

                id: 'pintura',

                title: 'Pintura',

                subtitle: 'Interiores y exteriores',

                photo: img('1562259949-e8e7689d7828'),

              },

              {

                id: 'jardineria',

                title: 'Jardinería',

                subtitle: 'Poda, riego y mantención',

                photo: img('1416879595882-3373a0480b5b'),

              },

              {

                id: 'cerrajeria',

                title: 'Cerrajería',

                subtitle: 'Aperturas y cambio de chapas',

                photo: img('1558002032-589707903656'),

              },

            ].map((cat) => (

              <CategoryCard

                key={cat.id}

                title={cat.title}

                subtitle={cat.subtitle}

                photo={cat.photo}

                variant="grid"

                onClick={() => void searchService(`Necesito ${cat.title.toLowerCase()}`)}

              />

            ))}

          </div>

        </div>

      </section>



      <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />

    </div>

  );

}



export default App;

