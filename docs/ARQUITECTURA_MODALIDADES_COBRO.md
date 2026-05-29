# Arquitectura de modalidades de cobro — MyWorksApp (Chile)

> Diseño alineado al stack actual: **Flutter + Riverpod + GoRouter + SQLite (sqlcipher)**  
> y evolución hacia **PostgreSQL + API REST** (Supabase / Node / similar).

---

## 0. Principios de diseño

### Separación de responsabilidades

| Capa | Responsabilidad |
|------|-----------------|
| **`JobModel` + `JobStateMachine`** | Ciclo de vida operativo del trabajo (quién hace qué, cuándo inicia/termina) |
| **`PaymentService` + tabla `payments`** | Dinero: autorización, escrow (`authorized`), liberación (`released`), reembolso (`refunded`) |
| **`PricingService`** | Cálculo de montos según modalidad, comuna, SKU o tarifa hora |
| **Modalidad (`pricing_mode`)** | Reglas distintas sobre el **mismo** esqueleto de estados |

### Nueva dimensión: `pricing_mode`

```dart
enum PricingMode {
  fixedPrice,    // Precio fijo pre-tasado
  hourlyBlock,   // Bloque de horas
  openQuote,     // Cotización abierta (RFP)
}
```

En PostgreSQL: `pricing_mode VARCHAR` con CHECK constraint.

### Estados de pago (ya en `PaymentModel`)

| Estado | Significado | Equivalente Angi / marketplace |
|--------|-------------|--------------------------------|
| `pending` | Intento de cobro iniciado | Checkout iniciado |
| `authorized` | Fondos capturados en **garantía (escrow)** | Held / pre-auth |
| `held` | Congelado por disputa u orden de cambio | Dispute hold |
| `released` | Liberado al trabajador | Payout |
| `refunded` | Devuelto al cliente | Refund |

**Regla de oro:** `JobStateMachine` **no** pasa a `in_progress` si la modalidad exige escrow y el pago principal no está en `authorized`.

---

## 1. Evolución del `JobStateMachine`

### 1.1 Estados operativos nuevos (extensión de `AppConstants`)

Mantener los actuales y añadir:

```dart
// Operativos
static const String jobStatusDraft = 'draft';                    // Cotización: borrador cliente
static const String jobStatusAwaitingQuotes = 'awaiting_quotes'; // Cotización: recibiendo presupuestos
static const String jobStatusQuoteSelected = 'quote_selected';   // Cotización: presupuesto elegido
static const String jobStatusAwaitingPayment = 'awaiting_payment'; // Esperando escrow
static const String jobStatusPaymentHeld = 'payment_held';       // Disputa / change order pendiente
static const String jobStatusPausedChangeOrder = 'paused_change_order'; // En curso pero pausado
```

Los estados `expired`, `no_show`, `cancelled`, `completed` se mantienen.

### 1.2 Estados de pago paralelos (consulta, no duplicar en `job.status`)

Tabla `payments` + opcional `job.payment_status` denormalizado para UI:

```
payment_status: none | pending | authorized | held | released | refunded
```

`JobStateMachine.transitionTo()` debe llamar a un **guard**:

```dart
Future<void> _assertPaymentGuard(JobModel job, String targetStatus) async {
  final mode = job.pricingMode; // nuevo campo
  final payment = await PaymentService.instance.getPrimaryPayment(job.id);

  switch (mode) {
    case PricingMode.fixedPrice:
    case PricingMode.hourlyBlock:
      if (targetStatus == jobStatusInProgress) {
        require(payment?.status == 'authorized');
      }
      break;
    case PricingMode.openQuote:
      if (targetStatus == jobStatusAccepted || targetStatus == jobStatusInProgress) {
        require(payment?.status == 'authorized'); // pago del presupuesto ganador
      }
      break;
  }
}
```

### 1.3 Diagramas por modalidad

#### A) PRECIO FIJO (`fixed_price`)

```
[Cliente agenda]
     │
     ▼
awaiting_payment ──(PaymentService.authorize)──► accepted
     │                                              │
     │ cancel                                         ▼
     ▼                                          in_progress
cancelled / expired                                  │
                                                       ├──► paused_change_order ──► (pago adicional authorized) ──► in_progress
                                                       ▼
                                                  completed ──► (PaymentService.release) ──► payment released
```

