import { useState, useEffect, lazy, Suspense } from 'react';
import { useQueryClient } from '@tanstack/react-query';

import { LandingHome } from './views/LandingHome';
import type { SearchWorker } from './components/SearchResultsView';
import { useAuth } from './context/AuthContext';
import { supabase } from './supabaseClient';
import { queryKeys } from './queryClient';
import {
  ALL_SERVICE_CATEGORIES,
  type ServiceCategory,
} from './data/serviceCategories';
import {
  CATALOG_STALE_MS,
  chargeSavedCard,
  createGuestWebpayCheckout,
  createPendingJob,
  fetchActiveServices,
  orderConfirmedMessage,
  openJobForWorker,
  parseCheckoutReturn,
  fetchPaymentStatus,
  fetchServiceByCategory,
  fetchWorkersCatalog,
  toWebWorkerCard,
  type CatalogCursor,
  type WorkerWithProfile,
} from '@myworksapp/shared';

const PaymentCheckoutModal = lazy(() =>
  import('./components/PaymentCheckoutModal').then((m) => ({
    default: m.PaymentCheckoutModal,
  })),
);

const PaidReturnView = lazy(() =>
  import('./components/PaidReturnView').then((m) => ({
    default: m.PaidReturnView,
  })),
);

const GuestCheckoutForm = lazy(() =>
  import('./components/GuestCheckoutForm').then((m) => ({
    default: m.GuestCheckoutForm,
  })),
);

const LiveChatWidget = lazy(() =>
  import('./components/LiveChatWidget').then((m) => ({
    default: m.LiveChatWidget,
  })),
);

const AuthModal = lazy(() =>
  import('./components/AuthModal').then((m) => ({ default: m.AuthModal })),
);

const SearchResultsView = lazy(() =>
  import('./components/SearchResultsView').then((m) => ({
    default: m.SearchResultsView,
  })),
);

const QuickBookingBar = lazy(() =>
  import('./components/QuickBookingBar').then((m) => ({
    default: m.QuickBookingBar,
  })),
);

const TrackingDashboard = lazy(() =>
  import('./components/TrackingDashboard').then((m) => ({
    default: m.TrackingDashboard,
  })),
);

function ViewFallback() {
  return <div className="min-h-screen app-shell" />;
}

type AppView = 'landing' | 'categories' | 'search' | 'tracking' | 'paid';

const CategoriesCatalogView = lazy(() =>
  import('./components/CategoriesCatalogView').then((m) => ({
    default: m.CategoriesCatalogView,
  })),
);



interface ServiceMatch {

  category: string;

  categoryName: string;

  problem: string;

  minPrice: number;

  maxPrice: number;

  urgency: string;

  workers: SearchWorker[];

  nextCursor: CatalogCursor | null;

}



