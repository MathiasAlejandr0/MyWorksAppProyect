# Asociaciones actor–caso de cada paquete (tomadas de las figuras vigentes del informe
# y de MyWorksAppProyect/docs/casos_de_uso.md, sección 1 y 2).
UC = {
 '01': 'Registrarse', '02': 'Iniciar sesión', '03': 'Recuperar contraseña',
 '04': 'Ejercer derechos sobre los datos (exportar / eliminar cuenta)',
 '05': 'Buscar profesionales con mapa y filtros', '06': 'Ver perfil público, reseñas y horas libres',
 '07': 'Solicitar servicio y reservar hora', '08': 'Pagar con Webpay en garantía (escrow)',
 '09': 'Comprar como invitado', '10': 'Definir contraseña tras pagar como invitado',
 '11': 'Aceptar o rechazar un pedido', '12': 'Avisar «voy en camino» y compartir ubicación',
 '13': 'Seguir el pedido en vivo', '14': 'Iniciar el trabajo con PIN',
 '15': 'Solicitar y aprobar o rechazar un cobro adicional', '16': 'Subir evidencia y finalizar el trabajo',
 '17': 'Recibir conforme y liberar el pago', '18': 'Calificar al profesional', '19': 'Calificar al cliente',
 '20': 'Cancelar una solicitud con reembolso', '21': 'Abrir disputa y proponer un acuerdo',
 '22': 'Resolver una disputa', '23': 'Chatear sobre un trabajo', '24': 'Recibir y gestionar notificaciones',
 '25': 'Completar perfil y solicitar verificación', '26': 'Configurar tarifas, horario y disponibilidad',
 '27': 'Consultar cobros y registrar cuenta bancaria', '28': 'Acceder a la consola con segundo factor',
 '29': 'Verificar profesionales (rechazo con nota)', '30': 'Supervisar métricas, pagos y liquidar al profesional',
 '31': 'Invitar colaborador interno', '32': 'Ejecutar procesos automáticos de pagos y soporte',
 '33': 'Reagendar la visita', '34': 'Atender la cola de soporte con mínimo privilegio',
}
ACT = {'V': 'Visitante', 'CI': 'Cliente\ninvitado', 'CR': 'Cliente\nregistrado', 'P': 'Profesional',
       'A': 'Administrador', 'C': 'Colaborador\ninterno', 'S': 'Sistema\n(planificador)',
       'SA': 'Supabase\nAuth / correo', 'T': 'Transbank\nWebpay', 'TS': 'Cloudflare\nTurnstile'}
PAQ = [
 dict(n=1, titulo='Paquete 1: Acceso y cuenta', sub='CU-01 a CU-04 y CU-10', ucs=['01','02','03','04','10'],
      assoc={'V':['01'], 'CR':['02','03','04'], 'P':['02','03','04'], 'CI':['10'], 'SA':['01','03'], 'TS':['01']},
      rel=[], gen=[]),
 dict(n=2, titulo='Paquete 2: Búsqueda, reserva y pago', sub='CU-05 a CU-09 y CU-33 (CU-10 extiende CU-09, ver paquete 1)',
      ucs=['05','06','07','08','09','33'],
      assoc={'V':['05','06'], 'CI':['09'], 'CR':['07','08','33'], 'P':['33'], 'T':['08','09'], 'TS':['09']},
      rel=[('07','08','«include»'), ('09','08','«include»')], gen=[('CI','V'), ('CR','V')]),
 dict(n=3, titulo='Paquete 3: Ejecución del servicio', sub='CU-11 a CU-16', ucs=['11','12','13','14','15','16'],
      assoc={'P':['11','12','14','15','16'], 'CR':['13','14','15'], 'T':['15']}, rel=[], gen=[]),
 dict(n=4, titulo='Paquete 4: Cierre, reputación y excepciones', sub='CU-17 a CU-22', ucs=['17','18','19','20','21','22'],
      assoc={'CR':['17','18','20','21'], 'P':['19','21'], 'A':['22'], 'S':['17','22']},
      rel=[('18','17','«extend»'), ('21','17','«extend»'), ('22','21','«extend»')], gen=[]),
 dict(n=5, titulo='Paquete 5: Comunicación y gestión del profesional', sub='CU-23 a CU-27', ucs=['23','24','25','26','27'],
      assoc={'CR':['23','24'], 'P':['23','24','25','26','27'], 'A':['25']}, rel=[], gen=[]),
 dict(n=6, titulo='Paquete 6: Administración y sistema', sub='CU-28 a CU-32 y CU-34 (consola de escritorio y backend)',
      ucs=['28','29','30','31','32','34'],
      assoc={'A':['28','29','30','31'], 'C':['28','31','34'], 'S':['32']}, rel=[], gen=[]),
]
CTX = {'V':[1,2], 'CI':[1,2], 'CR':[1,2,3,4,5], 'P':[1,2,3,4,5], 'S':[4,6], 'SA':[1], 'T':[2,3],
       'TS':[1,2], 'A':[4,5,6], 'C':[6]}