| Paso | `job.status` | `payment.status` | Acción |
|------|--------------|------------------|--------|
| Crear solicitud + checkout | `awaiting_payment` | `pending` → `authorized` | `PricingService.calculateFixed()` |
| Pago OK | `accepted` | `authorized` | Worker asignado (directo o tras aceptar) |
| Worker inicia visita | `in_progress` | `authorized` | Guard: debe estar `authorized` |
| Trabajo terminado | `completed` | `released` | Liberar escrow (− comisión plataforma) |
| Cancelación antes de inicio | `cancelled` | `refunded` | Política de reembolso |

**Diferencia con hoy:** hoy `quick_booking` salta a `accepted` sin pago; con precio fijo el flujo pasa por `awaiting_payment` → `authorized` → `accepted`.

#### B) COBRO POR HORA (`hourly_block`)

```
awaiting_payment (monto = hourly_rate × horas_bloque)
     │
     ▼ authorized
accepted ──► in_progress ──► completed ──► released
                  │
                  └──► (opcional) overtime / change_order si excede bloque
```

| Paso | Detalle |
|------|---------|
| Cotización implícita | `PricingService`: `worker.hourly_rate_clp × block_hours` (+ recargo comuna) |
| Pago adelantado | `authorized` por el **bloque** (2h, 4h, 8h) |
| Exceso de tiempo | `change_orders` tipo `overtime` antes de `completed` |
| Liberación | Al `completed`; si hubo overtime pagado, un segundo `payment` child |

#### C) COTIZACIÓN ABIERTA (`open_quote`)

```
draft / awaiting_quotes
     │  (workers envían quote_proposals)
     ▼
quote_selected (cliente elige 1 propuesta)
     │
     ▼
awaiting_payment (monto = proposal.total_clp)
     │
     ▼ authorized
accepted ──► in_progress ──► completed ──► released
```

| Paso | `job.status` | Notas |
|------|--------------|-------|
| Publicar RFP | `awaiting_quotes` | Sin workerId fijo |
| Propuestas | — | Tabla `quote_proposals` |
| Elegir presupuesto | `quote_selected` | `workerId` asignado |
| Pagar presupuesto | `awaiting_payment` → `accepted` | Un solo pago principal |
| Resto | Igual que fijo | |

**No** pasa por `pending` genérico de “cualquier worker acepta”; el match es **post-cotización**.

### 1.4 Matriz de transiciones (resumen)

| Desde | Hacia | Condición |
|-------|-------|-----------|
| `awaiting_payment` | `accepted` | `payment.status == authorized` |
| `awaiting_payment` | `cancelled` | Timeout checkout / usuario cancela |
| `accepted` | `in_progress` | Worker + `payment authorized` |
| `in_progress` | `paused_change_order` | Change order enviado |
| `paused_change_order` | `in_progress` | Change order pagado (`authorized`) o rechazado |
| `in_progress` | `completed` | Sin change orders pendientes |
| `completed` | — | `payment` → `released` (job operativo final) |
| `awaiting_quotes` | `quote_selected` | Cliente selecciona propuesta |
| `quote_selected` | `awaiting_payment` | Iniciar checkout del monto acordado |

### 1.5 Integración Flutter (`JobStateMachine`)

```dart
class JobStateMachine {
  Future<JobModel> transitionTo({
    required String jobId,
    required String newStatus,
    String? userId,
  }) async {
    final job = await _jobRepository.getJobById(jobId);
    // 1. Validar transición según pricing_mode
    final matrix = TransitionMatrix.forMode(job.pricingMode);
    if (!matrix.isAllowed(job.status, newStatus)) throw ...;

    // 2. Guards de pago
    await PaymentGuard.validate(job: job!, targetStatus: newStatus);

    // 3. Persistir + side effects
    await _jobRepository.updateJob(...);
    if (newStatus == jobStatusCompleted) {
      await PaymentService.instance.releasePrimaryPayment(jobId);
    }
    return updatedJob;
  }
}
```

`TransitionMatrix` reemplaza el `Map` estático único actual.

