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
      acuerdos_trabajo: {
        Row: {
          acepta_cliente: boolean | null
          acepta_trabajador: boolean | null
          aplicado_en: string | null
          creado_en: string
          estado: string
          id: string
          id_trabajo: string
          propuesto_por: string
          tipo: string
        }
        Insert: {
          acepta_cliente?: boolean | null
          acepta_trabajador?: boolean | null
          aplicado_en?: string | null
          creado_en?: string
          estado?: string
          id: string
          id_trabajo: string
          propuesto_por: string
          tipo: string
        }
        Update: {
          acepta_cliente?: boolean | null
          acepta_trabajador?: boolean | null
          aplicado_en?: string | null
          creado_en?: string
          estado?: string
          id?: string
          id_trabajo?: string
          propuesto_por?: string
          tipo?: string
        }
        Relationships: [
          {
            foreignKeyName: "acuerdos_trabajo_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "acuerdos_trabajo_propuesto_por_fkey"
            columns: ["propuesto_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      auditoria_consola: {
        Row: {
          accion: string
          antes: Json | null
          creado_en: string
          despues: Json | null
          entidad: string
          id: string
          id_actor: string | null
          id_entidad: string | null
          ip: string | null
          motivo: string | null
          rol_actor: string | null
          user_agent: string | null
        }
        Insert: {
          accion: string
          antes?: Json | null
          creado_en?: string
          despues?: Json | null
          entidad: string
          id?: string
          id_actor?: string | null
          id_entidad?: string | null
          ip?: string | null
          motivo?: string | null
          rol_actor?: string | null
          user_agent?: string | null
        }
        Update: {
          accion?: string
          antes?: Json | null
          creado_en?: string
          despues?: Json | null
          entidad?: string
          id?: string
          id_actor?: string | null
          id_entidad?: string | null
          ip?: string | null
          motivo?: string | null
          rol_actor?: string | null
          user_agent?: string | null
        }
        Relationships: []
      }
      app_config: {
        Row: {
          actualizado_en: string
          clave: string
          valor: string
        }
        Insert: {
          actualizado_en?: string
          clave: string
          valor: string
        }
        Update: {
          actualizado_en?: string
          clave?: string
          valor?: string
        }
        Relationships: []
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
        Relationships: [
          {
            foreignKeyName: "banderas_funcionalidad_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      bloqueos_pin_inicio: {
        Row: {
          actualizado_en: string
          bloqueado_hasta: string | null
          fallos: number
          id_trabajo: string
          pin_ok_hasta: string | null
          pin_ok_usuario: string | null
        }
        Insert: {
          actualizado_en?: string
          bloqueado_hasta?: string | null
          fallos?: number
          id_trabajo: string
          pin_ok_hasta?: string | null
          pin_ok_usuario?: string | null
        }
        Update: {
          actualizado_en?: string
          bloqueado_hasta?: string | null
          fallos?: number
          id_trabajo?: string
          pin_ok_hasta?: string | null
          pin_ok_usuario?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "bloqueos_pin_inicio_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
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
        Relationships: [
          {
            foreignKeyName: "bloqueos_usuario_id_bloqueado_fkey"
            columns: ["id_bloqueado"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "bloqueos_usuario_id_bloqueador_fkey"
            columns: ["id_bloqueador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      calificaciones: {
        Row: {
          comentario: string | null
          creado_en: string
          direccion: string
          estado_revision: string
          id: string
          id_calificado: string
          id_trabajo: string
          id_usuario: string | null
          motivo_revision: string | null
          peso_confianza: number
          puntaje: number
        }
        Insert: {
          comentario?: string | null
          creado_en: string
          direccion?: string
          estado_revision?: string
          id: string
          id_calificado: string
          id_trabajo: string
          id_usuario?: string | null
          motivo_revision?: string | null
          peso_confianza?: number
          puntaje: number
        }
        Update: {
          comentario?: string | null
          creado_en?: string
          direccion?: string
          estado_revision?: string
          id?: string
          id_calificado?: string
          id_trabajo?: string
          id_usuario?: string | null
          motivo_revision?: string | null
          peso_confianza?: number
          puntaje?: number
        }
        Relationships: [
          {
            foreignKeyName: "calificaciones_id_calificado_fkey"
            columns: ["id_calificado"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calificaciones_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ratings_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      calificaciones_cliente: {
        Row: {
          comentario: string | null
          creado_en: string
          id: string
          id_cliente: string
          id_trabajador: string
          id_trabajo: string
          puntaje: number
        }
        Insert: {
          comentario?: string | null
          creado_en?: string
          id: string
          id_cliente: string
          id_trabajador: string
          id_trabajo: string
          puntaje: number
        }
        Update: {
          comentario?: string | null
          creado_en?: string
          id?: string
          id_cliente?: string
          id_trabajador?: string
          id_trabajo?: string
          puntaje?: number
        }
        Relationships: [
          {
            foreignKeyName: "calificaciones_cliente_id_cliente_fkey"
            columns: ["id_cliente"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calificaciones_cliente_id_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "calificaciones_cliente_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
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
            foreignKeyName: "cancelaciones_trabajo_cancelado_por_fkey"
            columns: ["cancelado_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "job_cancellations_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      categorias_servicio: {
        Row: {
          activa: boolean
          creado_en: string
          id: string
          nombre: string
        }
        Insert: {
          activa?: boolean
          creado_en?: string
          id: string
          nombre: string
        }
        Update: {
          activa?: boolean
          creado_en?: string
          id?: string
          nombre?: string
        }
        Relationships: []
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
        Relationships: [
          {
            foreignKeyName: "codigos_restablecimiento_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      comunas: {
        Row: {
          activa: number
          id: string
          id_region: string
          latitud: number | null
          longitud: number | null
          nombre: string
        }
        Insert: {
          activa?: number
          id: string
          id_region: string
          latitud?: number | null
          longitud?: number | null
          nombre: string
        }
        Update: {
          activa?: number
          id?: string
          id_region?: string
          latitud?: number | null
          longitud?: number | null
          nombre?: string
        }
        Relationships: [
          {
            foreignKeyName: "comunas_id_region_fkey"
            columns: ["id_region"]
            isOneToOne: false
            referencedRelation: "regiones"
            referencedColumns: ["id"]
          },
        ]
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
      cuentas_bancarias: {
        Row: {
          actualizado_en: string
          banco: string
          id_usuario: string
          nombre_titular: string
          numero_cuenta: string
          rut_titular: string
          tipo_cuenta: string
        }
        Insert: {
          actualizado_en?: string
          banco: string
          id_usuario: string
          nombre_titular: string
          numero_cuenta: string
          rut_titular: string
          tipo_cuenta: string
        }
        Update: {
          actualizado_en?: string
          banco?: string
          id_usuario?: string
          nombre_titular?: string
          numero_cuenta?: string
          rut_titular?: string
          tipo_cuenta?: string
        }
        Relationships: [
          {
            foreignKeyName: "cuentas_bancarias_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: true
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      dispositivos_push: {
        Row: {
          actualizado_en: string
          creado_en: string
          id_usuario: string
          plataforma: string
          token: string
        }
        Insert: {
          actualizado_en?: string
          creado_en?: string
          id_usuario: string
          plataforma?: string
          token: string
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          id_usuario?: string
          plataforma?: string
          token?: string
        }
        Relationships: [
          {
            foreignKeyName: "dispositivos_push_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      disputa_mensajes: {
        Row: {
          creado_en: string
          cuerpo: string
          id: string
          id_autor: string | null
          id_disputa: string
          interna: boolean
        }
        Insert: {
          creado_en?: string
          interna?: boolean
          cuerpo: string
          id: string
          id_autor?: string | null
          id_disputa: string
        }
        Update: {
          creado_en?: string
          cuerpo?: string
          id?: string
          id_autor?: string | null
          id_disputa?: string
        }
        Relationships: [
          {
            foreignKeyName: "disputa_mensajes_id_autor_fkey"
            columns: ["id_autor"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputa_mensajes_id_disputa_fkey"
            columns: ["id_disputa"]
            isOneToOne: false
            referencedRelation: "disputas"
            referencedColumns: ["id"]
          },
        ]
      }
      disputas: {
        Row: {
          abierta_por: string
          actualizado_en: string
          creado_en: string
          decision_sugerida: string | null
          descripcion: string | null
          estado: string
          id: string
          id_trabajo: string
          motivo: string
          motivo_regla: string | null
          origen: string
          resolucion: string | null
          resuelta_en: string | null
          resuelta_por: string | null
          vence_en: string | null
        }
        Insert: {
          abierta_por: string
          actualizado_en: string
          creado_en: string
          decision_sugerida?: string | null
          descripcion?: string | null
          estado: string
          id: string
          id_trabajo: string
          motivo: string
          motivo_regla?: string | null
          origen?: string
          resolucion?: string | null
          resuelta_en?: string | null
          resuelta_por?: string | null
          vence_en?: string | null
        }
        Update: {
          abierta_por?: string
          actualizado_en?: string
          creado_en?: string
          decision_sugerida?: string | null
          descripcion?: string | null
          estado?: string
          id?: string
          id_trabajo?: string
          motivo?: string
          motivo_regla?: string | null
          origen?: string
          resolucion?: string | null
          resuelta_en?: string | null
          resuelta_por?: string | null
          vence_en?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "disputas_abierta_por_fkey"
            columns: ["abierta_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputas_resuelta_por_fkey"
            columns: ["resuelta_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "disputes_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      encuesta_testing_respuestas: {
        Row: {
          id_encuesta: string
          item: number
          valor: number
        }
        Insert: {
          id_encuesta: string
          item: number
          valor: number
        }
        Update: {
          id_encuesta?: string
          item?: number
          valor?: number
        }
        Relationships: [
          {
            foreignKeyName: "encuesta_testing_respuestas_id_encuesta_fkey"
            columns: ["id_encuesta"]
            isOneToOne: false
            referencedRelation: "encuestas_testing"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "encuesta_testing_respuestas_id_encuesta_fkey"
            columns: ["id_encuesta"]
            isOneToOne: false
            referencedRelation: "encuestas_testing_con_puntaje"
            referencedColumns: ["id"]
          },
        ]
      }
      encuestas_testing: {
        Row: {
          creado_en: string
          id: string
          id_usuario: string | null
          plataforma: string
          que_funciono: string | null
          que_mejorar: string | null
          rol: string
          satisfaccion: number
          tarea_completada: string
          version_app: string | null
        }
        Insert: {
          creado_en?: string
          id?: string
          id_usuario?: string | null
          plataforma: string
          que_funciono?: string | null
          que_mejorar?: string | null
          rol: string
          satisfaccion: number
          tarea_completada: string
          version_app?: string | null
        }
        Update: {
          creado_en?: string
          id?: string
          id_usuario?: string | null
          plataforma?: string
          que_funciono?: string | null
          que_mejorar?: string | null
          rol?: string
          satisfaccion?: number
          tarea_completada?: string
          version_app?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "encuestas_testing_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
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
        Relationships: [
          {
            foreignKeyName: "eventos_analitica_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      eventos_ranking: {
        Row: {
          creado_en: string
          factores: Json
          id: string
          id_trabajador: string
          id_trabajo: string | null
          tipo_evento: string
        }
        Insert: {
          creado_en?: string
          factores?: Json
          id: string
          id_trabajador: string
          id_trabajo?: string | null
          tipo_evento: string
        }
        Update: {
          creado_en?: string
          factores?: Json
          id?: string
          id_trabajador?: string
          id_trabajo?: string | null
          tipo_evento?: string
        }
        Relationships: [
          {
            foreignKeyName: "eventos_ranking_id_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "eventos_ranking_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      fotos_trabajo: {
        Row: {
          creado_en: string
          id: string
          id_trabajo: string
          imagen_webp: string | null
          ruta_foto: string
          tipo_medio: string
        }
        Insert: {
          creado_en: string
          id: string
          id_trabajo: string
          imagen_webp?: string | null
          ruta_foto: string
          tipo_medio?: string
        }
        Update: {
          creado_en?: string
          id?: string
          id_trabajo?: string
          imagen_webp?: string | null
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
      intentos_pin_inicio: {
        Row: {
          creado_en: string
          id: number
          id_trabajo: string
          id_usuario: string | null
          intentos_restantes: number
          resultado: string
        }
        Insert: {
          creado_en?: string
          id?: never
          id_trabajo: string
          id_usuario?: string | null
          intentos_restantes: number
          resultado: string
        }
        Update: {
          creado_en?: string
          id?: never
          id_trabajo?: string
          id_usuario?: string | null
          intentos_restantes?: number
          resultado?: string
        }
        Relationships: [
          {
            foreignKeyName: "intentos_pin_inicio_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "intentos_pin_inicio_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      liquidaciones: {
        Row: {
          creado_en: string
          estado_transferencia: string
          id: string
          id_operador: string | null
          id_pago: string
          id_trabajador: string | null
          id_trabajo: string
          liberada_por_sistema: boolean
          monto_clp: number
          notas: string | null
          proveedor: string
          referencia_transferencia: string
        }
        Insert: {
          creado_en?: string
          estado_transferencia?: string
          id?: string
          id_operador?: string | null
          id_pago: string
          id_trabajador?: string | null
          id_trabajo: string
          liberada_por_sistema?: boolean
          monto_clp: number
          notas?: string | null
          proveedor?: string
          referencia_transferencia: string
        }
        Update: {
          creado_en?: string
          estado_transferencia?: string
          id?: string
          id_operador?: string | null
          id_pago?: string
          id_trabajador?: string | null
          id_trabajo?: string
          liberada_por_sistema?: boolean
          monto_clp?: number
          notas?: string | null
          proveedor?: string
          referencia_transferencia?: string
        }
        Relationships: [
          {
            foreignKeyName: "liquidaciones_id_operador_fkey"
            columns: ["id_operador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "liquidaciones_id_pago_fkey"
            columns: ["id_pago"]
            isOneToOne: false
            referencedRelation: "pagos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "liquidaciones_id_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "liquidaciones_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
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
            foreignKeyName: "mensajes_id_destinatario_fkey"
            columns: ["id_destinatario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "mensajes_id_remitente_fkey"
            columns: ["id_remitente"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "messages_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      metodos_pago_oneclick: {
        Row: {
          actualizado_en: string
          creado_en: string
          estado: string
          id_trabajo_pendiente: string | null
          id_usuario: string
          tbk_user: string | null
          ticket_handoff: string | null
          tipo_tarjeta: string | null
          token_inscripcion: string | null
          ultimos4: string | null
          url_inscripcion: string | null
          username: string
        }
        Insert: {
          actualizado_en?: string
          creado_en?: string
          estado?: string
          id_trabajo_pendiente?: string | null
          id_usuario: string
          tbk_user?: string | null
          ticket_handoff?: string | null
          tipo_tarjeta?: string | null
          token_inscripcion?: string | null
          ultimos4?: string | null
          url_inscripcion?: string | null
          username: string
        }
        Update: {
          actualizado_en?: string
          creado_en?: string
          estado?: string
          id_trabajo_pendiente?: string | null
          id_usuario?: string
          tbk_user?: string | null
          ticket_handoff?: string | null
          tipo_tarjeta?: string | null
          token_inscripcion?: string | null
          ultimos4?: string | null
          url_inscripcion?: string | null
          username?: string
        }
        Relationships: [
          {
            foreignKeyName: "metodos_pago_oneclick_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: true
            referencedRelation: "perfiles"
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
          {
            foreignKeyName: "ordenes_cambio_id_pago_fkey"
            columns: ["id_pago"]
            isOneToOne: false
            referencedRelation: "pagos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ordenes_cambio_id_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      pagos: {
        Row: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        Insert: {
          actualizado_en: string
          alta_consumido_en?: string | null
          alta_jti?: string | null
          alta_nonce_hash?: string | null
          ambiente?: string | null
          autorizado_en?: string | null
          buy_order?: string | null
          cobro_reclamado_en?: string | null
          creado_en: string
          estado: string
          handoff_consumido_en?: string | null
          id: string
          id_orden_cambio?: string | null
          id_trabajo: string
          id_transaccion?: string | null
          liberado_en?: string | null
          metodo_pago?: string | null
          moneda?: string
          monto: number
          orden_detalle_oneclick?: string | null
          origen_retorno?: string | null
          reembolsado_en?: string | null
          reembolso_solicitado_en?: string | null
          tipo_pago?: string
          token_tbk?: string | null
          url_tbk?: string | null
        }
        Update: {
          actualizado_en?: string
          alta_consumido_en?: string | null
          alta_jti?: string | null
          alta_nonce_hash?: string | null
          ambiente?: string | null
          autorizado_en?: string | null
          buy_order?: string | null
          cobro_reclamado_en?: string | null
          creado_en?: string
          estado?: string
          handoff_consumido_en?: string | null
          id?: string
          id_orden_cambio?: string | null
          id_trabajo?: string
          id_transaccion?: string | null
          liberado_en?: string | null
          metodo_pago?: string | null
          moneda?: string
          monto?: number
          orden_detalle_oneclick?: string | null
          origen_retorno?: string | null
          reembolsado_en?: string | null
          reembolso_solicitado_en?: string | null
          tipo_pago?: string
          token_tbk?: string | null
          url_tbk?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pagos_id_orden_cambio_fkey"
            columns: ["id_orden_cambio"]
            isOneToOne: false
            referencedRelation: "ordenes_cambio"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "payments_jobId_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      paises: {
        Row: {
          id: string
          iso2: string
          nombre: string
        }
        Insert: {
          id: string
          iso2: string
          nombre: string
        }
        Update: {
          id?: string
          iso2?: string
          nombre?: string
        }
        Relationships: []
      }
      perfiles: {
        Row: {
          calificaciones_cliente: number
          correo: string | null
          creado_en: string
          estado_cuenta: string
          id: string
          nombre: string
          reputacion_cliente: number | null
          rol: string
          ruta_foto_perfil: string | null
        }
        Insert: {
          calificaciones_cliente?: number
          correo?: string | null
          creado_en?: string
          estado_cuenta?: string
          id?: string
          nombre?: string
          reputacion_cliente?: number | null
          rol?: string
          ruta_foto_perfil?: string | null
        }
        Update: {
          calificaciones_cliente?: number
          correo?: string | null
          creado_en?: string
          estado_cuenta?: string
          id?: string
          nombre?: string
          reputacion_cliente?: number | null
          rol?: string
          ruta_foto_perfil?: string | null
        }
        Relationships: []
      }
      pines_inicio_trabajo: {
        Row: {
          creado_en: string
          id_trabajo: string
          pin: string
        }
        Insert: {
          creado_en?: string
          id_trabajo: string
          pin: string
        }
        Update: {
          creado_en?: string
          id_trabajo?: string
          pin?: string
        }
        Relationships: [
          {
            foreignKeyName: "pines_inicio_trabajo_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      portafolio_trabajador: {
        Row: {
          creado_en: string
          descripcion: string | null
          id: string
          id_trabajador: string
          ruta_foto: string
          tipo_medio: string
        }
        Insert: {
          creado_en: string
          descripcion?: string | null
          id: string
          id_trabajador: string
          ruta_foto: string
          tipo_medio?: string
        }
        Update: {
          creado_en?: string
          descripcion?: string | null
          id?: string
          id_trabajador?: string
          ruta_foto?: string
          tipo_medio?: string
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
      propuesta_cotizacion_items: {
        Row: {
          concepto: string
          id_propuesta: string
          linea: number
          monto: number
        }
        Insert: {
          concepto: string
          id_propuesta: string
          linea: number
          monto: number
        }
        Update: {
          concepto?: string
          id_propuesta?: string
          linea?: number
          monto?: number
        }
        Relationships: [
          {
            foreignKeyName: "propuesta_cotizacion_items_id_propuesta_fkey"
            columns: ["id_propuesta"]
            isOneToOne: false
            referencedRelation: "propuestas_cotizacion"
            referencedColumns: ["id"]
          },
        ]
      }
      propuestas_cotizacion: {
        Row: {
          creado_en: string
          descripcion: string
          estado: string
          horas_estimadas: number | null
          id: string
          id_trabajador: string
          id_trabajo: string
          monto_total_clp: number
          validez_hasta: string | null
        }
        Insert: {
          creado_en: string
          descripcion: string
          estado: string
          horas_estimadas?: number | null
          id: string
          id_trabajador: string
          id_trabajo: string
          monto_total_clp: number
          validez_hasta?: string | null
        }
        Update: {
          creado_en?: string
          descripcion?: string
          estado?: string
          horas_estimadas?: number | null
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
      ranking_aprendizaje: {
        Row: {
          creado_en: string
          id: string
          metricas: Json | null
          motivo: string
          pesos_antes: Json
          pesos_despues: Json
        }
        Insert: {
          creado_en?: string
          id: string
          metricas?: Json | null
          motivo: string
          pesos_antes: Json
          pesos_despues: Json
        }
        Update: {
          creado_en?: string
          id?: string
          metricas?: Json | null
          motivo?: string
          pesos_antes?: Json
          pesos_despues?: Json
        }
        Relationships: []
      }
      ranking_config: {
        Row: {
          actualizado_en: string
          aprendizaje_activo: number
          id: string
          n_bayes: number
          peso_calificacion: number
          peso_completados: number
          peso_confianza: number
          peso_impulso: number
          peso_recencia: number
          peso_rechazos: number
          peso_verificacion: number
          pesos_senal: Json
          prior_bayes: number
          tasa_aprendizaje: number
          umbral_auto_excluir: number
          umbral_revision: number
        }
        Insert: {
          actualizado_en?: string
          aprendizaje_activo?: number
          id?: string
          n_bayes?: number
          peso_calificacion?: number
          peso_completados?: number
          peso_confianza?: number
          peso_impulso?: number
          peso_recencia?: number
          peso_rechazos?: number
          peso_verificacion?: number
          pesos_senal?: Json
          prior_bayes?: number
          tasa_aprendizaje?: number
          umbral_auto_excluir?: number
          umbral_revision?: number
        }
        Update: {
          actualizado_en?: string
          aprendizaje_activo?: number
          id?: string
          n_bayes?: number
          peso_calificacion?: number
          peso_completados?: number
          peso_confianza?: number
          peso_impulso?: number
          peso_recencia?: number
          peso_rechazos?: number
          peso_verificacion?: number
          pesos_senal?: Json
          prior_bayes?: number
          tasa_aprendizaje?: number
          umbral_auto_excluir?: number
          umbral_revision?: number
        }
        Relationships: []
      }
      regiones: {
        Row: {
          codigo_oficial: string | null
          id: string
          id_pais: string
          nombre: string
        }
        Insert: {
          codigo_oficial?: string | null
          id: string
          id_pais: string
          nombre: string
        }
        Update: {
          codigo_oficial?: string | null
          id?: string
          id_pais?: string
          nombre?: string
        }
        Relationships: [
          {
            foreignKeyName: "regiones_id_pais_fkey"
            columns: ["id_pais"]
            isOneToOne: false
            referencedRelation: "paises"
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
        Relationships: [
          {
            foreignKeyName: "reportes_id_reportante_fkey"
            columns: ["id_reportante"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reportes_id_usuario_reportado_fkey"
            columns: ["id_usuario_reportado"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
      reprogramaciones_trabajo: {
        Row: {
          creado_en: string
          estado: string
          fecha_anterior: string
          fecha_propuesta: string
          id: string
          id_trabajo: string
          motivo: string | null
          propuesta_por: string
          respondida_en: string | null
          respondida_por: string | null
          rol_proponente: string
        }
        Insert: {
          creado_en?: string
          estado?: string
          fecha_anterior: string
          fecha_propuesta: string
          id?: string
          id_trabajo: string
          motivo?: string | null
          propuesta_por: string
          respondida_en?: string | null
          respondida_por?: string | null
          rol_proponente: string
        }
        Update: {
          creado_en?: string
          estado?: string
          fecha_anterior?: string
          fecha_propuesta?: string
          id?: string
          id_trabajo?: string
          motivo?: string | null
          propuesta_por?: string
          respondida_en?: string | null
          respondida_por?: string | null
          rol_proponente?: string
        }
        Relationships: [
          {
            foreignKeyName: "reprogramaciones_propuesta_por_fkey"
            columns: ["propuesta_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reprogramaciones_respondida_por_fkey"
            columns: ["respondida_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "reprogramaciones_trabajo_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      senales_resena: {
        Row: {
          creado_en: string
          detalle: string | null
          estado: string
          id: string
          id_calificacion: string
          puntaje: number
          resuelto_en: string | null
          resuelto_por: string | null
          tipo_senal: string
        }
        Insert: {
          creado_en?: string
          detalle?: string | null
          estado?: string
          id: string
          id_calificacion: string
          puntaje: number
          resuelto_en?: string | null
          resuelto_por?: string | null
          tipo_senal: string
        }
        Update: {
          creado_en?: string
          detalle?: string | null
          estado?: string
          id?: string
          id_calificacion?: string
          puntaje?: number
          resuelto_en?: string | null
          resuelto_por?: string | null
          tipo_senal?: string
        }
        Relationships: [
          {
            foreignKeyName: "senales_resena_id_calificacion_fkey"
            columns: ["id_calificacion"]
            isOneToOne: false
            referencedRelation: "calificaciones"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "senales_resena_resuelto_por_fkey"
            columns: ["resuelto_por"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
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
        Relationships: [
          {
            foreignKeyName: "servicios_categoria_fkey"
            columns: ["categoria"]
            isOneToOne: false
            referencedRelation: "categorias_servicio"
            referencedColumns: ["id"]
          },
        ]
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
        Relationships: [
          {
            foreignKeyName: "tickets_soporte_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: false
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
        ]
      }
      trabajador_horarios: {
        Row: {
          activo: boolean
          actualizado_en: string
          creado_en: string | null
          dia_semana: number
          hora_fin: string
          hora_inicio: string
          id: string
          id_usuario: string
        }
        Insert: {
          activo?: boolean
          actualizado_en?: string
          creado_en?: string | null
          dia_semana: number
          hora_fin: string
          hora_inicio: string
          id?: string
          id_usuario: string
        }
        Update: {
          activo?: boolean
          actualizado_en?: string
          creado_en?: string | null
          dia_semana?: number
          hora_fin?: string
          hora_inicio?: string
          id?: string
          id_usuario?: string
        }
        Relationships: [
          {
            foreignKeyName: "trabajador_horarios_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      trabajador_horas_publicadas: {
        Row: {
          creado_en: string
          dia_semana: number
          hora: string
          id_usuario: string
        }
        Insert: {
          creado_en?: string
          dia_semana: number
          hora: string
          id_usuario: string
        }
        Update: {
          creado_en?: string
          dia_semana?: number
          hora?: string
          id_usuario?: string
        }
        Relationships: [
          {
            foreignKeyName: "trabajador_horas_publicadas_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      trabajador_precios: {
        Row: {
          codigo: string
          id_usuario: string
          monto_clp: number
        }
        Insert: {
          codigo: string
          id_usuario: string
          monto_clp: number
        }
        Update: {
          codigo?: string
          id_usuario?: string
          monto_clp?: number
        }
        Relationships: [
          {
            foreignKeyName: "trabajador_precios_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
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
            foreignKeyName: "trabajador_servicios_categoria_fkey"
            columns: ["categoria_servicio"]
            isOneToOne: false
            referencedRelation: "categorias_servicio"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trabajador_servicios_id_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      trabajador_servicios_extra: {
        Row: {
          id: string
          id_usuario: string
          monto_clp: number
          subtitulo: string
          titulo: string
          unidad: string
        }
        Insert: {
          id: string
          id_usuario: string
          monto_clp: number
          subtitulo?: string
          titulo: string
          unidad?: string
        }
        Update: {
          id?: string
          id_usuario?: string
          monto_clp?: number
          subtitulo?: string
          titulo?: string
          unidad?: string
        }
        Relationships: [
          {
            foreignKeyName: "trabajador_servicios_extra_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      trabajadores: {
        Row: {
          calificacion: number
          conteo_rechazos: number
          descripcion: string | null
          disponible: number
          es_elite: boolean | null
          estado_verificacion: string
          id_comuna: string | null
          id_usuario: string
          latitud_base: number | null
          longitud_base: number | null
          nota_verificacion: string | null
          origen_base: string | null
          pausa_por_trabajo: boolean
          precios_configurados: number
          prioridad_manual: number
          profesion: string
          radio_servicio_km: number
          radio_urbano_km: number
          ranking_actualizado_en: string | null
          score_desglose: Json
          score_listado: number
          tarifa_fuera_radio_clp: number
          tarifa_visita: number
          trabajos_completados: number
          usa_horario: boolean
          zona_trabajo: string | null
        }
        Insert: {
          calificacion?: number
          conteo_rechazos?: number
          descripcion?: string | null
          disponible?: number
          es_elite?: boolean | null
          estado_verificacion?: string
          id_comuna?: string | null
          id_usuario: string
          latitud_base?: number | null
          longitud_base?: number | null
          nota_verificacion?: string | null
          origen_base?: string | null
          pausa_por_trabajo?: boolean
          precios_configurados?: number
          prioridad_manual?: number
          profesion?: string
          radio_servicio_km?: number
          radio_urbano_km?: number
          ranking_actualizado_en?: string | null
          score_desglose?: Json
          score_listado?: number
          tarifa_fuera_radio_clp?: number
          tarifa_visita?: number
          trabajos_completados?: number
          usa_horario?: boolean
          zona_trabajo?: string | null
        }
        Update: {
          calificacion?: number
          conteo_rechazos?: number
          descripcion?: string | null
          disponible?: number
          es_elite?: boolean | null
          estado_verificacion?: string
          id_comuna?: string | null
          id_usuario?: string
          latitud_base?: number | null
          longitud_base?: number | null
          nota_verificacion?: string | null
          origen_base?: string | null
          pausa_por_trabajo?: boolean
          precios_configurados?: number
          prioridad_manual?: number
          profesion?: string
          radio_servicio_km?: number
          radio_urbano_km?: number
          ranking_actualizado_en?: string | null
          score_desglose?: Json
          score_listado?: number
          tarifa_fuera_radio_clp?: number
          tarifa_visita?: number
          trabajos_completados?: number
          usa_horario?: boolean
          zona_trabajo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "trabajadores_id_comuna_fkey"
            columns: ["id_comuna"]
            isOneToOne: false
            referencedRelation: "comunas"
            referencedColumns: ["id"]
          },
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
          {
            foreignKeyName: "trabajos_id_comuna_fkey"
            columns: ["id_comuna"]
            isOneToOne: false
            referencedRelation: "comunas"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "trabajos_id_cotizacion_seleccionada_fkey"
            columns: ["id_cotizacion_seleccionada"]
            isOneToOne: false
            referencedRelation: "propuestas_cotizacion"
            referencedColumns: ["id"]
          },
        ]
      }
      ubicacion_en_vivo: {
        Row: {
          actualizado_en: string
          id_trabajador: string
          id_trabajo: string
          latitud: number
          longitud: number
          precision_metros: number | null
        }
        Insert: {
          actualizado_en?: string
          id_trabajador: string
          id_trabajo: string
          latitud: number
          longitud: number
          precision_metros?: number | null
        }
        Update: {
          actualizado_en?: string
          id_trabajador?: string
          id_trabajo?: string
          latitud?: number
          longitud?: number
          precision_metros?: number | null
        }
        Relationships: [
          {
            foreignKeyName: "ubicacion_en_vivo_id_trabajo_fkey"
            columns: ["id_trabajo"]
            isOneToOne: true
            referencedRelation: "trabajos"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "ubicacion_en_vivo_trabajador_fkey"
            columns: ["id_trabajador"]
            isOneToOne: false
            referencedRelation: "trabajadores"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      verificacion_eventos: {
        Row: {
          creado_en: string
          estado: string
          id: string
          id_actor: string | null
          id_usuario: string
          nota: string | null
        }
        Insert: {
          creado_en?: string
          estado: string
          id?: string
          id_actor?: string | null
          id_usuario: string
          nota?: string | null
        }
        Update: {
          creado_en?: string
          estado?: string
          id?: string
          id_actor?: string | null
          id_usuario?: string
          nota?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "verificacion_eventos_id_actor_fkey"
            columns: ["id_actor"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "verificacion_eventos_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      cobros_profesional: {
        Row: {
          bruto_clp: number | null
          comision_clp: number | null
          creado_en: string | null
          estado_pago: string | null
          estado_transferencia: string | null
          id_pago: string | null
          id_trabajador: string | null
          id_trabajo: string | null
          liberado_en: string | null
          liquidado_en: string | null
          neto_clp: number | null
          referencia_transferencia: string | null
          tipo_pago: string | null
        }
        Relationships: []
      }
      encuestas_testing_con_puntaje: {
        Row: {
          creado_en: string | null
          id: string | null
          id_usuario: string | null
          plataforma: string | null
          que_funciono: string | null
          que_mejorar: string | null
          rol: string | null
          satisfaccion: number | null
          sus_puntaje: number | null
          tarea_completada: string | null
          version_app: string | null
        }
        Insert: {
          creado_en?: string | null
          id?: string | null
          id_usuario?: string | null
          plataforma?: string | null
          que_funciono?: string | null
          que_mejorar?: string | null
          rol?: string | null
          satisfaccion?: number | null
          sus_puntaje?: never
          tarea_completada?: string | null
          version_app?: string | null
        }
        Update: {
          creado_en?: string | null
          id?: string | null
          id_usuario?: string | null
          plataforma?: string | null
          que_funciono?: string | null
          que_mejorar?: string | null
          rol?: string | null
          satisfaccion?: number | null
          sus_puntaje?: never
          tarea_completada?: string | null
          version_app?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "encuestas_testing_id_usuario_fkey"
            columns: ["id_usuario"]
            isOneToOne: false
            referencedRelation: "perfiles"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Functions: {
      _asegurar_ventanas_horario: { Args: { p_id: string }; Returns: undefined }
      _hora_santiago: { Args: { p_ts: string }; Returns: string }
      _normalizar_pesos_ranking: {
        Args: {
          p_cal: number
          p_comp: number
          p_conf: number
          p_imp: number
          p_rec: number
          p_rech: number
          p_ver: number
        }
        Returns: number[]
      }
      _notificar_reprogramacion: {
        Args: {
          p_cuerpo: string
          p_destino: string
          p_id_trabajo: string
          p_titulo: string
        }
        Returns: undefined
      }
      _ranking_cfg: {
        Args: never
        Returns: {
          actualizado_en: string
          aprendizaje_activo: number
          id: string
          n_bayes: number
          peso_calificacion: number
          peso_completados: number
          peso_confianza: number
          peso_impulso: number
          peso_recencia: number
          peso_rechazos: number
          peso_verificacion: number
          pesos_senal: Json
          prior_bayes: number
          tasa_aprendizaje: number
          umbral_auto_excluir: number
          umbral_revision: number
        }
        SetofOptions: {
          from: "*"
          to: "ranking_config"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      _registrar_evento_ranking: {
        Args: { p_tipo: string; p_trabajador: string; p_trabajo: string }
        Returns: undefined
      }
      abrir_disputa: {
        Args: {
          p_descripcion: string
          p_id: string
          p_id_trabajo: string
          p_motivo: string
        }
        Returns: undefined
      }
      acuerdo_pendiente: {
        Args: { p_id_trabajo: string }
        Returns: {
          acepta_cliente: boolean
          acepta_trabajador: boolean
          estado: string
          id: string
          tipo: string
        }[]
      }
      admin_actualizar_estado_disputa: {
        Args: { p_estado: string; p_id: string; p_resolucion?: string }
        Returns: undefined
      }
      admin_metricas_resumen: { Args: never; Returns: Json }
      aplicar_cierre_disputa: {
        Args: {
          p_decision: string
          p_disputa_id: string
          p_operador: string
          p_resolucion: string
        }
        Returns: Json
      }
      aprender_pesos_ranking: { Args: never; Returns: Json }
      aprender_pesos_ranking_admin: { Args: never; Returns: Json }
      asegurar_pin_inicio: { Args: { p_trabajo_id: string }; Returns: string }
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
      base_publica_profesional: {
        Args: { p_id: string }
        Returns: {
          latitud_base: number
          longitud_base: number
        }[]
      }
      calificar_cliente: {
        Args: { p_comentario?: string; p_puntaje: number; p_trabajo_id: string }
        Returns: number
      }
      categorias_con_disponibles: { Args: never; Returns: string[] }
      cerrar_trabajo_conforme: {
        Args: { p_trabajo_id: string }
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
      clasificar_disputa: {
        Args: { p_motivo: string; p_trabajo_id: string }
        Returns: {
          decision: string
          estado: string
          regla: string
          vence: string
        }[]
      }
      comentar_disputa: {
        Args: { p_comentario: string; p_id: string }
        Returns: undefined
      }
      confirmar_trabajo_tras_captura: {
        Args: { p_id_pago: string }
        Returns: string
      }
      consola_buscar: {
        Args: { p_q: string }
        Returns: {
          detalle: string
          id: string
          ruta: string
          tipo: string
          titulo: string
        }[]
      }
      consola_cambiar_rol: {
        Args: { p_id: string; p_motivo: string; p_rol: string }
        Returns: undefined
      }
      consola_cerrar_sesiones: {
        Args: { p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_cron_salud: { Args: never; Returns: Json }
      consola_disputas_resueltas: {
        Args: never
        Returns: {
          creado_en: string
          descripcion: string
          estado: string
          id: string
          id_trabajo: string
          monto_retenido: number
          motivo: string
          nombre_cliente: string
          nombre_profesional: string
          resolucion: string
          resuelta_en: string
        }[]
      }
      consola_editar_bandera: {
        Args: { p_habilitada: number; p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_editar_config: {
        Args: { p_clave: string; p_motivo: string; p_valor: string }
        Returns: undefined
      }
      consola_leer_config: {
        Args: never
        Returns: {
          clave: string
          valor: string
        }[]
      }
      consola_fijar_estado_cuenta: {
        Args: { p_estado: string; p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_listar_equipo: {
        Args: never
        Returns: {
          correo: string
          creado_en: string
          estado_cuenta: string
          id: string
          invitacion_pendiente: boolean
          nombre: string
          rol: string
        }[]
      }
      consola_marcar_error: {
        Args: { p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_moderar_resena: {
        Args: { p_estado: string; p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_nota_interna: {
        Args: { p_id: string; p_nota: string }
        Returns: undefined
      }
      consola_registrar_vista_sensible: {
        Args: { p_entidad: string; p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_revocar_invitacion: {
        Args: { p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_resolver_reporte: {
        Args: { p_estado: string; p_id: string; p_motivo: string }
        Returns: undefined
      }
      consola_resumen_periodo: {
        Args: { p_desde: string; p_hasta: string }
        Returns: Json
      }
      consola_disputas_abiertas: {
        Args: never
        Returns: {
          creado_en: string
          decision_sugerida: string
          descripcion: string
          estado: string
          id: string
          id_trabajo: string
          monto_retenido: number
          motivo: string
          motivo_regla: string
          nombre_cliente: string
          nombre_profesional: string
          vence_en: string
        }[]
      }
      crear_intencion_pago: {
        Args: { p_buy_order?: string; p_id_trabajo: string; p_monto: number }
        Returns: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      crear_intencion_pago_orden_cambio: {
        Args: {
          p_buy_order?: string
          p_id_orden_cambio: string
          p_id_trabajo: string
          p_monto: number
        }
        Returns: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      crear_intencion_pago_servicio: {
        Args: { p_id_trabajo: string; p_id_usuario: string; p_monto: number }
        Returns: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      disputa_esta_activa: { Args: { p_estado: string }; Returns: boolean }
      enviar_encuesta_testing: {
        Args: {
          p_plataforma: string
          p_que_funciono?: string
          p_que_mejorar?: string
          p_rol: string
          p_satisfaccion: number
          p_sus: number[]
          p_tarea_completada: string
          p_version_app?: string
        }
        Returns: string
      }
      enviar_verificacion_profesional: {
        Args: { p_nota: string }
        Returns: undefined
      }
      es_marca_tiempo_iso: { Args: { p_valor: string }; Returns: boolean }
      es_parte_trabajo: { Args: { p_trabajo_id: string }; Returns: boolean }
      es_rol_trabajador: { Args: { p_usuario_id: string }; Returns: boolean }
      evaluar_resena: { Args: { p_id: string }; Returns: number }
      evidencia_disputa: {
        Args: { p_id_disputa: string }
        Returns: {
          id: string
          imagen_base64: string
        }[]
      }
      expirar_pagos_abandonados: { Args: never; Returns: number }
      fichas_sensibles_admin: {
        Args: never
        Returns: {
          id_usuario: string
          latitud_base: number
          longitud_base: number
          nota_verificacion: string
        }[]
      }
      fijar_prioridad_trabajador: {
        Args: { p_id: string; p_prioridad: number }
        Returns: undefined
      }
      fijar_verificacion_profesional: {
        Args: { p_estado: string; p_id_usuario: string; p_nota?: string }
        Returns: undefined
      }
      guardar_config_ranking: { Args: { p_cfg: Json }; Returns: Json }
      guardar_horarios_propios: { Args: { p_horarios: Json }; Returns: Json }
      horarios_disponibles_propios: { Args: never; Returns: Json }
      horarios_libres_profesional: {
        Args: { p_dias?: number; p_id_trabajador: string }
        Returns: {
          inicio: string
        }[]
      }
      intentar_pin_inicio: {
        Args: { p_pin: string; p_trabajo_id: string }
        Returns: Json
      }
      is_admin: { Args: never; Returns: boolean }
      km_entre_puntos: {
        Args: { p_lat1: number; p_lat2: number; p_lng1: number; p_lng2: number }
        Returns: number
      }
      liberar_escrow: {
        Args: { p_id_pago: string }
        Returns: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      liberar_escrow_manual: {
        Args: {
          p_id_operador: string
          p_id_pago: string
          p_notas?: string
          p_proveedor?: string
          p_referencia: string
        }
        Returns: Json
      }
      liberar_trabajo_sistema: {
        Args: { p_nota: string; p_trabajo_id: string }
        Returns: undefined
      }
      limpiar_invitados_sin_pago: { Args: never; Returns: number }
      listar_cuentas_demo_acceso: {
        Args: never
        Returns: {
          categoria_servicio: string
          correo: string
          id: string
          nombre: string
          profesion: string
          rol: string
        }[]
      }
      listar_profesionales_catalogo: {
        Args: {
          p_categoria?: string
          p_cursor_calificacion?: number
          p_cursor_id?: string
          p_latitud?: number
          p_limit?: number
          p_longitud?: number
          p_offset?: number
          p_zona?: string
        }
        Returns: {
          calificacion: number
          categoria_servicio: string
          descripcion: string
          distancia_km: number
          es_elite: boolean
          id_usuario: string
          latitud_base: number
          longitud_base: number
          nombre: string
          origen_base: string
          prioridad_manual: number
          profesion: string
          radio_servicio_km: number
          radio_urbano_km: number
          ruta_foto_perfil: string
          score_listado: number
          tarifa_fuera_radio_clp: number
          tarifa_visita: number
          trabajos_completados: number
          zona_trabajo: string
        }[]
      }
      listar_senales_resena: {
        Args: { p_estado?: string; p_limit?: number }
        Returns: {
          comentario: string
          creado_en: string
          detalle: string
          estado: string
          estado_revision: string
          id: string
          id_calificacion: string
          id_trabajador: string
          id_trabajo: string
          nombre_cliente: string
          nombre_trabajador: string
          peso_confianza: number
          puntaje: number
          puntaje_resena: number
          tipo_senal: string
        }[]
      }
      listar_trabajos_marketplace: {
        Args: { p_limite?: number }
        Returns: {
          actualizado_en: string
          creado_en: string
          descripcion: string
          estado: string
          id: string
          id_servicio: string
          metadatos_servicio: string
          modalidad_cobro: string
        }[]
      }
      marcar_orden_cambio_pagada: {
        Args: { p_id_orden_cambio: string; p_id_pago: string }
        Returns: {
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
        SetofOptions: {
          from: "*"
          to: "ordenes_cambio"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      marcar_pago_liberado: {
        Args: {
          p_id_operador: string
          p_id_pago: string
          p_notas: string
          p_referencia: string
        }
        Returns: undefined
      }
      marcar_reembolso_automatico: {
        Args: { p_id_pago: string; p_modo: string }
        Returns: string
      }
      metadatos_sin_pin: { Args: { p_raw: string }; Returns: string }
      mi_ficha_propia: {
        Args: never
        Returns: {
          estado_verificacion: string
          latitud_base: number
          longitud_base: number
          nota_verificacion: string
          origen_base: string
          radio_servicio_km: number
        }[]
      }
      minuto_utc: { Args: { p_valor: string }; Returns: string }
      monto_esperado_trabajo: {
        Args: { p_job: Database["public"]["Tables"]["trabajos"]["Row"] }
        Returns: number
      }
      normalizar_bloques_horario: { Args: { p_horarios: Json }; Returns: Json }
      obtener_config_ranking: { Args: never; Returns: Json }
      obtener_pin_inicio: { Args: { p_trabajo_id: string }; Returns: string }
      obtener_trabajo_sin_direccion: { Args: { p_id: string }; Returns: Json }
      perfil_contacto_si_trabajo_activo: {
        Args: { p_perfil_id: string }
        Returns: {
          correo: string
          id: string
          nombre: string
        }[]
      }
      perfiles_publicos_por_ids: {
        Args: { p_ids: string[] }
        Returns: {
          id: string
          nombre: string
          rol: string
          ruta_foto_perfil: string
        }[]
      }
      profesional_tiene_trabajo_activo: {
        Args: { p_id_trabajador: string }
        Returns: boolean
      }
      profesionales_ocupados: { Args: { p_ids: string[] }; Returns: string[] }
      proponer_acuerdo: {
        Args: { p_id: string; p_id_trabajo: string; p_tipo: string }
        Returns: Json
      }
      proponer_reprogramacion: {
        Args: { p_fecha: string; p_motivo?: string; p_trabajo_id: string }
        Returns: {
          creado_en: string
          estado: string
          fecha_anterior: string
          fecha_propuesta: string
          id: string
          id_trabajo: string
          motivo: string | null
          propuesta_por: string
          respondida_en: string | null
          respondida_por: string | null
          rol_proponente: string
        }
        SetofOptions: {
          from: "*"
          to: "reprogramaciones_trabajo"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      publicar_ubicacion_trabajo: {
        Args: {
          p_lat: number
          p_lng: number
          p_precision?: number
          p_trabajo_id: string
        }
        Returns: undefined
      }
      quitar_dispositivo_push: { Args: { p_token: string }; Returns: undefined }
      recargo_traslado_clp: {
        Args: {
          p_lat_trabajador: number
          p_lat_trabajo: number
          p_lng_trabajador: number
          p_lng_trabajo: number
          p_radio_km: number
        }
        Returns: number
      }
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
      reclamar_cobro_oneclick: {
        Args: { p_buy_order: string; p_id_pago: string; p_monto: number }
        Returns: string
      }
      recomputar_agregados_profesional: {
        Args: { p_id: string }
        Returns: undefined
      }
      recomputar_agregados_profesionales: { Args: never; Returns: number }
      reconcile_secret_valido: { Args: { p_secret: string }; Returns: boolean }
      reembolsar_escrow: {
        Args: { p_id_pago: string }
        Returns: {
          actualizado_en: string
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      refrescar_ranking_todos: { Args: never; Returns: number }
      refrescar_ranking_todos_admin: { Args: never; Returns: number }
      refrescar_ranking_trabajador: {
        Args: { p_id: string }
        Returns: undefined
      }
      registrar_dispositivo_push: {
        Args: { p_plataforma?: string; p_token: string }
        Returns: undefined
      }
      registrar_transferencia_profesional: {
        Args: { p_id_pago: string; p_notas?: string; p_referencia: string }
        Returns: Json
      }
      resolver_senal_resena: {
        Args: { p_estado: string; p_id: string }
        Returns: undefined
      }
      resolver_soporte_automatico: { Args: never; Returns: Json }
      responder_acuerdo: {
        Args: { p_acepta: boolean; p_id: string }
        Returns: Json
      }
      responder_reprogramacion: {
        Args: { p_acepta: boolean; p_id: string }
        Returns: {
          creado_en: string
          estado: string
          fecha_anterior: string
          fecha_propuesta: string
          id: string
          id_trabajo: string
          motivo: string | null
          propuesta_por: string
          respondida_en: string | null
          respondida_por: string | null
          rol_proponente: string
        }
        SetofOptions: {
          from: "*"
          to: "reprogramaciones_trabajo"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      resumen_calificacion_clientes: {
        Args: { p_ids: string[] }
        Returns: {
          cantidad: number
          id_usuario: string
          promedio: number
        }[]
      }
      retirar_reprogramacion: {
        Args: { p_id: string }
        Returns: {
          creado_en: string
          estado: string
          fecha_anterior: string
          fecha_propuesta: string
          id: string
          id_trabajo: string
          motivo: string | null
          propuesta_por: string
          respondida_en: string | null
          respondida_por: string | null
          rol_proponente: string
        }
        SetofOptions: {
          from: "*"
          to: "reprogramaciones_trabajo"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      rol_consola: { Args: never; Returns: string }
      seleccionar_cotizacion: {
        Args: { p_id_cotizacion: string }
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
          alta_consumido_en: string | null
          alta_jti: string | null
          alta_nonce_hash: string | null
          ambiente: string | null
          autorizado_en: string | null
          buy_order: string | null
          cobro_reclamado_en: string | null
          creado_en: string
          estado: string
          handoff_consumido_en: string | null
          id: string
          id_orden_cambio: string | null
          id_trabajo: string
          id_transaccion: string | null
          liberado_en: string | null
          metodo_pago: string | null
          moneda: string
          monto: number
          orden_detalle_oneclick: string | null
          origen_retorno: string | null
          reembolsado_en: string | null
          reembolso_solicitado_en: string | null
          tipo_pago: string
          token_tbk: string | null
          url_tbk: string | null
        }
        SetofOptions: {
          from: "*"
          to: "pagos"
          isOneToOne: true
          isSetofReturn: false
        }
      }
      sincronizar_estado_pago_trabajo: {
        Args: { p_trabajo_id: string }
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
      slug_geo: { Args: { p_texto: string }; Returns: string }
      soporte_comentar_disputa: {
        Args: { p_comentario: string; p_id: string }
        Returns: undefined
      }
      soporte_numero: {
        Args: { p_clave: string; p_default: number }
        Returns: number
      }
      stats_profesional: {
        Args: { p_id: string }
        Returns: {
          calificacion: number
          es_elite: boolean
          id_usuario: string
          n_calificaciones: number
          trabajos_completados: number
        }[]
      }
      stats_profesionales: {
        Args: { p_ids: string[] }
        Returns: {
          calificacion: number
          es_elite: boolean
          id_usuario: string
          n_calificaciones: number
          trabajos_completados: number
        }[]
      }
      sus_puntaje: { Args: { p_id_encuesta: string }; Returns: number }
      texto_a_timestamptz: { Args: { p_valor: string }; Returns: string }
      texto_tiene_contacto: { Args: { p_texto: string }; Returns: boolean }
      trabajador_reservable: {
        Args: { p_trabajador: string }
        Returns: boolean
      }
      trabajo_admite_disputa: { Args: { p_estado: string }; Returns: boolean }
      trabajo_tiene_evidencia: {
        Args: { p_trabajo_id: string }
        Returns: boolean
      }
      transicion_trabajo_permitida: {
        Args: { p_desde: string; p_hacia: string; p_modalidad?: string }
        Returns: boolean
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
      transiciones_trabajo_posibles: {
        Args: { p_desde: string; p_modalidad?: string }
        Returns: string[]
      }
      ver_reputacion_cliente: {
        Args: { p_cliente: string }
        Returns: {
          calificaciones: number
          disputas: number
          reputacion: number
        }[]
      }
      vincular_trabajador_cotizacion: {
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
      vincular_trabajador_solicitud: {
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
