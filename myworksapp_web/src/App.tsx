import { useState, useEffect, useRef, lazy, Suspense } from 'react';
import { useQueryClient } from '@tanstack/react-query';

import { LandingHome } from './views/LandingHome';
import type { SearchWorker } from './components/SearchResultsView';
import { useAuth } from './context/AuthContext';
import { supabase } from './supabaseClient';
import { useLiveJobLocation } from './hooks/useLiveJobLocation';
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
  createWebpaySession,
  fetchActiveServices,
  orderConfirmedMessage,
  openJobForWorker,
  closeJobOnClientApproval,
  parseCheckoutReturn,
  fetchPaymentStatus,
  fetchServiceByCategory,
  fetchWorkersCatalog,
  fetchCategoriesWithPros,
  categoriesWithPros,
  fetchJobTrackingSnapshot,
  fetchMyNotifications,
  fetchUserJobs,
  toWebWorkerCard,
  type JobTrackingSnapshot,
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

const FALLBACK_PHOTO =
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop&q=70';

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



function resolveCategory(text: string): {
  category: string;
  categoryName: string;
  problem: string;
  minPrice: number;
  maxPrice: number;
  urgency: 'Media' | 'Alta';
} | null {
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
      categoryName: 'Plomería',
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

  if (
    lower.includes('construc') ||
    lower.includes('remodel') ||
    lower.includes('maestro')
  ) {
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
      categoryName: 'Electricidad',
      problem: 'Instalaciones y reparaciones eléctricas',
      minPrice: 25000,
      maxPrice: 60000,
      urgency: 'Media' as const,
    };
  }

  return null;
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
  const [scheduledAt, setScheduledAt] = useState<string | null>(null);

  const [showChat, setShowChat] = useState(false);

  const [showAuth, setShowAuth] = useState(false);
  const [authInitialEmail, setAuthInitialEmail] = useState('');

  const [bookingError, setBookingError] = useState<string | null>(null);
  const [catalogError, setCatalogError] = useState<string | null>(null);
  const [loadingMoreWorkers, setLoadingMoreWorkers] = useState(false);
  const [paidVerifying, setPaidVerifying] = useState(false);
  const [paidVerifyError, setPaidVerifyError] = useState<string | null>(null);
  const [guestPasswordToken, setGuestPasswordToken] = useState<string | null>(null);
  const [paymentNotice, setPaymentNotice] = useState<string | null>(null);
  const [jobSnapshot, setJobSnapshot] = useState<JobTrackingSnapshot | null>(null);
  const [unreadCount, setUnreadCount] = useState(0);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notificationLines, setNotificationLines] = useState<string[]>([]);
  const [confirmBusy, setConfirmBusy] = useState(false);
  const [confirmError, setConfirmError] = useState<string | null>(null);
  const [myOrders, setMyOrders] = useState<Awaited<ReturnType<typeof fetchUserJobs>> | null>(null);
  const [ordersError, setOrdersError] = useState<string | null>(null);
  const restoredJob = useRef(false);

  const [activeNav, setActiveNav] = useState<'servicios' | 'como-funciona'>('servicios');
  const [availableCategoryIds, setAvailableCategoryIds] = useState<ReadonlySet<string> | null>(null);

  useEffect(() => {
    let cancelled = false;
    void fetchCategoriesWithPros(supabase).then((ids) => {
      if (cancelled || ids == null) return;
      setAvailableCategoryIds(new Set(ids));
    });
    return () => {
      cancelled = true;
    };
  }, []);

  const visibleCategories = categoriesWithPros(
    ALL_SERVICE_CATEGORIES,
    availableCategoryIds,
  );

  const liveLocation = useLiveJobLocation(
    view === 'tracking' ? checkoutJobId : null,
    jobSnapshot?.latitude,
    jobSnapshot?.longitude,
  );



  useEffect(() => {

    document.body.classList.add('dark');

    localStorage.setItem('mwa-dark-mode', '1');

  }, []);

  useEffect(() => {
    if (view !== 'tracking' || !checkoutJobId) return;
    let cancelled = false;
    const load = () => {
      void fetchJobTrackingSnapshot(supabase, checkoutJobId)
        .then((snapshot) => {
          if (!cancelled && snapshot) setJobSnapshot(snapshot);
        })
        .catch(() => {
          // Se conserva el último estado visible si el refresco falla.
        });
    };
    load();
    const timer = window.setInterval(load, 8000);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [view, checkoutJobId]);

  const confirmReceipt = async () => {
    if (!checkoutJobId) return;
    setConfirmBusy(true);
    setConfirmError(null);
    try {
      await closeJobOnClientApproval(supabase, checkoutJobId);
      const snapshot = await fetchJobTrackingSnapshot(supabase, checkoutJobId);
      setJobSnapshot(snapshot);
      setPaymentNotice('Recibiste conforme. El pago retenido quedó liberado.');
    } catch (err) {
      setConfirmError(
        err instanceof Error ? err.message : 'No se pudo recibir conforme.',
      );
    } finally {
      setConfirmBusy(false);
    }
  };

  const openJobTracking = async (jobId: string) => {
    try {
      const snapshot = await fetchJobTrackingSnapshot(supabase, jobId);
      if (!snapshot) {
        setBookingError('No encontramos ese pedido.');
        return;
      }
      setCheckoutJobId(snapshot.id);
      setJobSnapshot(snapshot);
      sessionStorage.setItem('mwa-active-job', snapshot.id);
      let worker: SearchWorker = {
        id: snapshot.workerId ?? 'sin-profesional',
        name: 'Profesional',
        profession: 'Visita',
        category: '',
        rating: 0,
        jobsDone: 0,
        photoUrl: FALLBACK_PHOTO,
        pricePerVisit: 0,
      };
      if (snapshot.workerId) {
        const { data } = await supabase
          .from('trabajadores')
          .select('id_usuario, profesion, calificacion, tarifa_visita, categoria_servicio, perfiles!trabajadores_id_usuario_fkey(nombre, ruta_foto_perfil)')
          .eq('id_usuario', snapshot.workerId)
          .maybeSingle();
        if (data) {
          const joined = data.perfiles as
            | { nombre?: string; ruta_foto_perfil?: string | null }
            | { nombre?: string; ruta_foto_perfil?: string | null }[]
            | null;
          const profileRow = Array.isArray(joined) ? joined[0] : joined;
          worker = {
            id: String(data.id_usuario),
            name: profileRow?.nombre ?? 'Profesional',
            profession: String(data.profesion ?? 'Visita'),
            category: String(data.categoria_servicio ?? ''),
            rating: Number(data.calificacion ?? 0),
            jobsDone: 0,
            photoUrl: profileRow?.ruta_foto_perfil || FALLBACK_PHOTO,
            pricePerVisit: Number(data.tarifa_visita ?? 0),
          };
        }
      }
      if (worker.category && snapshot.workerId) {
        // Mismo conteo que la tarjeta del catálogo (trabajos completados reales).
        const catalog = await supabase.rpc('listar_profesionales_catalogo', {
          p_categoria: worker.category,
          p_limit: 40,
        });
        const rows = Array.isArray(catalog.data)
          ? (catalog.data as { id_usuario: string; trabajos_completados?: number | null }[])
          : [];
        const row = rows.find((r) => String(r.id_usuario) === String(snapshot.workerId));
        if (row) worker = { ...worker, jobsDone: Number(row.trabajos_completados ?? 0) };
      }
      setSelectedWorker(worker);
      setServiceMatch((prev) => prev ?? {
        category: worker.category || 'plomeria',
        categoryName: snapshot.description ?? worker.profession,
        problem: snapshot.description ?? '',
        minPrice: worker.pricePerVisit,
        maxPrice: worker.pricePerVisit,
        urgency: 'normal',
        workers: [],
        nextCursor: null,
      });
      setMyOrders(null);
      setBookingError(null);
      setView('tracking');
    } catch {
      setBookingError('No se pudo abrir el seguimiento. Entra de nuevo e inténtalo.');
    }
  };

  const showMyOrders = async () => {
    if (!profile) {
      setAuthInitialEmail('');
      setShowAuth(true);
      return;
    }
    setOrdersError(null);
    try {
      const rows = await fetchUserJobs(supabase, profile.id);
      const closed = new Set(['completado', 'cancelado', 'expirado', 'no_asistio']);
      const active = rows.filter((row) => !closed.has(row.status));
      const completed = rows.filter((row) => row.status === 'completado').slice(0, 8);
      setMyOrders([...active, ...completed]);
    } catch {
      setOrdersError('No se pudieron leer tus pedidos.');
      setMyOrders([]);
    }
  };

  useEffect(() => {
    if (!profile || restoredJob.current) return;
    restoredJob.current = true;
    if (parseCheckoutReturn(window.location.search).kind !== 'none') return;
    const jobId = sessionStorage.getItem('mwa-active-job');
    if (jobId) void openJobTracking(jobId);
  }, [profile]);

  useEffect(() => {
    if (!profile) {
      setUnreadCount(0);
      return;
    }
    void fetchMyNotifications(supabase, profile.id)
      .then((rows) => {
        setUnreadCount(rows.filter((row) => !row.read).length);
        setNotificationLines(rows.map((row) => `${row.title}: ${row.body}`));
      })
      .catch(() => {
        setUnreadCount(0);
        setNotificationLines([]);
      });
  }, [profile, view]);

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
          if (saved.jobId) {
            setCheckoutJobId(saved.jobId);
            sessionStorage.setItem('mwa-active-job', saved.jobId);
          }
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
            if (jobIdParam) sessionStorage.setItem('mwa-active-job', jobIdParam);
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
      const pending = restorePending();
      const jobIdParam = returned.jobId;
      const paymentId = returned.paymentId;
      if (jobIdParam) setCheckoutJobId(jobIdParam);
      if (returned.guest && returned.passwordToken) {
        setGuestPasswordToken(returned.passwordToken);
      }

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
              return;
            }
            if (jobIdParam) sessionStorage.setItem('mwa-active-job', jobIdParam);
            if (!returned.guest && pending.workerName) setView('tracking');
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

    if (!meta) {
      setCatalogError('No reconocimos el oficio. Elige una categoría del catálogo.');
      setIsSearching(false);
      return;
    }



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

  const startCheckout = async (slotIso?: string) => {
    if (!selectedWorker) return;
    if (!selectedServiceId) {
      setBookingError('No hay un servicio activo en Supabase para esta categoría.');
      return;
    }
    const when = slotIso ?? scheduledAt ?? undefined;
    if (slotIso) setScheduledAt(slotIso);
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
        scheduledAt: when,
      });
      setCheckoutJobId(job.id);
      sessionStorage.setItem('mwa-active-job', job.id);
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
      return charged;
    }
    const session = await createWebpaySession(supabase, {
      jobId: checkoutJobId,
      amountClp: selectedWorker.pricePerVisit,
      presentMode: 'redirect',
    });
    window.location.assign(session.redirectUrl);
    return { charged: false, redirected: true } as const;
  };

  const submitGuestCheckout = async (data: {
    name: string;
    email: string;
    phone: string;
    address: string;
    turnstileToken?: string;
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
      scheduledAt: scheduledAt ?? undefined,
      turnstileToken: data.turnstileToken,
    });
    if (session.nonce) {
      sessionStorage.setItem('mwa-guest-alta-nonce', session.nonce);
    }
    sessionStorage.setItem('mwa-guest-email', data.email.trim());
    setCheckoutJobId(session.jobId);
    sessionStorage.setItem('mwa-active-job', session.jobId);
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
          passwordToken={guestPasswordToken}
          onContinueTracking={() => {
            if (checkoutJobId && profile) {
              void openJobTracking(checkoutJobId);
              return;
            }
            if (profile) {
              if (selectedWorker) setView('tracking');
              return;
            }
            // El invitado todavía no tiene sesión: sin ella el seguimiento sale vacío.
            // Al entrar, el efecto de restauración abre 'mwa-active-job'.
            if (checkoutJobId) sessionStorage.setItem('mwa-active-job', checkoutJobId);
            setAuthInitialEmail(sessionStorage.getItem('mwa-guest-email')?.trim() ?? '');
            setView('landing');
            setShowAuth(true);
          }}
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

          serviceTitle={serviceMatch?.categoryName ?? jobSnapshot?.description ?? 'Servicio'}

          serviceLocation={jobSnapshot?.address ?? 'La dirección queda guardada en el trabajo'}

          orderId={checkoutJobId ?? 'sin-pedido'}

          jobStatus={jobSnapshot?.status}

          paymentStatus={jobSnapshot?.paymentStatus}

          latitude={jobSnapshot?.latitude}

          longitude={jobSnapshot?.longitude}

          workerLatitude={liveLocation.fix?.latitude}

          workerLongitude={liveLocation.fix?.longitude}

          etaMinutes={liveLocation.fix?.etaMinutes}

          distanceKm={liveLocation.fix?.distanceKm}

          gpsError={liveLocation.error}

          profileName={profile?.name}

          paymentNotice={paymentNotice}

          unreadCount={unreadCount}

          onBack={() => {
            // Un pedido abierto desde Mis pedidos o tras recargar no trae resultados de búsqueda.
            sessionStorage.removeItem('mwa-active-job');
            setView(serviceMatch && serviceMatch.workers.length > 0 ? 'search' : 'landing');
          }}

          onOpenChat={() => setShowChat(true)}

          onOpenNotifications={() => setShowNotifications(true)}

          onConfirmReceipt={() => void confirmReceipt()}

          confirmBusy={confirmBusy}

          confirmError={confirmError}

          onOpenDispute={profile ? async (reason, detail) => {
            if (!checkoutJobId) throw new Error('Falta el trabajo.');
            const { error } = await supabase.rpc('abrir_disputa', {
              p_id: crypto.randomUUID(),
              p_id_trabajo: checkoutJobId,
              p_motivo: reason,
              p_descripcion: detail,
            });
            if (error) throw new Error(error.message);
          } : undefined}

          onAddDisputeComment={profile ? async (comment) => {
            if (!checkoutJobId) throw new Error('Falta el trabajo.');
            const { data, error } = await supabase
              .from('disputas')
              .select('id')
              .eq('id_trabajo', checkoutJobId)
              .in('estado', ['abierta', 'en_revision'])
              .order('creado_en', { ascending: false })
              .limit(1)
              .maybeSingle();
            if (error) throw new Error(error.message);
            if (!data?.id) throw new Error('No hay una disputa abierta en este trabajo.');
            const { error: commentError } = await supabase.rpc('comentar_disputa', {
              p_id: data.id,
              p_comentario: comment,
            });
            if (commentError) throw new Error(commentError.message);
          } : undefined}

        />

        {showNotifications && (
          <div className="toast-error" role="status">
            {notificationLines.length === 0
              ? 'No tienes notificaciones.'
              : notificationLines.slice(0, 5).join(' · ')}
            <button type="button" onClick={() => setShowNotifications(false)}>Cerrar</button>
          </div>
        )}

        {showChat && (

          <LiveChatWidget

            workerName={selectedWorker.name}

            workerPhoto={selectedWorker.photoUrl}

            jobId={checkoutJobId}

            senderId={profile?.id ?? null}

            receiverId={selectedWorker.id}

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
            categories={visibleCategories}
            profileName={profile?.name}
            onBack={() => setView('landing')}
            onSelectCategory={openCategory}
            onShowAuth={() => {
              setAuthInitialEmail('');
              setShowAuth(true);
            }}
          />
          <Suspense fallback={null}>
            <AuthModal open={showAuth} initialEmail={authInitialEmail} onClose={() => setShowAuth(false)} />
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

          onShowAuth={() => {
            setAuthInitialEmail('');
            setShowAuth(true);
          }}
          hasMore={Boolean(serviceMatch?.nextCursor)}
          isLoadingMore={loadingMoreWorkers}
          onLoadMore={() => void loadMoreWorkers()}

        />



        {selectedWorker && (

          <QuickBookingBar

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            pricePerHour={selectedWorker.pricePerVisit}

            onContinue={(slotIso) => void startCheckout(slotIso)}

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
              setAuthInitialEmail('');
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



        <AuthModal open={showAuth} initialEmail={authInitialEmail} onClose={() => setShowAuth(false)} />

      </div>
      </Suspense>
    );

  }



  return (
    <LandingHome
      activeNav={activeNav}
      setActiveNav={setActiveNav}
      profile={profile}
      setShowAuth={(open) => {
        if (open) setAuthInitialEmail('');
        setShowAuth(open);
      }}
      authInitialEmail={authInitialEmail}
      logout={() => void logout()}
      authError={authError}
      clearError={clearError}
      goToCategories={goToCategories}
      openCategory={openCategory}
      showAuth={showAuth}
      availableCategoryIds={availableCategoryIds}
      checkoutNotice={bookingError}
      clearCheckoutNotice={() => setBookingError(null)}
      onShowOrders={() => void showMyOrders()}
      orders={myOrders?.map((order) => ({
        id: order.id,
        status: order.status,
        address: order.address ?? null,
        description: order.description ?? null,
      })) ?? null}
      ordersError={ordersError}
      onOpenOrder={(jobId) => void openJobTracking(jobId)}
      onCloseOrders={() => setMyOrders(null)}
    />
  );

}



export default App;

