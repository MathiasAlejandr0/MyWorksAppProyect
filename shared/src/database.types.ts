/**
 * GENERATED — no editar a mano salvo emergencia.
 * Fuente: supabase gen types (project wxqrfcqifkfgawrnqmnj)
 * Regenerar: node scripts/gen-supabase-types.mjs
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.5"
  }
  public: {
    Tables: {
      acciones_pendientes: {
        Row: {
          actualizado_en: string
          conteo_reintentos: number | null
          creado_en: string
          datos: string
          estado: string
          id: string
          id_entidad: string | null
          id_usuario: string
          mensaje_error: string | null
          tipo_accion: string
          tipo_entidad: string
        }
        Insert: {
          actualizado_en: string
          conteo_reintentos?: number | null
          creado_en: string
          datos: string
          estado?: string
          id: string
          id_entidad?: string | null
          id_usuario: string
          mensaje_error?: string | null
          tipo_accion: string
          tipo_entidad: string
        }
        Update: {
          actualizado_en?: string
          conteo_reintentos?: number | null
          creado_en?: string
          datos?: string
          estado?: string
          id?: string
          id_entidad?: string | null
          id_usuario?: string
          mensaje_error?: string | null
          tipo_accion?: string
          tipo_entidad?: string
        }
        Relationships: [
          {
            foreignKeyName: "pending_actions_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      banderas_funcionalidad: {
        Row: {
          actualizado_en: string
          creado_en: string
          habilitada: number
          id: string
          id_usuario: string | null
          nombre_bandera: string
          rol: string | null
          version_app: string | null
        }
        Insert: {
          actualizado_en: string
          creado_en: string
          habilitada?: number
          id: string
          id_usuario?: string | null
          nombre_bandera: string
          rol?: string | null
          version_app?: string | null
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          habilitada?: number
          id?: string
          id_usuario?: string | null
          nombre_bandera?: string
          rol?: string | null
          version_app?: string | null
        }
        Relationships: []
      }
      bloqueos_usuario: {
        Row: {
          creado_en: string
          id: string
          id_bloqueado: string
          id_bloqueador: string
        }
        Insert: {
          creado_en: string
          id: string
          id_bloqueado: string
          id_bloqueador: string
        }
        Update: {
          creado_en?: string
          id?: string
          id_bloqueado?: string
          id_bloqueador?: string
        }
        Relationships: []
      }
      calificaciones: {
        Row: {
          comentario: string | null
          creado_en: string
          id: string
          id_trabajo: string
          id_usuario: string | null
          puntaje: number
        }
        Insert: {
          comentario?: string | null
          creado_en: string
          id: string
          id_trabajo: string
          id_usuario?: string | null
          puntaje: number
        }
        Update: {
          comentario?: string | null
          creado_en?: string
          id?: string
          id_trabajo?: string
          id_usuario?: string | null
          puntaje?: number
        }
        Relationships: [
          {
            foreignKeyName: "ratings_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      cancelaciones_trabajo: {
        Row: {
          cancelado_en: string
          cancelado_por: string
          id: string
          id_trabajo: string
          motivo: string
        }
        Insert: {
          cancelado_en: string
          cancelado_por: string
          id: string
          id_trabajo: string
          motivo: string
        }
        Update: {
          cancelado_en?: string
          cancelado_por?: string
          id?: string
          id_trabajo?: string
          motivo?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_cancellations_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      codigos_restablecimiento: {
        Row: {
          codigo: string
          correo: string
          creado_en: string
          expira_en: string
          id: string
          id_usuario: string
          usado: number | null
        }
        Insert: {
          codigo: string
          correo: string
          creado_en: string
          expira_en: string
          id: string
          id_usuario: string
          usado?: number | null
        }
        Update: {
          codigo?: string
          correo?: string
          creado_en?: string
          expira_en?: string
          id?: string
          id_usuario?: string
          usado?: number | null
        }
        Relationships: []
      }
      configuraciones_servicio: {
        Row: {
          actualizado_en: string
          creado_en: string
          esquema_config: string
          id: string
          id_servicio: string
        }
        Insert: {
          actualizado_en: string
          creado_en: string
          esquema_config: string
          id: string
          id_servicio: string
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          esquema_config?: string
          id?: string
          id_servicio?: string
        }
        Relationships: [
          {
            foreignKeyName: "service_configs_serviceId_fkey"
            columns: ["id_servicio"]
            isOneToOne: true
            referencedRelation: "servicios"
            referencedColumns: ["id"]
          },
        ]
      }
      consentimientos_usuario: {
        Row: {
          aceptado: number
          aceptado_en: string
          agente_usuario: string | null
          direccion_ip: string | null
          id: string
          id_usuario: string
          version_consentimiento: string
        }
        Insert: {
          aceptado?: number
          aceptado_en: string
          agente_usuario?: string | null
          direccion_ip?: string | null
          id: string
          id_usuario: string
          version_consentimiento: string
        }
        Update: {
          aceptado?: number
          aceptado_en?: string
          agente_usuario?: string | null
          direccion_ip?: string | null
          id?: string
          id_usuario?: string
          version_consentimiento?: string
        }
        Relationships: [
          {
            foreignKeyName: "user_consents_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      disputas: {
        Row: {
          abierta_por: string
          actualizado_en: string
          creado_en: string
          descripcion: string | null
          estado: string
          id: string
          id_trabajo: string
          motivo: string
          resolucion: string | null
          resuelta_en: string | null
          resuelta_por: string | null
        }
        Insert: {
          abierta_por: string
          actualizado_en: string
          creado_en: string
          descripcion?: string | null
          estado: string
          id: string
          id_trabajo: string
          motivo: string
          resolucion?: string | null
          resuelta_en?: string | null
          resuelta_por?: string | null
        }
        Update: {
          abierta_por?: string
          actualizado_en?: string
          creado_en?: string
          descripcion?: string | null
          estado?: string
          id?: string
          id_trabajo?: string
          motivo?: string
          resolucion?: string | null
          resuelta_en?: string | null
          resuelta_por?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "disputes_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      eventos_abuso: {
        Row: {
          accion_tomada: string | null
          accion_tomada_en: string | null
          conteo: number
          detectado_en: string
          id: string
          id_usuario: string
          resuelto: number | null
          tipo_abuso: string
        }
        Insert: {
          accion_tomada?: string | null
          accion_tomada_en?: string | null
          conteo: number
          detectado_en: string
          id: string
          id_usuario: string
          resuelto?: number | null
          tipo_abuso: string
        }
        Update: {
          accion_tomada?: string | null
          accion_tomada_en?: string | null
          conteo?: number
          detectado_en?: string
          id?: string
          id_usuario?: string
          resuelto?: number | null
          tipo_abuso?: string
        }
        Relationships: [
          {
            foreignKeyName: "abuse_events_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      eventos_analitica: {
        Row: {
          id: string
          id_usuario: string | null
          marca_tiempo: string
          metadatos: string | null
          nombre_evento: string
          rol: string | null
        }
        Insert: {
          id: string
          id_usuario?: string | null
          marca_tiempo: string
          metadatos?: string | null
          nombre_evento: string
          rol?: string | null
        }
        Update: {
          id?: string
          id_usuario?: string | null
          marca_tiempo?: string
          metadatos?: string | null
          nombre_evento?: string
          rol?: string | null
        }
        Relationships: []
      }
      fotos_trabajo: {
        Row: {
          creado_en: string
          id: string
          id_trabajo: string
          ruta_foto: string
          tipo_medio: string
        }
        Insert: {
          creado_en: string
          id: string
          id_trabajo: string
          ruta_foto: string
          tipo_medio?: string
        }
        Update: {
          creado_en?: string
          id?: string
          id_trabajo?: string
          ruta_foto?: string
          tipo_medio?: string
        }
        Relationships: [
          {
            foreignKeyName: "job_photos_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      impulsos: {
        Row: {
          creado_en: string
          fecha_fin: string
          fecha_inicio: string
          id: string
          id_trabajador: string
          tipo_impulso: string
        }
        Insert: {
          creado_en: string
          fecha_fin: string
          fecha_inicio: string
          id: string
          id_trabajador: string
          tipo_impulso: string
        }
        Update: {
          creado_en?: string
          fecha_fin?: string
          fecha_inicio?: string
          id?: string
          id_trabajador?: string
          tipo_impulso?: string
        }
        Relationships: [
          {
            foreignKeyName: "boosts_workerId_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      mensajes: {
        Row: {
          contenido: string
          creado_en: string
          id: string
          id_destinatario: string
          id_remitente: string
          id_trabajo: string
          leido: number
          ruta_imagen: string | null
          tipo: string
        }
        Insert: {
          contenido: string
          creado_en: string
          id: string
          id_destinatario: string
          id_remitente: string
          id_trabajo: string
          leido?: number
          ruta_imagen?: string | null
          tipo?: string
        }
        Update: {
          contenido?: string
          creado_en?: string
          id?: string
          id_destinatario?: string
          id_remitente?: string
          id_trabajo?: string
          leido?: number
          ruta_imagen?: string | null
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: "messages_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      notificaciones: {
        Row: {
          creado_en: string
          cuerpo: string
          id: string
          id_relacionado: string | null
          id_usuario: string
          leido: number
          tipo: string
          titulo: string
        }
        Insert: {
          creado_en: string
          cuerpo: string
          id: string
          id_relacionado?: string | null
          id_usuario: string
          leido?: number
          tipo: string
          titulo: string
        }
        Update: {
          creado_en?: string
          cuerpo?: string
          id?: string
          id_relacionado?: string | null
          id_usuario?: string
          leido?: number
          tipo?: string
          titulo?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      ordenes_cambio: {
        Row: {
          creado_en: string
          descripcion: string
          estado: string
          id: string
          id_pago: string | null
          id_trabajador: string
          id_trabajo: string
          monto_clp: number
          respondido_en: string | null
          tipo: string
          titulo: string
        }
        Insert: {
          creado_en: string
          descripcion: string
          estado?: string
          id: string
          id_pago?: string | null
          id_trabajador: string
          id_trabajo: string
          monto_clp: number
          respondido_en?: string | null
          tipo: string
          titulo: string
        }
        Update: {
          creado_en?: string
          descripcion?: string
          estado?: string
          id?: string
          id_pago?: string | null
          id_trabajador?: string
          id_trabajo?: string
          monto_clp?: number
          respondido_en?: string | null
          tipo?: string
          titulo?: string
        }
        Relationships: [
          {
            foreignKeyName: "change_orders_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      pagos: {
        Row: {
          actualizado_en: string
          autorizado_en: string | null
          creado_en: string
          estado: string
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          reembolsado_en: string | null
          tipo_pago: string
        }
        Insert: {
          actualizado_en: string
          autorizado_en?: string | null
          creado_en: string
          estado: string
          id: string
          id_orden_cambio?: string | null
          id_trabajo: string
          id_transaccion?: string | null
          liberado_en?: string | null
          metodo_pago?: string | null
          moneda?: string
          monto: number
          reembolsado_en?: string | null
          tipo_pago?: string
        }
        Update: {
          actualizado_en?: string
          autorizado_en?: string | null
          creado_en?: string
          estado?: string
          id?: string
          id_orden_cambio?: string | null
          id_trabajo?: string
          id_transaccion?: string | null
          liberado_en?: string | null
          metodo_pago?: string | null
          moneda?: string
          monto?: number
          reembolsado_en?: string | null
          tipo_pago?: string
        }
        Relationships: [
          {
            foreignKeyName: "payments_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      perfiles: {
        Row: {
          correo: string | null
          creado_en: string
          estado_cuenta: string
          id: string
          nombre: string
          rol: string
          ruta_foto_perfil: string | null
        }
        Insert: {
          correo?: string | null
          creado_en?: string
          estado_cuenta?: string
          id?: string
          nombre?: string
          rol?: string
          ruta_foto_perfil?: string | null
        }
        Update: {
          correo?: string | null
          creado_en?: string
          estado_cuenta?: string
          id?: string
          nombre?: string
          rol?: string
          ruta_foto_perfil?: string | null
        }
        Relationships: []
      }
      portafolio_trabajador: {
        Row: {
          creado_en: string
          descripcion: string | null
          id: string
          id_trabajador: string
          ruta_foto: string
          tipo_medio: string | null
        }
        Insert: {
          creado_en: string
          descripcion?: string | null
          id: string
          id_trabajador: string
          ruta_foto: string
          tipo_medio?: string | null
        }
        Update: {
          creado_en?: string
          descripcion?: string | null
          id?: string
          id_trabajador?: string
          ruta_foto?: string
          tipo_medio?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "worker_portfolio_workerId_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      propuestas_cotizacion: {
        Row: {
          creado_en: string
          descripcion: string
          desglose: string | null
          estado: string
          id: string
          id_trabajador: string
          id_trabajo: string
          monto_total_clp: number
          validez_hasta: string | null
        }
        Insert: {
          creado_en: string
          descripcion: string
          desglose?: string | null
          estado: string
          id: string
          id_trabajador: string
          id_trabajo: string
          monto_total_clp: number
          validez_hasta?: string | null
        }
        Update: {
          creado_en?: string
          descripcion?: string
          desglose?: string | null
          estado?: string
          id?: string
          id_trabajador?: string
          id_trabajo?: string
          monto_total_clp?: number
          validez_hasta?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "quote_proposals_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "quote_proposals_workerId_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      registros_error_app: {
        Row: {
          creado_en: string
          estado: string
          id: string
          id_usuario: string | null
          mensaje: string
          metadatos: Json | null
          plataforma: string | null
          tipo_error: string
          traza_pila: string | null
          version_app: string | null
        }
        Insert: {
          creado_en?: string
          estado?: string
          id: string
          id_usuario?: string | null
          mensaje: string
          metadatos?: Json | null
          plataforma?: string | null
          tipo_error?: string
          traza_pila?: string | null
          version_app?: string | null
        }
        Update: {
          creado_en?: string
          estado?: string
          id?: string
          id_usuario?: string | null
          mensaje?: string
          metadatos?: Json | null
          plataforma?: string | null
          tipo_error?: string
          traza_pila?: string | null
          version_app?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "app_error_logs_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reportes: {
        Row: {
          creado_en: string
          descripcion: string | null
          estado: string
          id: string
          id_reportante: string
          id_usuario_reportado: string
          motivo: string
        }
        Insert: {
          creado_en: string
          descripcion?: string | null
          estado?: string
          id: string
          id_reportante: string
          id_usuario_reportado: string
          motivo: string
        }
        Update: {
          creado_en?: string
          descripcion?: string | null
          estado?: string
          id?: string
          id_reportante?: string
          id_usuario_reportado?: string
          motivo?: string
        }
        Relationships: []
      }
      servicios: {
        Row: {
          activo: number
          actualizado_en: string | null
          aviso_legal: string | null
          categoria: string
          creado_en: string | null
          descripcion: string | null
          id: string
          modelo_precio: string
          nombre: string
          requiere_certificacion: number
        }
        Insert: {
          activo?: number
          actualizado_en?: string | null
          aviso_legal?: string | null
          categoria?: string
          creado_en?: string | null
          descripcion?: string | null
          id: string
          modelo_precio?: string
          nombre: string
          requiere_certificacion?: number
        }
        Update: {
          activo?: number
          actualizado_en?: string | null
          aviso_legal?: string | null
          categoria?: string
          creado_en?: string | null
          descripcion?: string | null
          id?: string
          modelo_precio?: string
          nombre?: string
          requiere_certificacion?: number
        }
        Relationships: []
      }
      suscripciones: {
        Row: {
          actualizado_en: string
          creado_en: string
          estado: string
          fecha_fin: string | null
          fecha_inicio: string
          id: string
          id_usuario: string
          tipo_plan: string
        }
        Insert: {
          actualizado_en: string
          creado_en: string
          estado: string
          fecha_fin?: string | null
          fecha_inicio: string
          id: string
          id_usuario: string
          tipo_plan: string
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          estado?: string
          fecha_fin?: string | null
          fecha_inicio?: string
          id?: string
          id_usuario?: string
          tipo_plan?: string
        }
        Relationships: [
          {
            foreignKeyName: "subscriptions_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      tickets_soporte: {
        Row: {
          asunto: string
          creado_en: string | null
          estado: string | null
          id: string
          id_trabajo: string | null
          monto_escrow: number
          nombre_cliente: string
          nombre_trabajador: string
        }
        Insert: {
          asunto: string
          creado_en?: string | null
          estado?: string | null
          id?: string
          id_trabajo?: string | null
          monto_escrow: number
          nombre_cliente: string
          nombre_trabajador: string
        }
        Update: {
          asunto?: string
          creado_en?: string | null
          estado?: string | null
          id?: string
          id_trabajo?: string | null
          monto_escrow?: number
          nombre_cliente?: string
          nombre_trabajador?: string
        }
        Relationships: []
      }
      trabajador_servicios: {
        Row: {
          categoria_servicio: string
          id_trabajador: string
        }
        Insert: {
          categoria_servicio: string
          id_trabajador: string
        }
        Update: {
          categoria_servicio?: string
          id_trabajador?: string
        }
        Relationships: [
          {
            foreignKeyName: "worker_services_workerId_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      trabajadores: {
        Row: {
          calificacion: number
          categoria_servicio: string
          conteo_rechazos: number
          descripcion: string | null
          disponible: number
          id_usuario: string
          niveles_precio: Json
          precios_configurados: number
          profesion: string
          servicios_personalizados: Json
          tarifa_visita: number
          zona_trabajo: string | null
        }
        Insert: {
          calificacion?: number
          categoria_servicio?: string
          conteo_rechazos?: number
          descripcion?: string | null
          disponible?: number
          id_usuario: string
          niveles_precio?: Json
          precios_configurados?: number
          profesion?: string
          servicios_personalizados?: Json
          tarifa_visita?: number
          zona_trabajo?: string | null
        }
        Update: {
          calificacion?: number
          categoria_servicio?: string
          conteo_rechazos?: number
          descripcion?: string | null
          disponible?: number
          id_usuario?: string
          niveles_precio?: Json
          precios_configurados?: number
          profesion?: string
          servicios_personalizados?: Json
          tarifa_visita?: number
          zona_trabajo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "trabajadores_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: true
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      trabajos: {
        Row: {
          actualizado_en: string
          creado_en: string
          descripcion: string | null
          direccion: string
          estado: string
          estado_pago: string | null
          fecha_programada: string | null
          horas_bloque: number | null
          id: string
          id_comuna: string | null
          id_cotizacion_seleccionada: string | null
          id_servicio: string | null
          id_sku_servicio: string | null
          id_trabajador: string | null
          id_usuario: string
          instantanea_precio: string | null
          latitud: number | null
          longitud: number | null
          metadatos_servicio: string | null
          modalidad_cobro: string | null
        }
        Insert: {
          actualizado_en: string
          creado_en: string
          descripcion?: string | null
          direccion?: string
          estado: string
          estado_pago?: string | null
          fecha_programada?: string | null
          horas_bloque?: number | null
          id: string
          id_comuna?: string | null
          id_cotizacion_seleccionada?: string | null
          id_servicio?: string | null
          id_sku_servicio?: string | null
          id_trabajador?: string | null
          id_usuario: string
          instantanea_precio?: string | null
          latitud?: number | null
          longitud?: number | null
          metadatos_servicio?: string | null
          modalidad_cobro?: string | null
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          descripcion?: string | null
          direccion?: string
          estado?: string
          estado_pago?: string | null
          fecha_programada?: string | null
          horas_bloque?: number | null
          id?: string
          id_comuna?: string | null
          id_cotizacion_seleccionada?: string | null
          id_servicio?: string | null
          id_sku_servicio?: string | null
          id_trabajador?: string | null
          id_usuario?: string
          instantanea_precio?: string | null
          latitud?: number | null
          longitud?: number | null
          metadatos_servicio?: string | null
          modalidad_cobro?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "jobs_serviceId_fkey"
            columns: ["id_servicio"]
            isOneToOne: false
            referencedRelation: "servicios"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "jobs_userId_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "jobs_workerId_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      admin_actualizar_estado_disputa: {
        Args: { p_estado: string; p_id: string; p_resolucion?: string }
        Returns: undefined
      }
      admin_metricas_resumen: { Args: never; Returns: Json }
      asignar_trabajador_trabajo: {
        Args: { p_trabajador_id: string; p_trabajo_id: string }
        Returns: {
          actualizado_en: string
          creado_en: string
          descripcion: string | null
          direccion: string
          estado: string
          estado_pago: string | null
          fecha_programada: string | null
          horas_bloque: number | null
          id: string
          id_comuna: string | null
          id_cotizacion_seleccionada: string | null
          id_servicio: string | null
          id_sku_servicio: string | null
          id_trabajador: string | null
          id_usuario: string
          instantanea_precio: string | null
          latitud: number | null
          longitud: number | null
          metadatos_servicio: string | null
          modalidad_cobro: string | null
        }
        SetofOptions: {
          from: "*"
          to: "trabajos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      es_parte_trabajo: { Args: { p_trabajo_id: string }; Returns: boolean }
      es_rol_trabajador: { Args: { p_usuario_id: string }; Returns: boolean }
      is_admin: { Args: never; Returns: boolean }
      rechazar_trabajo_pendiente: {
        Args: { p_metadatos?: string; p_trabajo_id: string }
        Returns: {
          actualizado_en: string
          creado_en: string
          descripcion: string | null
          direccion: string
          estado: string
          estado_pago: string | null
          fecha_programada: string | null
          horas_bloque: number | null
          id: string
          id_comuna: string | null
          id_cotizacion_seleccionada: string | null
          id_servicio: string | null
          id_sku_servicio: string | null
          id_trabajador: string | null
          id_usuario: string
          instantanea_precio: string | null
          latitud: number | null
          longitud: number | null
          metadatos_servicio: string | null
          modalidad_cobro: string | null
        }
        SetofOptions: {
          from: "*"
          to: "trabajos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      simular_transicion_pago: {
        Args: { p_nuevo_estado: string; p_pago_id: string }
        Returns: {
          actualizado_en: string
          autorizado_en: string | null
          creado_en: string
          estado: string
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          reembolsado_en: string | null
          tipo_pago: string
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      transicionar_trabajo: {
        Args: { p_nuevo_estado: string; p_pin?: string; p_trabajo_id: string }
        Returns: {
          actualizado_en: string
          creado_en: string
          descripcion: string | null
          direccion: string
          estado: string
          estado_pago: string | null
          fecha_programada: string | null
          horas_bloque: number | null
          id: string
          id_comuna: string | null
          id_cotizacion_seleccionada: string | null
          id_servicio: string | null
          id_sku_servicio: string | null
          id_trabajador: string | null
          id_usuario: string
          instantanea_precio: string | null
          latitud: number | null
          longitud: number | null
          metadatos_servicio: string | null
          modalidad_cobro: string | null
        }
        SetofOptions: {
          from: "*"
          to: "trabajos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends (DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never) = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends (DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never) = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends (PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never) = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const