---

## 2. Esquema PostgreSQL (backend futuro)

### 2.1 Convenciones

- Moneda por defecto: **CLP** (`currency CHAR(3) DEFAULT 'CLP'`)
- Comunas Chile: tabla `comunas` (código INE o nombre normalizado)
- Categorías alineadas a `ServiceModel.category`:  
  `construction`, `plumbing`, `cleaning`, `assembly`, `tech_support`, `gardening`, `moving`, `locksmith` (cerrajería)

### 2.2 Diagrama entidad-relación (simplificado)

```
service_categories ──< services ──< service_skus (precio fijo)
        │                │
        │                └──< jobs >── payments
        │                      │
comunas ──< comuna_pricing_factors     ├──< quote_proposals
        │                              ├──< change_orders
workers ──< worker_hourly_rates         └──< job_status_history
```

### 2.3 DDL principal

```sql
-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- opcional para matching geo

-- Comunas (Chile)
CREATE TABLE comunas (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo_ine    VARCHAR(10) UNIQUE,
  nombre        VARCHAR(120) NOT NULL,
  region        VARCHAR(80) NOT NULL,
  activa        BOOLEAN NOT NULL DEFAULT TRUE
);

-- Categorías (espejo de services.category)
CREATE TABLE service_categories (
  id          VARCHAR(40) PRIMARY KEY, -- ej. 'plumbing'
  nombre      VARCHAR(120) NOT NULL,
  icono       VARCHAR(60),
  activa      BOOLEAN DEFAULT TRUE
);

-- Servicios del catálogo
CREATE TABLE services (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id     VARCHAR(40) NOT NULL REFERENCES service_categories(id),
  nombre          VARCHAR(200) NOT NULL,
  descripcion     TEXT,
  pricing_mode    VARCHAR(20) NOT NULL CHECK (pricing_mode IN ('fixed_price','hourly_block','open_quote')),
  activo          BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- SKUs precio fijo (ej. "Cambio cilindro cerradura")
CREATE TABLE service_skus (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_id      UUID NOT NULL REFERENCES services(id),
  sku_code        VARCHAR(60) NOT NULL,
  titulo          VARCHAR(200) NOT NULL,
  descripcion     TEXT,
  base_price_clp  INTEGER NOT NULL CHECK (base_price_clp >= 0),
  duracion_min    INTEGER, -- estimada
  activo          BOOLEAN DEFAULT TRUE,
  UNIQUE (service_id, sku_code)
);

-- Factor precio por comuna (multiplicador o recargo fijo)
CREATE TABLE comuna_pricing_factors (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  comuna_id       UUID NOT NULL REFERENCES comunas(id),
  category_id     VARCHAR(40) REFERENCES service_categories(id), -- NULL = global
  factor          NUMERIC(6,4) NOT NULL DEFAULT 1.0000,  -- ej. 1.15 Providencia
  fixed_surcharge_clp INTEGER DEFAULT 0,
  vigente_desde   DATE NOT NULL DEFAULT CURRENT_DATE,
  vigente_hasta   DATE,
  UNIQUE (comuna_id, category_id, vigente_desde)
);

-- Tarifa hora del trabajador
CREATE TABLE worker_hourly_rates (
  worker_id       UUID NOT NULL, -- FK users/workers
  category_id     VARCHAR(40) NOT NULL REFERENCES service_categories(id),
  hourly_rate_clp INTEGER NOT NULL CHECK (hourly_rate_clp > 0),
  bloques_permitidos SMALLINT[] DEFAULT '{2,4,8}', -- horas vendibles
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (worker_id, category_id)
);

-- Solicitud / Job (solicitudes_servicio)
CREATE TABLE jobs (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL,
  worker_id         UUID, -- NULL en open_quote hasta quote_selected
  service_id        UUID NOT NULL REFERENCES services(id),
  pricing_mode      VARCHAR(20) NOT NULL,
  status            VARCHAR(40) NOT NULL,
  payment_status    VARCHAR(20) NOT NULL DEFAULT 'none',

  -- Ubicación
  direccion         TEXT NOT NULL,
  comuna_id         UUID REFERENCES comunas(id),
  lat               DOUBLE PRECISION,
  lng               DOUBLE PRECISION,

  -- Contenido
  descripcion       TEXT,
  scheduled_at      TIMESTAMPTZ,
  metadata          JSONB DEFAULT '{}', -- campos dinámicos por servicio

  -- Pricing snapshot (congelado al pagar)
  pricing_snapshot  JSONB, -- { sku_id, base, factor, total, hours, rate... }

  -- Referencias modalidad
  service_sku_id    UUID REFERENCES service_skus(id),
  hourly_block_hours SMALLINT,
  selected_quote_id UUID, -- FK quote_proposals

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at       TIMESTAMPTZ,
  started_at        TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ
);

CREATE INDEX idx_jobs_user ON jobs(user_id);
CREATE INDEX idx_jobs_worker ON jobs(worker_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_mode ON jobs(pricing_mode);

-- Historial de estados (auditoría)
CREATE TABLE job_status_history (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id      UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  from_status VARCHAR(40),
  to_status   VARCHAR(40) NOT NULL,
  actor_id    UUID,
  reason      TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Pagos (1 job puede tener N pagos: principal + change orders)
CREATE TABLE payments (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id            UUID NOT NULL REFERENCES jobs(id),
  change_order_id   UUID, -- NULL si es pago principal
  tipo              VARCHAR(20) NOT NULL DEFAULT 'primary' CHECK (tipo IN ('primary','change_order','overtime')),
  amount_clp        INTEGER NOT NULL CHECK (amount_clp > 0),
  platform_fee_clp  INTEGER NOT NULL DEFAULT 0,
  currency          CHAR(3) NOT NULL DEFAULT 'CLP',
  status            VARCHAR(20) NOT NULL CHECK (status IN ('pending','authorized','held','released','refunded')),
  payment_method    VARCHAR(30),
  gateway           VARCHAR(30), -- 'mercadopago', 'webpay', 'mock'
  gateway_intent_id VARCHAR(120),
  authorized_at     TIMESTAMPTZ,
  released_at       TIMESTAMPTZ,
  refunded_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_job ON payments(job_id);
CREATE INDEX idx_payments_status ON payments(status);

-- Cotizaciones (cotizaciones_propuestas)
CREATE TABLE quote_proposals (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id          UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  worker_id       UUID NOT NULL,
  monto_total_clp INTEGER NOT NULL CHECK (monto_total_clp > 0),
  descripcion     TEXT NOT NULL,
  validez_hasta   TIMESTAMPTZ,
  desglose        JSONB, -- { materiales: x, mano_obra: y }
  estado          VARCHAR(20) NOT NULL DEFAULT 'submitted'
    CHECK (estado IN ('submitted','withdrawn','accepted','rejected')),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (job_id, worker_id)
);

-- Órdenes de cambio (extensiones)
CREATE TABLE change_orders (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id          UUID NOT NULL REFERENCES jobs(id),
  worker_id       UUID NOT NULL,
  tipo            VARCHAR(30) NOT NULL CHECK (tipo IN ('extra_work','materials','overtime','hidden_damage')),
  titulo          VARCHAR(200) NOT NULL,
  descripcion     TEXT NOT NULL,
  monto_clp       INTEGER NOT NULL CHECK (monto_clp > 0),
  evidencia_urls  JSONB DEFAULT '[]',
  estado          VARCHAR(20) NOT NULL DEFAULT 'pending_client'
    CHECK (estado IN ('pending_client','approved','rejected','paid','cancelled')),
  payment_id      UUID REFERENCES payments(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  responded_at    TIMESTAMPTZ
);

-- Fotos del job / RFP
CREATE TABLE job_attachments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id      UUID NOT NULL REFERENCES jobs(id),
  uploaded_by UUID NOT NULL,
  url         TEXT NOT NULL,
  tipo        VARCHAR(20) DEFAULT 'photo',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 2.4 Relación con categorías actuales

| Flutter `ServiceModel.category` | `service_categories.id` | Modalidad típica |
|--------------------------------|-------------------------|------------------|
| `electrical` | electrical | fixed / hourly |
| `plumbing` | plumbing | fixed / open_quote |
| `locksmith` | locksmith | **fixed_price** (cilindro) |
| `assembly` | assembly | hourly_block |
| `construction` | construction | **open_quote** |
| `cleaning` | cleaning | fixed / hourly |

`PricingService` consulta:

1. `service.pricing_mode` (default por categoría)
2. `service_skus` + `comuna_pricing_factors` (fijo)
3. `worker_hourly_rates` (hora)
4. Sin tabla de precio → `open_quote`

### 2.5 Evolución SQLite local (Flutter)

Migración vN en `database_helper.dart`:

```sql
ALTER TABLE jobs ADD COLUMN pricing_mode TEXT DEFAULT 'fixed_price';
ALTER TABLE jobs ADD COLUMN payment_status TEXT DEFAULT 'none';
ALTER TABLE jobs ADD COLUMN comuna_id TEXT;
ALTER TABLE jobs ADD COLUMN pricing_snapshot TEXT; -- JSON
ALTER TABLE jobs ADD COLUMN service_sku_id TEXT;
ALTER TABLE jobs ADD COLUMN hourly_block_hours INTEGER;
ALTER TABLE jobs ADD COLUMN selected_quote_id TEXT;

