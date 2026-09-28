import { lazy, Suspense } from 'react';
import { ArrowRight, Lock, LogOut, Play, Search as SearchIcon, ShieldCheck, UserPlus } from 'lucide-react';
import { CategoryCard } from '../components/CategoryCard';
import { BrandLogo } from '../components/BrandLogo';
import {
  ALL_SERVICE_CATEGORIES,
  FEATURED_CATEGORIES,
  type ServiceCategory,
} from '../data/serviceCategories';

const AuthModal = lazy(() =>
  import('../components/AuthModal').then((m) => ({ default: m.AuthModal })),
);

const U = 'https://images.unsplash.com';
const img = (id: string) =>
  `${U}/photo-${id}?auto=format&fit=crop&w=640&h=400&q=70`;

type LandingHomeProps = {
  activeNav: string;
  setActiveNav: (value: 'servicios' | 'como-funciona') => void;
  profile: { name: string } | null;
  setShowAuth: (open: boolean) => void;
  logout: () => void;
  authError: string | null;
  clearError: () => void;
  goToCategories: () => void;
  openCategory: (cat: ServiceCategory) => void;
  showAuth: boolean;
};

export function LandingHome({
  activeNav,
  setActiveNav,
  profile,
  setShowAuth,
  logout,
  authError,
  clearError,
  goToCategories,
  openCategory,
  showAuth,
}: LandingHomeProps) {
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

              <button type="button" className="btn-primary" onClick={goToCategories}>

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

            {FEATURED_CATEGORIES.map((cat) => (

              <CategoryCard

                key={cat.id}

                title={cat.title}

                subtitle={cat.subtitle}

                photo={cat.photo}

                onClick={() => openCategory(cat)}

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

                <span>Profesionales verificados • Pago protegido • Tú tienes el control</span>

              </div>

            </div>



            <div className="how-steps-row">

              {[

                {

                  num: '01',

                  icon: UserPlus,

                  title: 'CREA TU CUENTA',

                  text: 'Regístrate en segundos y accede a profesionales verificados del catálogo.',

                },

                {

                  num: '02',

                  icon: SearchIcon,

                  title: 'BUSCA Y COMPARA',

                  text: 'Explora técnicos calificados. Revisa valoraciones, precios y disponibilidad.',

                },

                {

                  num: '03',

                  icon: Lock,

                  title: 'RESERVA Y RECIBE',

                  text: 'El pago queda protegido. Sigues el servicio hasta la entrega.',

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

              <h2>Oficios para tu casa.</h2>

            </div>

            <button type="button" className="categories-v2-link" onClick={goToCategories}>

              VER TODAS LAS CATEGORÍAS <ArrowRight size={14} />

            </button>

          </div>



          <div className="categories-grid categories-grid--8">

            {ALL_SERVICE_CATEGORIES.slice(0, 8).map((cat) => (

              <CategoryCard

                key={cat.id}

                title={cat.title}

                subtitle={cat.subtitle}

                photo={cat.photo}

                variant="grid"

                onClick={() => openCategory(cat)}

              />

            ))}

          </div>

        </div>

      </section>



      <Suspense fallback={null}>
        <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />
      </Suspense>

    </div>

  );
}
