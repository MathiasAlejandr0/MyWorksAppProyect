import { useState, useEffect, useRef, lazy, Suspense } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useQueryClient } from '@tanstack/react-query';

import { LandingHome } from './views/LandingHome';
import { NotificationInbox } from './components/NotificationInbox';
import type { SearchWorker } from './components/SearchResultsView';
import { useAuth } from './context/useAuth';
import { registrarEventoUso } from './analytics/registrarEvento';
import { supabase } from './supabaseClient';
import { useLiveJobLocation } from './hooks/useLiveJobLocation';
import { queryKeys } from './queryClient';
import { geocodeChileAddress } from './geo/geocodeChile';
import {
  ALL_SERVICE_CATEGORIES,
  type ServiceCategory,
} from './data/serviceCategories';
import { resolveCategory, type MapSite } from './data/resolveServiceQuery';
import { categoryFromPath, pathForView, recordIdFromPath, viewFromPath, type AppView } from './routing/paths';
import { AccountPage } from './pages/AccountPage';
import { LegalPage } from './pages/LegalPage';
import { NotFoundPage } from './pages/NotFoundPage';
import { ProfessionalProfilePage } from './pages/ProfessionalProfilePage';
import { WorkWithUsPage } from './pages/WorkWithUsPage';
import { ChangeOrderPanel } from './components/ChangeOrderPanel';
import { SiteFooter } from './components/SiteFooter';
import {
  CATALOG_STALE_MS,
  EVENTOS_USO,
  chargeSavedCard,
  createGuestWebpayCheckout,
  getSavedCard,
  removeSavedCard,
  startCardEnrollment,
  createPendingJob,
  createWebpaySession,
  fetchJobChargePreview,
  previewGuestCharge,
  type AppNotification,
  fetchActiveServices,
  agreementErrorMessage,
  orderConfirmedMessage,
  openJobForWorker,
  closeJobOnClientApproval,
  parseCheckoutReturn,
  fetchPaymentStatus,
  fetchServiceByCategory,
  fetchWorkersCatalog,
  fetchWorkerFreeSlots,
  formatBookingSlotLabel,
  fetchCategoriesWithPros,
  categoriesWithPros,
  fetchJobTrackingSnapshot,
  fetchClientStartPin,
  clientShouldShowStartPin,
  fetchJobEvidencePhotos,
  syncJobEvidencePhotos,
  fetchMyNotifications,
  fetchUserJobs,
  toWebWorkerCard,
  fetchWorkerPublicStats,
  catalogPinTooFar,
  transportSurcharge,
  isOpenAt,
  type WeeklyHours,
  type JobTrackingSnapshot,
  type JobEvidencePhoto,
  type CatalogCursor,
  type WorkerWithProfile,
  initialsAvatarDataUrl,
  profilePhotoOrInitials,
} from '@myworksapp/shared';

type ScheduleRow = {
  id_usuario: string;
  dia_semana: number;
  hora_inicio: string;
  hora_fin: string;
  activo: boolean | null;
};

function minutesOf(value: string): number {
  const [hour, minute] = value.split(':');
  return Number(hour) * 60 + Number(minute || 0);
}

type LooseQuery = {
  from: (table: string) => {
    select: (columns: string) => {
      in: (
        column: string,
        values: string[],
      ) => Promise<{
        data: Array<Record<string, unknown>> | null;
        error: { message: string } | null;
      }>;
    };
  };
};

async function loadSchedules(
  ids: string[],
): Promise<Map<string, WeeklyHours>> {
  const result = new Map<string, WeeklyHours>();
  if (ids.length === 0) return result;
  // anon no tiene SELECT sobre trabajadores: sin sesión no se consulta y
  // la disponibilidad queda como la entrega el catálogo.
  const { data: session } = await supabase.auth.getSession();
  if (!session.session) return result;
  // Las columnas viven en la base y todavía no están en database.types.ts.
  const db = supabase as unknown as LooseQuery;
  const [flags, rows] = await Promise.all([
    db.from('trabajadores').select('id_usuario, usa_horario').in('id_usuario', ids),
    db
      .from('trabajador_horarios')
      .select('id_usuario, dia_semana, hora_inicio, hora_fin, activo')
      .in('id_usuario', ids),
  ]);
  if (flags.error || rows.error) return result;
  const days = new Map<string, WeeklyHours['days']>();
  for (const raw of rows.data ?? []) {
    const row = raw as ScheduleRow;
    if (!row.id_usuario || row.dia_semana == null) continue;
    const list = days.get(row.id_usuario) ?? [];
    list.push({
      weekday: row.dia_semana,
      startMinute: minutesOf(String(row.hora_inicio)),
      endMinute: minutesOf(String(row.hora_fin)),
      enabled: row.activo !== false,
    });
    days.set(row.id_usuario, list);
  }
  for (const flag of flags.data ?? []) {
    const id = String(flag.id_usuario ?? '');
    if (!id) continue;
    result.set(id, {
      enabled: flag.usa_horario === true,
      days: days.get(id) ?? [],
    });
  }
  return result;
}