CREATE TABLE quote_proposals (...);
CREATE TABLE change_orders (...);
CREATE TABLE comuna_pricing_factors (...); -- cache local opcional
```

---

## 3. Órdenes de cambio (Change Orders)

### 3.1 Flujo de negocio

1. Job en `in_progress`, pago principal `authorized`.
2. Trabajador crea `change_order` (filtración oculta, material extra, horas adicionales).
3. `JobStateMachine` → `paused_change_order` (el timer del bloque horario se congela).
4. Cliente recibe push/notificación → revisa monto + fotos.
5. Cliente **aprueba** → `PaymentService.createPayment(change_order)` → `authorize` → `change_order.estado = paid` → job vuelve a `in_progress`.
6. Cliente **rechaza** → `change_order.estado = rejected` → job vuelve a `in_progress` sin cobro (trabajador puede disputar o cerrar sin ese extra).

### 3.2 Reglas en backend (API)

```
POST /jobs/{id}/change-orders
  → validar: job.status in ('in_progress', 'paused_change_order')
  → validar: requester == job.worker_id
  → crear change_order pending_client
  → PATCH job.status = paused_change_order
  → payment principal → held (opcional, según política)

POST /change-orders/{id}/approve
  → validar: requester == job.user_id
  → crear payment tipo change_order
  → authorize → change_order.paid
  → si todos los CO pendientes resueltos: job → in_progress

