-- Unifica la categoría de jardinería. Había dos códigos: 'jardinera' (servicio
-- gardening_basic y dos profesionales) y 'jardineria' (web, seed de la demo y
-- svc-demo-jardineria). Se deja solo 'jardineria'. Ya aplicado en la base de la demo.
update public.servicios set categoria = 'jardineria' where categoria = 'jardinera';
update public.trabajadores set categoria_servicio = 'jardineria' where categoria_servicio = 'jardinera';
update public.trabajador_servicios set categoria_servicio = 'jardineria' where categoria_servicio = 'jardinera';