async function withScheduleAvailability(workers: WorkerWithProfile[]): Promise<SearchWorker[]> {
  const now = new Date();
  let schedules = new Map<string, WeeklyHours>();
  try {
    schedules = await loadSchedules(workers.map((worker) => worker.userId));
  } catch {
    schedules = new Map();
  }
  return workers.map((worker) => {
    const schedule = schedules.get(worker.userId);
    return {
      ...toWebWorkerCard(worker),
      availableNow: Boolean(
        schedule && worker.isAvailable === 1 && isOpenAt(schedule, now),
      ),
    };
  });
}

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

const JobEvidencePanel = lazy(() =>
  import('./components/JobEvidencePanel').then((m) => ({
    default: m.JobEvidencePanel,
  })),
);

const JobClientActions = lazy(() =>
  import('./components/JobClientActions').then((m) => ({
    default: m.JobClientActions,
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



export function App() {

  const { profile, loading: authLoading, logout, error: authError, clearError } = useAuth();
  const queryClient = useQueryClient();

  const [query, setQuery] = useState('');

  const [serviceMatch, setServiceMatch] = useState<ServiceMatch | null>(null);

  const [isSearching, setIsSearching] = useState(false);

  const [selectedWorker, setSelectedWorker] = useState<SearchWorker | null>(null);
  const [clientLocation, setClientLocation] = useState<MapSite | null>(null);
  const [clientLocationSource, setClientLocationSource] = useState<
    'gps' | 'map' | 'address' | null
  >(null);
  /** Sitio ya guardado en el trabajo de cobro. `undefined` = aún no hay pedido. */
  const [jobSiteBound, setJobSiteBound] = useState<MapSite | null | undefined>(
    undefined,
  );
  const [locating, setLocating] = useState(false);
  const [locatingAddress, setLocatingAddress] = useState(false);

  const [selectedServiceId, setSelectedServiceId] = useState<string | null>(null);

  const [showCheckout, setShowCheckout] = useState(false);

  const [showGuestCheckout, setShowGuestCheckout] = useState(false);

  const [checkoutJobId, setCheckoutJobId] = useState<string | null>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const [view, setViewState] = useState<AppView>(() => viewFromPath(location.pathname));
  useEffect(() => {
    setViewState(viewFromPath(location.pathname));
  }, [location.pathname]);
  const setView = (next: AppView) => {
    setViewState(next);
    const target = pathForView(next, {
      category: serviceMatch?.category ?? categoryFromPath(location.pathname),
      jobId: checkoutJobId,
    });
    if (location.pathname !== target) navigate(target);
  };
  const [pendingAgreement, setPendingAgreement] = useState<{ id: string; tipo: string } | null>(null);
  const [openDispute, setOpenDispute] = useState<{ openedBy: string | null } | null>(null);
  const [scheduledAt, setScheduledAt] = useState<string | null>(null);
  const [bookingSlots, setBookingSlots] = useState<string[]>([]);
  const [bookingSlotsLoading, setBookingSlotsLoading] = useState(false);

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
  const [clientStartPin, setClientStartPin] = useState<string | null>(null);
  const [jobEvidence, setJobEvidence] = useState<JobEvidencePhoto[]>([]);
  const jobEvidenceRef = useRef<JobEvidencePhoto[]>([]);
  jobEvidenceRef.current = jobEvidence;
  const [unreadCount, setUnreadCount] = useState(0);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notices, setNotices] = useState<AppNotification[]>([]);
  const [noticeJobTitles, setNoticeJobTitles] = useState<Record<string, string>>({});
  const [payableTotalClp, setPayableTotalClp] = useState<number | null>(null);
  const [chargeLocking, setChargeLocking] = useState(false);
  const [chargeLockError, setChargeLockError] = useState<string | null>(null);
  const [guestPayableClp, setGuestPayableClp] = useState<number | null>(null);
  const [guestQuoteError, setGuestQuoteError] = useState<string | null>(null);
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
    if (!selectedWorker) {
      setBookingSlots([]);
      setBookingSlotsLoading(false);
      return;
    }
    let cancelled = false;
    setBookingSlots([]);
    setBookingSlotsLoading(true);
    void fetchWorkerFreeSlots(supabase, selectedWorker.id)
      .then((slots) => {
        if (!cancelled) setBookingSlots(slots);
      })
      .catch((err) => {
        console.error(err);
        if (!cancelled) setBookingSlots([]);
      })
      .finally(() => {
        if (!cancelled) setBookingSlotsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [selectedWorker]);

  useEffect(() => {
    if (view !== 'tracking' || !checkoutJobId) return;
    let cancelled = false;
    const loadSnapshot = () => {
      void fetchJobTrackingSnapshot(supabase, checkoutJobId)
        .then(async (snapshot) => {
          if (cancelled || !snapshot) return;
          setJobSnapshot(snapshot);
          if (!clientShouldShowStartPin(snapshot.status)) {
            setClientStartPin(null);
            return;
          }
          setClientStartPin(await fetchClientStartPin(supabase, snapshot.id));
        })
        .catch(() => {
          // Se conserva el último estado visible si el refresco falla.
        });
    };
    void fetchJobEvidencePhotos(supabase, checkoutJobId)
      .then((photos) => {
        if (!cancelled) setJobEvidence(photos);
      })
      .catch(() => {
        // Se conserva la última evidencia visible si la carga falla.
      });
    // supabase.rpc devuelve un PromiseLike (sin .catch): se envuelve en una Promise real.
    // Si la función aún no existe en la base, el acuerdo queda en null sin romper la vista.
    const loadAgreement = () => {
      void Promise.resolve(supabase.rpc('acuerdo_pendiente', { p_id_trabajo: checkoutJobId }))
        .then(({ data, error }) => {
          const row = error ? undefined : data?.[0];
          if (!cancelled) setPendingAgreement(row ? { id: row.id, tipo: row.tipo } : null);
        })
        .catch(() => {
          if (!cancelled) setPendingAgreement(null);
        });
    };
    const loadDispute = () => {
      void supabase
        .from('disputas')
        .select('abierta_por')
        .eq('id_trabajo', checkoutJobId)
        .in('estado', ['abierta', 'en_revision', 'requiere_humano', 'reembolso_pendiente'])
        .order('creado_en', { ascending: false })
        .limit(1)
        .maybeSingle()
        .then(({ data, error }) => {
          if (cancelled) return;
          if (error || !data) {
            setOpenDispute(null);
            return;
          }
          const row = data as { abierta_por?: string | null };
          setOpenDispute({ openedBy: row.abierta_por ? String(row.abierta_por) : null });
        });
    };
    loadSnapshot();
    loadDispute();
    loadAgreement();
    const tick = () => {
      if (document.visibilityState === 'hidden') return;
      loadSnapshot();
      loadDispute();
      loadAgreement();
      void syncJobEvidencePhotos(supabase, checkoutJobId, jobEvidenceRef.current)
        .then((photos) => {
          if (!cancelled) setJobEvidence(photos);
        })
        .catch(() => {
          // Se conserva la última evidencia visible si el refresco falla.
        });
    };
    const timer = window.setInterval(tick, 8000);
    const onVisible = () => {
      if (document.visibilityState === 'visible') tick();
    };
    document.addEventListener('visibilitychange', onVisible);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
      document.removeEventListener('visibilitychange', onVisible);
    };
  }, [view, checkoutJobId]);

  const goHome = () => {
    sessionStorage.removeItem('mwa-active-job');
    setShowChat(false);
    setShowNotifications(false);
    setShowCheckout(false);
    setShowGuestCheckout(false);
    setMyOrders(null);
    setConfirmError(null);
    setConfirmBusy(false);
    setPaymentNotice(null);
    setJobEvidence([]);
    setClientStartPin(null);
    setOpenDispute(null);
    setView('landing');
  };

  const confirmReceipt = async () => {
    if (!checkoutJobId) return;
    setConfirmBusy(true);
    setConfirmError(null);
    try {
      await closeJobOnClientApproval(supabase, checkoutJobId);
      setPaymentNotice('Recibiste conforme. El pago retenido quedó liberado.');
      try {
        const snapshot = await fetchJobTrackingSnapshot(supabase, checkoutJobId);
        if (snapshot) {
          setJobSnapshot(snapshot);
        } else {
          setJobSnapshot((prev) =>
            prev ? { ...prev, status: 'completado', paymentStatus: 'liberado' } : prev,
          );
        }
      } catch {
        setJobSnapshot((prev) =>
          prev ? { ...prev, status: 'completado', paymentStatus: 'liberado' } : prev,
        );
      }
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
      try {
        setJobEvidence(await fetchJobEvidencePhotos(supabase, snapshot.id));
      } catch {
        setJobEvidence([]);
      }
      sessionStorage.setItem('mwa-active-job', snapshot.id);
      let worker: SearchWorker = {
        id: snapshot.workerId ?? 'sin-profesional',
        name: 'Profesional',
        profession: 'Visita',
        category: '',
        rating: 0,
        jobsDone: 0,
        photoUrl: initialsAvatarDataUrl('Profesional', snapshot.workerId ?? 'sin-profesional'),
        pricePerVisit: 0,
      };
      if (snapshot.workerId) {
        const { data } = await supabase
          .from('trabajadores')
          .select('id_usuario, profesion, calificacion, tarifa_visita, trabajos_completados, trabajador_servicios(categoria_servicio), perfiles!trabajadores_id_usuario_fkey(nombre, ruta_foto_perfil)')
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
            category: String(
              ((data.trabajador_servicios ?? []) as { categoria_servicio: string }[])
                .map((s) => s.categoria_servicio)
                .sort()[0] ?? '',
            ),
            rating: Number(data.calificacion ?? 0),
            // Preferimos la RPC canónica: la columna puede estar sembrada.
            jobsDone: Number(data.trabajos_completados ?? 0),
            photoUrl: profilePhotoOrInitials(
              profileRow?.ruta_foto_perfil,
              profileRow?.nombre ?? 'Profesional',
              String(data.id_usuario),
            ),
            pricePerVisit: Number(data.tarifa_visita ?? 0),
          };
          const stats = await fetchWorkerPublicStats(supabase, worker.id);
          if (stats) {
            worker = {
              ...worker,
              rating: stats.rating,
              jobsDone: stats.completedJobs,
            };
          }
        }
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
      navigate(`/pedido/${snapshot.id}`);
    } catch {
      setBookingError('No se pudo abrir el seguimiento. Entra de nuevo e inténtalo.');
    }
  };

  const openNotice = (notice: AppNotification) => {
    setShowNotifications(false);
    if (!notice.read) {
      setNotices((rows) =>
        rows.map((row) => (row.id === notice.id ? { ...row, read: true } : row)),
      );
      setUnreadCount((count) => Math.max(0, count - 1));
      void supabase.from('notificaciones').update({ leido: 1 }).eq('id', notice.id);
    }
    if (notice.relatedId) void openJobTracking(notice.relatedId);
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
        setNotices(rows);
      })
      .catch(() => {
        setUnreadCount(0);
        setNotices([]);
      });
    const channel = supabase
      .channel(`notificaciones-${profile.id}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'notificaciones', filter: `id_usuario=eq.${profile.id}` },
        () => {
          void fetchMyNotifications(supabase, profile.id)
            .then((rows) => {
              setUnreadCount(rows.filter((row) => !row.read).length);
              setNotices(rows);
            })
            .catch(() => undefined);
        },
      )
      .subscribe();
    return () => {
      void supabase.removeChannel(channel);
    };
  }, [profile]);

  useEffect(() => {
    const ids = [...new Set(
      notices
        .map((notice) => notice.relatedId?.trim() ?? '')
        .filter((id) => id.length > 0),
    )];
    if (ids.length === 0) {
      setNoticeJobTitles({});
      return;
    }
    let cancelled = false;
    void supabase
      .from('trabajos')
      .select('id, descripcion, direccion')
      .in('id', ids)
      .then(({ data }) => {
        if (cancelled) return;
        const titles: Record<string, string> = {};
        for (const row of data ?? []) {
          const id = String(row.id ?? '');
          if (!id) continue;
          const description = String(row.descripcion ?? '').trim();
          const address = String(row.direccion ?? '').trim();
          titles[id] = description || address || 'Pedido';
        }
        setNoticeJobTitles(titles);
      });
    return () => {
      cancelled = true;
    };
  }, [notices]);

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
      let workerId = '';
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
            workerId = saved.worker.id;
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
      return { workerName, savedAmount, workerId };
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
            registrarEventoUso(EVENTOS_USO.confirmoPedido, {
              ...(jobIdParam ? { id_trabajo: jobIdParam } : {}),
              ...(pending.workerId ? { id_profesional: pending.workerId } : {}),
            });
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
            registrarEventoUso(EVENTOS_USO.confirmoPedido, {
              ...(jobIdParam ? { id_trabajo: jobIdParam } : {}),
              ...(pending.workerId ? { id_profesional: pending.workerId } : {}),
            });
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

    setSelectedWorker(null);



    setCatalogError(null);

    const meta = resolveCategory(text);
    const catalogOrigin = clientLocation
      ? { latitude: clientLocation.latitude, longitude: clientLocation.longitude }
      : null;

    if (!meta) {
      setCatalogError('No reconocimos el oficio. Elige una categoría del catálogo.');
      setIsSearching(false);
      navigate('/servicios');
      return;
    }
    if (location.pathname !== `/servicios/${encodeURIComponent(meta.category)}`) {
      navigate(`/servicios/${encodeURIComponent(meta.category)}`);
    }



    try {

      const [service, page] = await Promise.all([

        queryClient.fetchQuery({
          queryKey: queryKeys.serviceByCategory(meta.category),
          queryFn: () => fetchServiceByCategory(supabase, meta.category),
          staleTime: CATALOG_STALE_MS,
        }),

        queryClient.fetchQuery({
          queryKey: queryKeys.workersByCategory(meta.category, catalogOrigin),
          queryFn: () =>
            fetchWorkersCatalog(supabase, { category: meta.category, origin: catalogOrigin }),
          staleTime: CATALOG_STALE_MS,
        }),

      ]);

      setSelectedServiceId(service?.id ?? null);

      const workers: SearchWorker[] = await withScheduleAvailability(page.workers);



      setServiceMatch({ ...meta, workers, nextCursor: page.nextCursor });

    } catch {

      setSelectedServiceId(null);

      setCatalogError('No se pudo cargar el catálogo. Revisa tu conexión e inténtalo de nuevo.');

      setServiceMatch({ ...meta, workers: [], nextCursor: null });

    } finally {

      setIsSearching(false);

    }

  };

  useEffect(() => {
    const slug = categoryFromPath(location.pathname);
    if (!slug) return;
    if (serviceMatch?.category === slug) return;
    const row = ALL_SERVICE_CATEGORIES.find((item) => item.id === slug);
    if (!row) {
      setCatalogError('Esa categoría no está en el catálogo.');
      setIsSearching(false);
      return;
    }
    void searchService(row.searchQuery);
  }, [location.pathname]);

  useEffect(() => {
    const jobId = recordIdFromPath(location.pathname, 'pedido');
    if (!jobId || !profile) return;
    if (checkoutJobId === jobId && jobSnapshot) return;
    void openJobTracking(jobId);
  }, [location.pathname, profile, checkoutJobId, jobSnapshot]);

  const loadMoreWorkers = async () => {
    const match = serviceMatch;
    if (!match?.nextCursor || loadingMoreWorkers) return;
    setLoadingMoreWorkers(true);
    setCatalogError(null);
    try {
      const page = await fetchWorkersCatalog(supabase, {
        category: match.category,
        cursor: match.nextCursor,
        origin: clientLocation
          ? { latitude: clientLocation.latitude, longitude: clientLocation.longitude }
          : null,
      });
      const extra: SearchWorker[] = await withScheduleAvailability(page.workers);
      const seen = new Set(match.workers.map((worker) => worker.id));
      setServiceMatch({
        ...match,
        workers: [...match.workers, ...extra.filter((worker) => !seen.has(worker.id))],
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
    setScheduledAt(null);
  };

  const liveSite = clientLocation;
  const chargeSite = jobSiteBound !== undefined ? jobSiteBound : liveSite;
  const quoteFor = (
    worker: SearchWorker | null,
    site: MapSite | null | undefined,
  ) =>
    worker
      ? transportSurcharge({
          workerLat: worker.latitude,
          workerLng: worker.longitude,
          jobLat: site?.latitude,
          jobLng: site?.longitude,
          radiusKm: worker.serviceRadiusKm,
          catalogBaseIsApproximate: true,
        })
      : null;
  const [chargeAttempt, setChargeAttempt] = useState(0);

  useEffect(() => {
    if (!showCheckout || !profile || !selectedWorker || !selectedServiceId || !scheduledAt) {
      return;
    }
    const site = chargeSite;
    if (!site) {
      setPayableTotalClp(null);
      setChargeLocking(false);
      setChargeLockError('Indica dónde es el trabajo: GPS, una dirección o el punto en el mapa.');
      return;
    }
    let cancelled = false;
    setChargeLocking(true);
    setPayableTotalClp(null);
    setChargeLockError(null);
    void (async () => {
      try {
        let jobId = checkoutJobId;
        if (jobId) {
          const snap = await fetchJobTrackingSnapshot(supabase, jobId);
          const same = snap != null
            && snap.latitude != null
            && snap.longitude != null
            && Math.abs(snap.latitude - site.latitude) < 1e-5
            && Math.abs(snap.longitude - site.longitude) < 1e-5;
          if (!same) jobId = null;
        }
        if (!jobId) {
          const job = await createPendingJob(supabase, {
            userId: profile.id,
            workerId: selectedWorker.id,
            serviceId: selectedServiceId,
            description: serviceMatch?.problem ?? query,
            pricingMode: 'precio_fijo',
            scheduledAt,
            latitude: site.latitude,
            longitude: site.longitude,
          });
          jobId = job.id;
          if (!cancelled) {
            setCheckoutJobId(job.id);
            setJobSiteBound(site);
            sessionStorage.setItem('mwa-active-job', job.id);
          }
        }
        const preview = await fetchJobChargePreview(supabase, jobId);
        if (cancelled) return;
        if (!preview) {
          setPayableTotalClp(null);
          setChargeLockError('No pudimos calcular el total. Reintenta antes de pagar.');
        } else {
          setPayableTotalClp(preview.totalClp);
          setChargeLockError(null);
        }
      } catch (err) {
        if (cancelled) return;
        setPayableTotalClp(null);
        setChargeLockError(
          err instanceof Error
            ? err.message
            : 'No pudimos calcular el total. Reintenta antes de pagar.',
        );
      } finally {
        if (!cancelled) setChargeLocking(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [
    showCheckout,
    profile,
    selectedWorker,
    selectedServiceId,
    scheduledAt,
    chargeSite,
    checkoutJobId,
    chargeAttempt,
    query,
    serviceMatch,
  ]);

  useEffect(() => {
    if (!showGuestCheckout || !selectedWorker || !clientLocation) {
      return;
    }
    let cancelled = false;
    setGuestPayableClp(null);
    setGuestQuoteError(null);
    void previewGuestCharge(supabase, {
      workerId: selectedWorker.id,
      latitude: clientLocation.latitude,
      longitude: clientLocation.longitude,
    })
      .then((quote) => {
        if (!cancelled) setGuestPayableClp(quote.totalClp);
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          setGuestPayableClp(null);
          setGuestQuoteError(
            err instanceof Error ? err.message : 'No pudimos calcular el total. Reintenta antes de pagar.',
          );
        }
      });
    return () => {
      cancelled = true;
    };
  }, [showGuestCheckout, selectedWorker, clientLocation]);
  const listedWorkers = (serviceMatch?.workers ?? []).filter((worker) => {
    if (!clientLocation) return true;
    const quote = quoteFor(worker, clientLocation);
    return !catalogPinTooFar(quote?.distanceKm);
  });
  const radarHint = selectedWorker
    ? 'El total, con traslado, se muestra al pagar.'
    : undefined;

  const pickClientLocation = (site: MapSite) => {
    setClientLocation(site);
    setClientLocationSource('map');
    setBookingError(null);
  };

  const resolveJobAddress = async (queryText: string): Promise<MapSite | null> => {
    const hit = await geocodeChileAddress(queryText);
    if (!hit) return null;
    const site = { latitude: hit.latitude, longitude: hit.longitude };
    setClientLocation(site);
    setClientLocationSource('address');
    return site;
  };

  const searchJobAddress = async (queryText: string, quiet = false) => {
    setLocatingAddress(true);
    if (!quiet) setBookingError(null);
    try {
      const site = await resolveJobAddress(queryText);
      if (!site && !quiet) {
        setBookingError(
          'No encontramos esa dirección. Prueba con calle y ciudad, o marca el punto en el mapa.',
        );
      }
      return site;
    } catch {
      if (!quiet) {
        setBookingError(
          'No se pudo buscar la dirección. Márcala en el mapa o usa el GPS si tu equipo lo tiene.',
        );
      }
      return null;
    } finally {
      setLocatingAddress(false);
    }
  };

  const useMyLocation = () => {
    if (!navigator.geolocation) {
      setBookingError(
        'Este equipo no tiene GPS. Escribe una dirección o marca el punto en el mapa.',
      );
      return;
    }
    setLocating(true);
    setBookingError(null);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setClientLocation({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
        });
        setClientLocationSource('gps');
        setLocating(false);
      },
      () => {
        setLocating(false);
        setBookingError(
          'No pudimos leer el GPS. Escribe una dirección o marca el punto en el mapa.',
        );
      },
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 30000 },
    );
  };

  const startCheckout = async (slotIso?: string) => {
    if (!selectedWorker) return;
    if (!selectedServiceId) {
      setBookingError('No hay un servicio activo en Supabase para esta categoría.');
      return;
    }
    if (!slotIso) {
      setBookingError('Elige un horario publicado por el profesional para continuar.');
      return;
    }
    registrarEventoUso(EVENTOS_USO.eligioHora, {
      id_profesional: selectedWorker.id,
      hora: slotIso,
    });
    setScheduledAt(slotIso);
    setBookingError(null);
    if (authLoading) {
      setBookingError('Estamos confirmando tu sesión. Inténtalo en un momento.');
      return;
    }

    // Sin sesión: la vista previa del servidor fija el total antes del botón.
    // Con sesión: el pedido pendiente se crea al abrir el cobro, con el punto
    // de ese momento, y el botón usa ese total.
    if (!profile) {
      setJobSiteBound(undefined);
      setShowGuestCheckout(true);
      return;
    }

    setJobSiteBound(undefined);
    setCheckoutJobId(null);
    setShowCheckout(true);
  };

  const confirmBooking = async () => {
    setShowCheckout(false);
    setShowGuestCheckout(false);
    setView('tracking');
    setBookingError(null);
  };

  const payWithWebpay = async (options?: { saveCard?: boolean }) => {
    if (!selectedWorker || !selectedServiceId || !profile) {
      throw new Error('Falta el trabajo para confirmar el pedido.');
    }

    const jobId = checkoutJobId;
    if (!jobId || payableTotalClp == null) {
      throw new Error('Espera a que calculemos el total antes de pagar.');
    }
    const preview = await fetchJobChargePreview(supabase, jobId);
    if (!preview) {
      setPayableTotalClp(null);
      setChargeLockError('No pudimos calcular el total. Reintenta antes de pagar.');
      throw new Error('No pudimos calcular el total. Reintenta antes de pagar.');
    }
    if (preview.totalClp !== payableTotalClp) {
      setPayableTotalClp(preview.totalClp);
    }
    const amountClp = preview.totalClp;

    sessionStorage.setItem(
      'mwa-pending-checkout',
      JSON.stringify({
        jobId,
        worker: selectedWorker,
        serviceTitle: serviceMatch?.categoryName,
        amount: amountClp,
      }),
    );
    const charged = await chargeSavedCard(supabase, {
      jobId,
      amountClp,
    });
    if (charged.charged) {
      await openJobForWorker(supabase, jobId);
      return charged;
    }
    const cardDroppedByBank = !charged.charged && charged.reason === 'tarjeta_inactiva';
    if (options?.saveCard || cardDroppedByBank) {
      // Se inscribe la tarjeta una vez y al volver el servidor cobra este pedido.
      // Los siguientes pedidos se cobran solos, sin volver a escribir la tarjeta.
      const enrollment = await startCardEnrollment(supabase, { jobId });
      window.location.assign(enrollment.handoffUrl);
      return { charged: false, redirected: true } as const;
    }
    const session = await createWebpaySession(supabase, {
      jobId,
      amountClp,
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
    const typedAddress = data.address.trim();
    const pinIsIntentional =
      clientLocationSource === 'map' || clientLocationSource === 'gps';
    let guestSite = clientLocation;
    if (typedAddress && !pinIsIntentional) {
      guestSite = (await resolveJobAddress(typedAddress)) ?? guestSite;
    }
    if (!guestSite) {
      throw new Error(
        'No encontramos esa dirección. Escríbela con calle y ciudad, o marca el punto en el mapa.',
      );
    }
    if (guestPayableClp == null) {
      throw new Error('Espera a que calculemos el total antes de pagar.');
    }
    const fresh = await previewGuestCharge(supabase, {
      workerId: selectedWorker.id,
      latitude: guestSite.latitude,
      longitude: guestSite.longitude,
    });
    if (fresh.totalClp !== guestPayableClp) {
      setGuestPayableClp(fresh.totalClp);
    }
    const guestAmount = fresh.totalClp;
    const session = await createGuestWebpayCheckout(supabase, {
      ...data,
      workerId: selectedWorker.id,
      serviceId: selectedServiceId,
      description: serviceMatch?.problem ?? query,
      amountClp: guestAmount,
      latitude: guestSite.latitude,
      longitude: guestSite.longitude,
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

  if (view === 'notfound') return <NotFoundPage />;
  if (view === 'account') return <AccountPage />;
  if (view === 'trabaja') return <WorkWithUsPage />;
  if (view === 'aviso') return <LegalPage kind="aviso" />;
  if (view === 'terminos') return <LegalPage kind="terminos" />;
  if (view === 'privacidad') return <LegalPage kind="privacidad" />;

  if (view === 'paid') {
    return (
      <>
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
          onGoHome={goHome}
        />
      </Suspense>
      <SiteFooter />
      </>
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

          startPin={clientStartPin}

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

          evidencePhotos={jobEvidence}

          unreadCount={unreadCount}

          onGoHome={goHome}

          onBack={() => {
            const closed = ['completado', 'cancelado', 'expirado', 'no_asistio']
              .includes(jobSnapshot?.status ?? '');
            if (closed) {
              goHome();
              return;
            }
            // Un pedido abierto desde Mis pedidos o tras recargar no trae resultados de búsqueda.
            sessionStorage.removeItem('mwa-active-job');
            setView(serviceMatch && serviceMatch.workers.length > 0 ? 'search' : 'landing');
          }}

          onOpenChat={() => setShowChat(true)}

          clientActions={checkoutJobId && profile && jobSnapshot && jobSnapshot.userId === profile.id ? (
            <>
            <ChangeOrderPanel jobId={checkoutJobId} />
            <JobClientActions
              jobId={checkoutJobId}
              status={jobSnapshot.status}
              scheduledAt={jobSnapshot.scheduledAt}
              workerId={jobSnapshot.workerId}
              workerName={selectedWorker.name}
              userId={profile.id}
              disputeOpen={openDispute != null}
              disputeOpenedBy={openDispute?.openedBy ?? null}
              onChanged={() => {
                void fetchJobTrackingSnapshot(supabase, checkoutJobId)
                  .then((snapshot) => {
                    if (snapshot) setJobSnapshot(snapshot);
                  })
                  .catch(() => {
                    // El refresco periódico vuelve a intentarlo.
                  });
              }}
            />
            </>
          ) : null}

          evidence={checkoutJobId && profile ? (
            <JobEvidencePanel
              jobId={checkoutJobId}
              userId={profile.id}
              readOnly={['completado', 'cancelado', 'expirado', 'rechazado'].includes(jobSnapshot?.status ?? '')}
            />
          ) : null}

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
            if (error) {
              throw new Error(
                /cerrado/i.test(error.message)
                  ? 'El trabajo ya está cerrado: no admite disputas.'
                  : /ya existe/i.test(error.message)
                    ? 'Ya hay una disputa abierta para este trabajo.'
                    : 'No se pudo abrir la disputa.',
              );
            }
            setOpenDispute({ openedBy: profile.id });
          } : undefined}

          pendingAgreement={pendingAgreement}
          disputeOpen={openDispute != null}
          onProposeAgreement={profile ? async (tipo) => {
            if (!checkoutJobId) throw new Error('Falta el trabajo.');
            const { error } = await supabase.rpc('proponer_acuerdo', {
              p_id: crypto.randomUUID(),
              p_id_trabajo: checkoutJobId,
              p_tipo: tipo,
            });
            if (error) throw new Error(agreementErrorMessage(error.message, 'proponer'));
            const { data } = await supabase.rpc('acuerdo_pendiente', { p_id_trabajo: checkoutJobId });
            const row = data?.[0];
            setPendingAgreement(row ? { id: row.id, tipo: row.tipo } : null);
          } : undefined}
          onRespondAgreement={profile && pendingAgreement ? async (acepta) => {
            const { error } = await supabase.rpc('responder_acuerdo', {
              p_id: pendingAgreement.id,
              p_acepta: acepta,
            });
            if (error) throw new Error(agreementErrorMessage(error.message, 'responder'));
            if (!checkoutJobId) return;
            const { data } = await supabase.rpc('acuerdo_pendiente', { p_id_trabajo: checkoutJobId });
            const row = data?.[0];
            setPendingAgreement(row ? { id: row.id, tipo: row.tipo } : null);
          } : undefined}
          onAppealDispute={profile ? async (motivo) => {
            if (!checkoutJobId) throw new Error('Falta el trabajo.');
            const { data, error } = await supabase
              .from('disputas')
              .select('id, estado, origen')
              .eq('id_trabajo', checkoutJobId)
              .order('creado_en', { ascending: false })
              .limit(1);
            if (error) throw new Error('No se pudo leer la disputa.');
            const row = data?.[0];
            if (!row || row.estado !== 'resuelta' || row.origen !== 'sistema') {
              throw new Error('Solo se puede apelar un cierre automático reciente.');
            }
            const { error: appealError } = await supabase.rpc('apelar_disputa', {
              p_id: row.id,
              p_motivo: motivo,
            });
            if (appealError) throw new Error('No se pudo pedir la revisión.');
          } : undefined}

          onAddDisputeComment={profile ? async (comment) => {
            if (!checkoutJobId) throw new Error('Falta el trabajo.');
            const { data, error } = await supabase
              .from('disputas')
              .select('id')
              .eq('id_trabajo', checkoutJobId)
              .in('estado', ['abierta', 'en_revision', 'requiere_humano', 'reembolso_pendiente'])
              .order('creado_en', { ascending: false })
              .limit(1)
              .maybeSingle();
            if (error) throw new Error('No se pudo leer la disputa.');
            if (!data?.id) throw new Error('No hay una disputa abierta en este trabajo.');
            const { error: commentError } = await supabase.rpc('comentar_disputa', {
              p_id: data.id,
              p_comentario: comment,
            });
            if (commentError) throw new Error('No se pudo agregar el comentario.');
          } : undefined}

        />

        {showNotifications && (
          <NotificationInbox
            notices={notices}
            jobTitles={noticeJobTitles}
            onClose={() => setShowNotifications(false)}
            onOpen={openNotice}
          />
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

        <SiteFooter />
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
          <SiteFooter />
          <Suspense fallback={null}>
            <AuthModal open={showAuth} initialEmail={authInitialEmail} onClose={() => setShowAuth(false)} />
          </Suspense>
        </div>
      </Suspense>
    );
  }

  if (view === 'search' || view === 'profile') {

    return (
      <Suspense fallback={<ViewFallback />}>
      <div className="min-h-screen app-shell app-shell--search">

        {view === 'profile' ? (
          <ProfessionalProfilePage
            onReserve={(worker) => {
              setSelectedWorker(worker);
              if (!worker.category) return;
              void fetchServiceByCategory(supabase, worker.category).then((service) => {
                if (service) setSelectedServiceId(service.id);
              });
            }}
          />
        ) : null}
        {view === 'search' ? (
        <SearchResultsView

          query={query}

          workers={listedWorkers}

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
          onOpenNotifications={() => setShowNotifications(true)}
          onLogout={() => void logout()}
          unreadCount={unreadCount}
          hasMore={Boolean(serviceMatch?.nextCursor)}
          isLoadingMore={loadingMoreWorkers}
          onLoadMore={() => void loadMoreWorkers()}
          clientLocation={clientLocation}
          onUseMyLocation={useMyLocation}
          onPickClientLocation={pickClientLocation}
          onSearchAddress={searchJobAddress}
          locating={locating}
          locatingAddress={locatingAddress}

        />
        ) : null}

        {showNotifications && profile ? (
          <NotificationInbox
            notices={notices}
            jobTitles={noticeJobTitles}
            onClose={() => setShowNotifications(false)}
            onOpen={openNotice}
          />
        ) : null}

        {selectedWorker && (

          <QuickBookingBar

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            pricePerHour={selectedWorker.pricePerVisit}
            radarHint={radarHint}
            loadingSlots={bookingSlotsLoading}
            slots={bookingSlots.map((iso) => ({
              iso,
              label: formatBookingSlotLabel(iso),
            }))}

            onContinue={(slotIso) => void startCheckout(slotIso)}

            onClose={() => setSelectedWorker(null)}

          />

        )}



        {showCheckout && selectedWorker && (

          <PaymentCheckoutModal

            workerName={selectedWorker.name}

            profession={selectedWorker.profession}

            payableTotalClp={payableTotalClp}
            chargeLocking={chargeLocking}
            chargeError={chargeLockError}
            onRetryCharge={() => setChargeAttempt((n) => n + 1)}
            hasJobSite={Boolean(chargeSite)}
            onUseAddress={searchJobAddress}
            locatingAddress={locatingAddress}

            serviceDescription={serviceMatch?.problem}

            jobId={checkoutJobId}

            onClose={() => {
              setShowCheckout(false);
              if (!checkoutJobId) setJobSiteBound(undefined);
            }}

            onPayWithWebpay={payWithWebpay}
            loadSavedCard={() => getSavedCard(supabase)}
            onRemoveSavedCard={() => removeSavedCard(supabase)}

            onSuccess={(details) => {
              registrarEventoUso(EVENTOS_USO.confirmoPedido, {
                ...(checkoutJobId ? { id_trabajo: checkoutJobId } : {}),
                id_profesional: selectedWorker.id,
              });
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
            payableTotalClp={guestPayableClp}
            quoteError={guestQuoteError}
            serviceDescription={serviceMatch?.problem}
            onClose={() => {
              setShowGuestCheckout(false);
              setJobSiteBound(undefined);
            }}
            onSubmit={submitGuestCheckout}
            onPreviewAddress={(queryText) => searchJobAddress(queryText, true)}
            locatingAddress={locatingAddress}
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
        {view === 'search' ? <SiteFooter /> : null}

      </div>
      </Suspense>
    );

  }



  return (
    <>
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
    <SiteFooter />
    </>
  );

}



export default App;