POST /change-orders/{id}/reject
  → change_order.rejected
  → job → in_progress si no hay otros pendientes
```

### 3.3 Guard en `JobStateMachine`

```dart
Future<void> transitionTo(...) async {
  if (job.status == jobStatusPausedChangeOrder && newStatus == jobStatusInProgress) {
    final pending = await ChangeOrderRepository.countPending(job.id);
    if (pending > 0) {
      throw AppError.validation('Hay órdenes de cambio sin resolver');
    }
  }
  if (newStatus == jobStatusCompleted) {
    final unpaid = await ChangeOrderRepository.countApprovedUnpaid(job.id);
    if (unpaid > 0) throw AppError.validation('Cobros adicionales pendientes de pago');
  }
}
```

### 3.4 Overtime en modalidad horaria

Si `elapsed_hours > hourly_block_hours`:

- Auto-sugerir `change_order` tipo `overtime` con  
  `monto = (elapsed - block) × worker.hourly_rate_clp`
- Misma máquina: `paused_change_order` hasta pago.

---

## 4. Ejemplos JSON (API `POST /jobs`)

### 4.1 Precio fijo — Cambio de cilindro (cerrajería)

```json
{
  "pricing_mode": "fixed_price",
  "service_id": "550e8400-e29b-41d4-a716-446655440010",
  "service_sku_id": "660e8400-e29b-41d4-a716-446655440001",
  "user_id": "usr_cliente_001",
  "worker_id": "demo-worker-locksmith-1",
  "direccion": "Los Leones 450, Depto 302",
  "comuna": {
    "codigo_ine": "13123",
    "nombre": "Providencia"
  },
  "ubicacion": {
    "lat": -33.4263,
    "lng": -70.6108
  },
  "descripcion": "Cilindro trabado, necesito cambio estándar",
  "scheduled_at": "2026-06-15T10:00:00-04:00",
  "metadata": {
    "tipo_cerradura": "standard",
    "piso": 3,
    "tiene_ascensor": true
  },
  "pricing_request": {
    "tipo": "fixed_price",
    "sku_code": "LOCK_CYLINDER_REPLACE"
  },
  "checkout": {
    "payment_method": "card",
    "return_url": "myworksapp://payment/return"
  }
}
```

**Respuesta esperada (servidor calcula y congela):**

```json
{
  "job_id": "job_abc123",
  "status": "awaiting_payment",
  "pricing_snapshot": {
    "sku_code": "LOCK_CYLINDER_REPLACE",
    "base_price_clp": 45000,
    "comuna_factor": 1.08,
    "comuna_surcharge_clp": 2000,
    "total_clp": 50600,
    "currency": "CLP"
  },
  "payment": {
    "id": "pay_xyz",
    "status": "pending",
    "amount_clp": 50600
  }
}
```

Tras `authorize` → `job.status = "accepted"`.

---

### 4.2 Cobro por hora — Lista de tareas (gasfiter / técnico)

```json
{
  "pricing_mode": "hourly_block",
  "service_id": "550e8400-e29b-41d4-a716-446655440020",
  "user_id": "usr_cliente_002",
  "worker_id": "demo-worker-plumbing-1",
  "direccion": "Av. Apoquindo 3000",
  "comuna": {
    "codigo_ine": "13114",
    "nombre": "Las Condes"
  },
  "ubicacion": {
    "lat": -33.4170,
    "lng": -70.6060
  },
  "descripcion": "Varias reparaciones menores: grifería cocina, sifón lavamanos, revisión presión",
  "scheduled_at": "2026-06-16T14:00:00-04:00",
  "metadata": {
    "task_list": [
      "Revisar grifería cocina",
      "Cambiar sifón lavamanos",
      "Revisar presión agua"
    ],
    "estimated_complexity": "medium"
  },
  "pricing_request": {
    "tipo": "hourly_block",
    "block_hours": 4,
    "worker_hourly_rate_clp": 18500
  },
  "checkout": {
    "payment_method": "card"
  }
}
```

**`pricing_snapshot` en respuesta:**

```json
{
  "pricing_mode": "hourly_block",
  "block_hours": 4,
  "hourly_rate_clp": 18500,
  "subtotal_clp": 74000,
  "platform_fee_clp": 7400,
  "total_clp": 81400,
  "policy": {
    "overtime_requires_change_order": true,
    "max_block_hours": 8
  }
}
```

---

### 4.3 Cotización abierta — Remodelación baño

```json
{
  "pricing_mode": "open_quote",
  "service_id": "550e8400-e29b-41d4-a716-446655440030",
  "user_id": "usr_cliente_003",
  "worker_id": null,
  "direccion": "Pasaje Los Aromos 128",
  "comuna": {
    "codigo_ine": "13101",
    "nombre": "Santiago"
  },
  "ubicacion": {
    "lat": -33.4489,
    "lng": -70.6693
  },
  "descripcion": "Remodelación completa baño 4m²: cambio cerámicos, mueble vanitorio, instalación termo",
  "scheduled_at": "2026-07-01T09:00:00-04:00",
  "metadata": {
    "superficie_m2": 4,
    "incluye_demolicion": true,
    "plazo_deseado_semanas": 3
  },
  "attachments": [
    {
      "url": "https://storage.example/banos/estado_actual_1.jpg",
      "tipo": "photo"
    },
    {
      "url": "https://storage.example/banos/plano_referencia.jpg",
      "tipo": "photo"
    }
  ],
  "pricing_request": {
    "tipo": "open_quote",
    "quote_deadline": "2026-06-20T23:59:59-04:00",
    "presupuesto_referencia_clp": 800000
  }
}
```

**Respuesta inicial:**

```json
{
  "job_id": "job_rfp_789",
  "status": "awaiting_quotes",
  "pricing_mode": "open_quote",
  "quote_deadline": "2026-06-20T23:59:59-04:00"
}
```

**Propuesta del trabajador (`POST /jobs/{id}/quotes`):**

```json
{
  "worker_id": "demo-worker-construction-1",
  "monto_total_clp": 1250000,
  "descripcion": "Incluye demolición, instalación cerámica porcelanato, grifería premium y termo 50L",
  "validez_hasta": "2026-06-25T12:00:00-04:00",
  "desglose": {
    "materiales_clp": 520000,
    "mano_obra_clp": 680000,
    "imprevistos_clp": 50000
  }
}
```

**Cliente acepta (`POST /jobs/{id}/quotes/{quoteId}/accept`) → luego checkout:**

```json
{
  "selected_quote_id": "quote_def456",
  "checkout": {
    "payment_method": "card"
  }
}
```

→ `awaiting_payment` → `authorized` → `accepted` → flujo operativo normal.

---

## 5. Evolución de servicios Flutter

### `PricingService` (interfaces)

```dart
abstract class PricingService {
  Future<PriceQuote> calculateFixed({
    required String skuId,
    required String comunaId,
  });