function resolveCategory(text: string) {
  const lower = text.toLowerCase();

  if (
    lower.includes('fuga') ||
    lower.includes('agua') ||
    lower.includes('lavaplatos') ||
    lower.includes('llave') ||
    lower.includes('plomer')
  ) {
    return {
      category: 'plomeria',
      categoryName: 'Gásfiter / Plomero SEC',
      problem: 'Reparación de fuga de agua y cambio de llaves o grifería',
      minPrice: 30000,
      maxPrice: 75000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('gasfiter') || lower.includes('gas ')) {
    return {
      category: 'gasfiteria',
      categoryName: 'Gasfitería',
      problem: 'Conexiones, revisiones y mantención de gas',
      minPrice: 30000,
      maxPrice: 80000,
      urgency: 'Media' as const,
    };
  }

  if (
    lower.includes('mueble') ||
    lower.includes('armar') ||
    lower.includes('closet') ||
    lower.includes('rack') ||
    lower.includes('armado') ||
    lower.includes('ensamblaje')
  ) {
    return {
      category: 'ensamblaje',
      categoryName: 'Armado de Muebles',
      problem: 'Montaje e instalación de mueble listo para armar',
      minPrice: 20000,
      maxPrice: 45000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('limpieza') || lower.includes('aseo')) {
    return {
      category: 'limpieza',
      categoryName: 'Limpieza',
      problem: 'Limpieza del hogar u oficina',
      minPrice: 18000,
      maxPrice: 45000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('pintura') || lower.includes('pintor')) {
    return {
      category: 'pintura',
      categoryName: 'Pintura',
      problem: 'Pintura de interiores o exteriores',
      minPrice: 25000,
      maxPrice: 70000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('jardin') || lower.includes('poda')) {
    return {
      category: 'jardineria',
      categoryName: 'Jardinería',
      problem: 'Poda, riego y mantención de áreas verdes',
      minPrice: 20000,
      maxPrice: 55000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('cerraj') || lower.includes('chapa')) {
    return {
      category: 'cerrajeria',
      categoryName: 'Cerrajería',
      problem: 'Apertura o cambio de chapas',
      minPrice: 22000,
      maxPrice: 60000,
      urgency: 'Alta' as const,
    };
  }

  if (lower.includes('construc') || lower.includes('remodel')) {
    return {
      category: 'construccion',
      categoryName: 'Construcción',
      problem: 'Obras menores y remodelaciones',
      minPrice: 40000,
      maxPrice: 120000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('soporte') || lower.includes('comput') || lower.includes('pc ')) {
    return {
      category: 'soporte_tecnico',
      categoryName: 'Soporte técnico',
      problem: 'Diagnóstico y reparación de equipos',
      minPrice: 20000,
      maxPrice: 50000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('mudanza') || lower.includes('traslado')) {
    return {
      category: 'mudanza',
      categoryName: 'Mudanza',
      problem: 'Traslado y embalaje',
      minPrice: 50000,
      maxPrice: 150000,
      urgency: 'Media' as const,
    };
  }

  if (
    lower.includes('climat') ||
    lower.includes('aire acondicionado') ||
    lower.includes('calefacc')
  ) {
    return {
      category: 'climatizacion',
      categoryName: 'Climatización',
      problem: 'Instalación o mantención de climatización',
      minPrice: 35000,
      maxPrice: 90000,
      urgency: 'Media' as const,
    };
  }

  if (lower.includes('electric') || lower.includes('electricista')) {
    return {
      category: 'electricidad',
      categoryName: 'Electricista Certificado',
      problem: 'Instalaciones y reparaciones eléctricas',
      minPrice: 25000,
      maxPrice: 60000,
      urgency: 'Media' as const,
    };
  }

  // Sin match claro: no forzar electricistas
  return {
    category: 'electricidad',
    categoryName: 'Profesional verificado',
    problem: 'Servicio a domicilio',
    minPrice: 25000,
    maxPrice: 60000,
    urgency: 'Media' as const,
  };
}



export function App() {

  const { profile, logout, error: authError, clearError } = useAuth();
  const queryClient = useQueryClient();

  const [view, setView] = useState<AppView>('landing');

  const [query, setQuery] = useState('');

  const [serviceMatch, setServiceMatch] = useState<ServiceMatch | null>(null);

  const [isSearching, setIsSearching] = useState(false);

  const [selectedWorker, setSelectedWorker] = useState<SearchWorker | null>(null);

  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);

  const [showCheckout, setShowCheckout] = useState(false);

  const [showGuestCheckout, setShowGuestCheckout] = useState(false);

  const [checkoutJobId, setCheckoutJobId] = useState<string | null>(null);

  const [showChat, setShowChat] = useState(false);

  const [showAuth, setShowAuth] = useState(false);

  const [bookingError, setBookingError] = useState<string | null>(null);
  const [catalogError, setCatalogError] = useState<string | null>(null);
  const [loadingMoreWorkers, setLoadingMoreWorkers] = useState(false);
  const [paidVerifying, setPaidVerifying] = useState(false);
  const [paidVerifyError, setPaidVerifyError] = useState<string | null>(null);
  const [paymentNotice, setPaymentNotice] = useState<string | null>(null);

  const [activeNav, setActiveNav] = useState<'servicios' | 'como-funciona'>('servicios');



  useEffect(() => {

    document.body.classList.add('dark');

    localStorage.setItem('mwa-dark-mode', '1');

  }, []);

  useEffect(() => {
    void queryClient.prefetchQuery({
      queryKey: queryKeys.activeServices,
      queryFn: () => fetchActiveServices(supabase),
      staleTime: CATALOG_STALE_MS,
    });
  }, [queryClient]);

  useEffect(() => {
    const returned = parseCheckoutReturn(window.location.search);
    if (returned.kind === 'none') return;

    const restorePending = () => {
      let workerName = '';
      let savedAmount = 0;
      try {
        const raw = sessionStorage.getItem('mwa-pending-checkout');
        if (raw) {
          const saved = JSON.parse(raw) as {
            worker?: SearchWorker;
            serviceTitle?: string;
            jobId?: string;
            amount?: number;
          };
          if (saved.worker) {
            setSelectedWorker(saved.worker);
            workerName = saved.worker.name;
          }
          if (saved.jobId) setCheckoutJobId(saved.jobId);
          if (saved.amount) savedAmount = saved.amount;
          if (saved.serviceTitle) {
            setServiceMatch((prev) =>
              prev
                ? { ...prev, categoryName: saved.serviceTitle || prev.categoryName }
                : prev,
            );
          }
          sessionStorage.removeItem('mwa-pending-checkout');
        }
      } catch {
        // el checkout pendiente no es JSON válido
      }
      return { workerName, savedAmount };
    };

    if (returned.kind === 'card') {
      window.history.replaceState({}, '', window.location.pathname);
      return;
    }

    if (returned.kind === 'tracked') {
      const pending = restorePending();
      const jobIdParam = returned.jobId;
      const amount = returned.amount || pending.savedAmount;
      const workerName = pending.workerName;
      const paymentId = returned.paymentId;
      if (jobIdParam) setCheckoutJobId(jobIdParam);
      setBookingError(null);
      setPaidVerifyError(null);
      setView('paid');
      window.history.replaceState({}, '', window.location.pathname);
      if (!paymentId) {
        setPaidVerifyError(
          'Falta referencia de pago. Si ya pagaste, revisa tu correo o inicia sesión.',
        );
        return;
      }
      setPaidVerifying(true);
      void fetchPaymentStatus(supabase, paymentId, jobIdParam ?? undefined)
        .then(async (status) => {
          if (
            status &&
            ['retenido', 'autorizado', 'liberado'].includes(status.estado)
          ) {
            if (jobIdParam) {
              await openJobForWorker(supabase, jobIdParam).catch(() => undefined);
            }
            setPaymentNotice(
              orderConfirmedMessage({
                amountClp: amount,
                last4: returned.last4,
                workerName,
              }),
            );
            setView(workerName ? 'tracking' : 'paid');
            return;
          }
          setPaidVerifyError(
            'Aún no confirmamos el pago con Transbank. Si ya pagaste, espera un momento y recarga.',
          );
        })
        .catch(() => {
          setPaidVerifyError(
            'No se pudo verificar el pago. Si ya pagaste, tu trabajo aparecerá en breve.',
          );
        })
        .finally(() => setPaidVerifying(false));
      return;
    }

    if (returned.kind === 'verify') {
      restorePending();
      const jobIdParam = returned.jobId;
      const paymentId = returned.paymentId;
      if (jobIdParam) setCheckoutJobId(jobIdParam);

      setView('paid');
      setBookingError(null);
      setPaidVerifyError(null);
      window.history.replaceState({}, '', window.location.pathname);

      if (paymentId) {
        setPaidVerifying(true);
        void fetchPaymentStatus(supabase, paymentId, jobIdParam ?? undefined)
          .then((status) => {
            if (
              !status ||
              !['retenido', 'autorizado', 'liberado'].includes(status.estado)
            ) {
              setPaidVerifyError(
                'Aún no confirmamos el pago con Transbank. Si ya pagaste, espera un momento y recarga.',
              );
            }
          })
          .catch(() => {
            setPaidVerifyError(
              'No se pudo verificar el pago. Si ya pagaste, tu trabajo aparecerá en breve.',
            );
          })
          .finally(() => setPaidVerifying(false));
      } else {
        setPaidVerifyError(
          'Falta referencia de pago. Si ya pagaste, revisa tu correo o inicia sesión.',
        );
      }
    } else if (returned.kind === 'failed') {
      setBookingError(returned.message);
      window.history.replaceState({}, '', window.location.pathname);
    }
  }, []);



  const searchService = async (text: string) => {

    if (!text.trim()) return;

    setIsSearching(true);

    setServiceMatch(null);

    setQuery(text);

    setView('search');

    setSelectedWorker(null);



    setCatalogError(null);

    const meta = resolveCategory(text);



    try {

      const [service, page] = await Promise.all([

        queryClient.fetchQuery({
          queryKey: queryKeys.serviceByCategory(meta.category),
          queryFn: () => fetchServiceByCategory(supabase, meta.category),
          staleTime: CATALOG_STALE_MS,
        }),

        queryClient.fetchQuery({
          queryKey: queryKeys.workersByCategory(meta.category),
          queryFn: () => fetchWorkersCatalog(supabase, { category: meta.category }),
          staleTime: CATALOG_STALE_MS,
        }),

      ]);

      setSelectedServiceId(service?.id ?? null);

      const workers: SearchWorker[] = page.workers.map((worker: WorkerWithProfile) => ({

        ...toWebWorkerCard(worker),

        availableNow: true,

      }));



      setServiceMatch({ ...meta, workers, nextCursor: page.nextCursor });

    } catch {

      setSelectedServiceId(null);

      setCatalogError('No se pudo cargar el catálogo. Revisa tu conexión e inténtalo de nuevo.');

      setServiceMatch({ ...meta, workers: [], nextCursor: null });

    } finally {

      setIsSearching(false);

    }

  };



  const loadMoreWorkers = async () => {
    const match = serviceMatch;
    if (!match?.nextCursor || loadingMoreWorkers) return;
    setLoadingMoreWorkers(true);
    setCatalogError(null);
    try {
      const page = await fetchWorkersCatalog(supabase, {
        category: match.category,
        cursor: match.nextCursor,
      });
      const extra: SearchWorker[] = page.workers.map((worker: WorkerWithProfile) => ({
        ...toWebWorkerCard(worker),
        availableNow: true,
      }));
      setServiceMatch({
        ...match,
        workers: [...match.workers, ...extra],
        nextCursor: page.nextCursor,
      });
    } catch {
      setCatalogError('No se pudieron cargar más profesionales. Inténtalo de nuevo.');
    } finally {
      setLoadingMoreWorkers(false);
    }
  };

  const requestWorker = (worker: SearchWorker) => {
    setSelectedWorker(worker);
    setBookingError(null);
  };

  const startCheckout = async () => {
    if (!selectedWorker) return;
    if (!selectedServiceId) {
      setBookingError('No hay un servicio activo en Supabase para esta categoría.');
      return;
    }
    setBookingError(null);

    // Sin sesión: datos + Webpay. Con sesión: cobro a la tarjeta de la app.
    if (!profile) {
      setShowGuestCheckout(true);
      return;
    }

    try {
      const job = await createPendingJob(supabase, {
        userId: profile.id,
        workerId: selectedWorker.id,
        serviceId: selectedServiceId,
        description: serviceMatch?.problem ?? query,
        pricingMode: 'precio_fijo',
      });
      setCheckoutJobId(job.id);
      setShowCheckout(true);
    } catch {
      setBookingError('No se pudo crear la solicitud. Verifica tu sesión.');
    }
  };

  const confirmBooking = async () => {
    setShowCheckout(false);
    setShowGuestCheckout(false);
    setView('tracking');
    setBookingError(null);
  };

  const payWithWebpay = async () => {
    if (!checkoutJobId || !selectedWorker) {
      throw new Error('Falta el trabajo para confirmar el pedido.');
    }
    sessionStorage.setItem(
      'mwa-pending-checkout',
      JSON.stringify({
        jobId: checkoutJobId,
        worker: selectedWorker,
        serviceTitle: serviceMatch?.categoryName,
        amount: selectedWorker.pricePerVisit,
      }),
    );
    const charged = await chargeSavedCard(supabase, {
      jobId: checkoutJobId,
      amountClp: selectedWorker.pricePerVisit,
    });
    if (charged.charged) {
      await openJobForWorker(supabase, checkoutJobId);
    }
    return charged;
  };

  const submitGuestCheckout = async (data: {
    name: string;
    email: string;
    phone: string;
    address: string;
  }) => {
    if (!selectedWorker || !selectedServiceId) {
      throw new Error('Falta profesional o servicio.');
    }
    const session = await createGuestWebpayCheckout(supabase, {
      ...data,
      workerId: selectedWorker.id,
      serviceId: selectedServiceId,
      description: serviceMatch?.problem ?? query,
      amountClp: selectedWorker.pricePerVisit,
    });
    setCheckoutJobId(session.jobId);
    sessionStorage.setItem(
      'mwa-pending-checkout',
      JSON.stringify({
        jobId: session.jobId,
        worker: selectedWorker,
        serviceTitle: serviceMatch?.categoryName,
      }),
    );
    // Invitado: redirección completa a Transbank.
    window.location.assign(session.redirectUrl);
  };



  const goToCategories = () => {
    setView('categories');
    setSelectedWorker(null);
  };

  const openCategory = (cat: ServiceCategory) => {
    void searchService(cat.searchQuery);
  };

  if (view === 'paid') {
    return (
      <Suspense fallback={<ViewFallback />}>
        <PaidReturnView
          workerName={selectedWorker?.name}
          jobId={checkoutJobId}
          verifying={paidVerifying}
          verifyError={paidVerifyError}
          onContinueTracking={() => setView('tracking')}
          onGoHome={() => setView('landing')}
        />
      </Suspense>
    );
  }

  if (view === 'tracking' && selectedWorker) {

    return (
      <Suspense fallback={<ViewFallback />}>
      <div className="min-h-screen app-shell">

        <TrackingDashboard

          workerName={selectedWorker.name}

          workerProfession={selectedWorker.profession}

          workerPhoto={selectedWorker.photoUrl}

          workerRating={selectedWorker.rating}

          workerJobs={selectedWorker.jobsDone}

          serviceTitle={serviceMatch?.categoryName ?? 'Instalación Eléctrica'}

          serviceLocation="La dirección queda guardada en el trabajo"

          orderId={checkoutJobId ?? 'sin-pedido'}

          profileName={profile?.name}

          paymentNotice={paymentNotice}

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
      </Suspense>
    );

  }



  if (view === 'categories') {
    return (
      <Suspense fallback={<ViewFallback />}>
        <div className="min-h-screen app-shell">
          <CategoriesCatalogView
            categories={ALL_SERVICE_CATEGORIES}
            profileName={profile?.name}
            onBack={() => setView('landing')}
            onSelectCategory={openCategory}
            onShowAuth={() => setShowAuth(true)}
          />
          <Suspense fallback={null}>
            <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />
          </Suspense>
        </div>
      </Suspense>
    );
  }

  if (view === 'search') {

    return (
      <Suspense fallback={<ViewFallback />}>
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
            setView('categories');
            setSelectedWorker(null);
          }}

          onShowAuth={() => setShowAuth(true)}
          hasMore={Boolean(serviceMatch?.nextCursor)}
          isLoadingMore={loadingMoreWorkers}
          onLoadMore={() => void loadMoreWorkers()}

        />



        {selectedWorker && (

          <QuickBookingBar

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            pricePerHour={Math.round(selectedWorker.pricePerVisit / 1000) * 1000 || 35000}

            onContinue={() => void startCheckout()}

            onClose={() => setSelectedWorker(null)}

          />

        )}



        {showCheckout && selectedWorker && (

          <PaymentCheckoutModal

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            basePrice={selectedWorker.pricePerVisit}

            serviceDescription={serviceMatch?.problem}

            jobId={checkoutJobId}

            onClose={() => setShowCheckout(false)}

            onPayWithWebpay={payWithWebpay}

            onSuccess={(details) => {
              sessionStorage.removeItem('mwa-pending-checkout');
              setPaymentNotice(details.notice);
              void confirmBooking();
            }}

          />

        )}

        {showGuestCheckout && selectedWorker && (
          <GuestCheckoutForm
            workerName={selectedWorker.name}
            profession={selectedWorker.profession}
            basePrice={selectedWorker.pricePerVisit}
            serviceDescription={serviceMatch?.problem}
            onClose={() => setShowGuestCheckout(false)}
            onSubmit={submitGuestCheckout}
            onPreferLogin={() => {
              setShowGuestCheckout(false);
              setShowAuth(true);
            }}
          />
        )}



        {bookingError && (

          <div className="toast-error" role="alert">

            {bookingError}

          </div>

        )}

        {catalogError && (
          <div className="toast-error" role="alert">
            {catalogError}
          </div>
        )}



        <AuthModal open={showAuth} onClose={() => setShowAuth(false)} />

      </div>
      </Suspense>
    );

  }



  return (
    <LandingHome
      activeNav={activeNav}
      setActiveNav={setActiveNav}
      profile={profile}
      setShowAuth={setShowAuth}
      logout={() => void logout()}
      authError={authError}
      clearError={clearError}
      goToCategories={goToCategories}
      openCategory={openCategory}
      showAuth={showAuth}
    />
  );

}



export default App;