  Future<PriceQuote> calculateHourlyBlock({
    required String workerId,
    required String categoryId,
    required int blockHours,
    String? comunaId,
  });

  Future<PriceQuote> validateOpenQuote({
    required int proposalAmountClp,
  });
}
```

### `PaymentService` (extensión)

```dart
Future<PaymentModel> authorizePrimary(JobModel job);
Future<PaymentModel> authorizeChangeOrder(ChangeOrderModel co);
Future<void> releaseOnJobCompleted(String jobId);
Future<void> refundOnCancellation(String jobId, CancellationPolicy policy);
```

### Riverpod

```dart
final pricingServiceProvider = Provider<PricingService>((ref) {
  return ref.watch(useBackendProvider)
    ? ApiPricingService(ref.read(apiClientProvider))
    : LocalPricingService();
});
```

---

## 6. Roadmap de implementación sugerido

| Fase | Entregable | Estado |
|------|------------|--------|
| 1 | Migración SQLite v15 + `JobModel` + tablas `quote_proposals` / `change_orders` | ✅ En código |
| 2 | `JobTransitionMatrix` + `PaymentGuard` + `JobStateMachine` integrado | ✅ En código |
| 3 | `PricingService.calculateFixedPrice` / `calculateHourlyBlock` / `ChangeOrderService` | ✅ Stubs locales |
| 4 | UI flujo **fixed_price** (checkout → escrow mock) | ✅ |
| 5 | UI **hourly_block** + overtime | ✅ Solicitud + horas extra |
| 6 | UI **open_quote** + propuestas | ✅ |
| 7 | PostgreSQL + API en nube | Pendiente |
| 8 | Pasarela real (Webpay / Mercado Pago) | **Fuera de alcance MVP** — requiere empresa constituida en Chile; la app usa **checkout simulado** |

### Archivos Flutter (Fase 1)

| Archivo | Rol |
|---------|-----|
| `lib/core/domain/pricing_constants.dart` | Modalidades y estados |
| `lib/core/domain/price_quote.dart` | Snapshot de precio |
| `lib/core/services/job_transition_matrix.dart` | Transiciones por modalidad |
| `lib/core/services/payment_guard.dart` | Guards de escrow |
| `lib/core/services/change_order_service.dart` | Órdenes de cambio |
| `lib/core/database/models/change_order_model.dart` | Modelo CO |
| `lib/core/database/models/quote_proposal_model.dart` | Modelo cotización |
| `lib/core/services/job_booking_service.dart` | Reserva visita `awaiting_payment` |
| `lib/core/widgets/escrow_checkout_sheet.dart` | Checkout mock escrow |
| `lib/core/widgets/pricing_quote_card.dart` | Desglose de precio |
| `lib/features/user/presentation/pages/quick_booking_page.dart` | Flujo pago visita |

---

## Referencias internas

- Estados actuales: `lib/core/utils/constants.dart`
- Máquina de estados: `lib/core/services/job_state_machine.dart`
- Pagos mock: `lib/core/services/payment_service.dart`
- Categorías: `lib/core/database/models/service_model.dart`
