-- ========== PostgreSQL (ecommerce_auditoria_db) ==========

-- 1. membresias_mix
CREATE TABLE IF NOT EXISTS membresias_mix (
    id_membresia SERIAL PRIMARY KEY,
    id_cliente_ref INT NOT NULL,
    nivel VARCHAR(20) CHECK (nivel IN ('Oro', 'Platino')),
    fecha_suscripcion DATE DEFAULT CURRENT_DATE,
    activa BOOLEAN DEFAULT TRUE
);

-- 2. ventas_online
CREATE TABLE IF NOT EXISTS ventas_online (
    id_pedido_web SERIAL PRIMARY KEY,
    id_cliente_ref INT NOT NULL,
    direccion_envio TEXT NOT NULL,
    fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_pagado DECIMAL(12, 2) NOT NULL,
    estado_envio VARCHAR(30) DEFAULT 'Pendiente'
);

-- 3. pagos_online
CREATE TABLE IF NOT EXISTS pagos_online (
    id_pago SERIAL PRIMARY KEY,
    id_pedido_web INT NOT NULL,
    metodo_pago VARCHAR(50),
    pasarela_aprobacion VARCHAR(100),
    fecha_cobro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_pedido_web) REFERENCES ventas_online(id_pedido_web)
);

-- 4. gastos_operativos
CREATE TABLE IF NOT EXISTS gastos_operativos (
    id_gasto SERIAL PRIMARY KEY,
    id_sucursal_ref INT NOT NULL,
    concepto VARCHAR(150) NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    fecha_gasto DATE DEFAULT CURRENT_DATE
);

-- 5. log_auditoria
CREATE TABLE IF NOT EXISTS log_auditoria (
    id_log SERIAL PRIMARY KEY,
    usuario VARCHAR(100) NOT NULL,
    modulo VARCHAR(50) NOT NULL,
    accion VARCHAR(50) NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    detalles JSONB
);

-- ========== TRIGGERS ==========

-- TRG_Pagos_Inmutables: Block UPDATE/DELETE on pagos_online
CREATE OR REPLACE FUNCTION fn_pagos_inmutables()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Los pagos ya cobrados no se pueden modificar ni eliminar';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Pagos_Inmutables
    BEFORE UPDATE OR DELETE ON pagos_online
    FOR EACH ROW
    EXECUTE FUNCTION fn_pagos_inmutables();

-- TRG_Valida_JSON_Auditoria: Validate JSON has "usuario_sistema" key
CREATE OR REPLACE FUNCTION fn_valida_json_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT (NEW.detalles ? 'usuario_sistema') THEN
        RAISE EXCEPTION 'El JSON debe contener la llave "usuario_sistema"';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Valida_JSON_Auditoria
    BEFORE INSERT ON log_auditoria
    FOR EACH ROW
    EXECUTE FUNCTION fn_valida_json_auditoria();

-- TRG_Nivel_Membresia: Force nivel to 'Oro' by default if NULL
CREATE OR REPLACE FUNCTION fn_nivel_membresia()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.nivel IS NULL THEN
        NEW.nivel := 'Oro';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Nivel_Membresia
    BEFORE INSERT ON membresias_mix
    FOR EACH ROW
    EXECUTE FUNCTION fn_nivel_membresia();

-- TRG_Aviso_Gasto_Grande: Notice if gasto > 100000
CREATE OR REPLACE FUNCTION fn_aviso_gasto_grande()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.monto > 100000 THEN
        RAISE NOTICE 'Aprobacion de Corporativo Requerida para gasto de $%', NEW.monto;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Aviso_Gasto_Grande
    BEFORE INSERT ON gastos_operativos
    FOR EACH ROW
    EXECUTE FUNCTION fn_aviso_gasto_grande();

-- TRG_Monto_Web_Negativo: Prevent negative total_pagado
CREATE OR REPLACE FUNCTION fn_monto_web_negativo()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.total_pagado < 0 THEN
        RAISE EXCEPTION 'El total pagado no puede ser negativo';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Monto_Web_Negativo
    BEFORE INSERT ON ventas_online
    FOR EACH ROW
    EXECUTE FUNCTION fn_monto_web_negativo();

-- TRG_Auditoria_Intocable: Block DELETE on log_auditoria
CREATE OR REPLACE FUNCTION fn_auditoria_intocable()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Los registros de auditoria de MixStore son inmutables por ley de proteccion de datos';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER TRG_Auditoria_Intocable
    BEFORE DELETE ON log_auditoria
    FOR EACH ROW
    EXECUTE FUNCTION fn_auditoria_intocable();

-- ========== CONSULTAS ==========

-- 81. Mostrar todos los pedidos web (ventas_online).
SELECT * FROM ventas_online;

-- 82. Mostrar todos los pagos online.
SELECT * FROM pagos_online;

-- 83. Mostrar todas las membresias Mix.
SELECT * FROM membresias_mix;

-- 84. Mostrar todos los gastos operativos de sucursales.
SELECT * FROM gastos_operativos;

-- 85. (Pedido por el profe en el pdf) Suma todo el dinero de ventas online con SUM
SELECT SUM(total_pagado) AS ingresos_totales_web FROM ventas_online;

-- 86. Calcular el gasto promedio operativo de las tiendas.
SELECT AVG(monto) AS gasto_promedio FROM gastos_operativos;

-- 87. Mostrar la venta online mas cara registrada.
SELECT * FROM ventas_online ORDER BY total_pagado DESC LIMIT 1;

-- 88. Contar cuantos registros hay en el log de auditoria.
SELECT COUNT(*) AS total_logs FROM log_auditoria;

-- 89. (Pedido por el profe en el pdf) Cuenta pedidos por metodo de pago usando GROUP BY
SELECT metodo_pago, COUNT(*) AS total
FROM pagos_online
GROUP BY metodo_pago;

-- 90. (Pedido por el profe en el pdf) Suma gastos por concepto con GROUP BY
SELECT concepto, SUM(monto) AS total_gastos
FROM gastos_operativos
GROUP BY concepto
ORDER BY total_gastos DESC;

-- 91. Mostrar logs donde la accion sea 'DELETE'.
SELECT * FROM log_auditoria WHERE accion = 'DELETE';

-- 92. (Pedido por el profe en el pdf) Extrae el valor 'ip_cliente' del JSON con el operador ->>
SELECT id_log, detalles->>'ip_cliente' AS ip_cliente FROM log_auditoria;

-- 93. Mostrar los pedidos web generados el dia de hoy.
SELECT * FROM ventas_online WHERE DATE(fecha_pedido) = CURRENT_DATE;

-- 94. Mostrar membresias con nivel 'Platino' que esten activas.
SELECT * FROM membresias_mix WHERE nivel = 'Platino' AND activa = TRUE;

-- 95. Mostrar ventas online con estado de envio 'En Ruta' o 'Entregado'.
SELECT * FROM ventas_online WHERE estado_envio IN ('En Ruta', 'Entregado');

-- 96. Mostrar las distintas pasarelas de aprobacion registradas.
SELECT DISTINCT pasarela_aprobacion FROM pagos_online;

-- 97. Mostrar los 5 gastos operativos mas altos.
SELECT * FROM gastos_operativos ORDER BY monto DESC LIMIT 5;

-- 98. (Pedido por el profe en el pdf) Cuenta ventas por dia con GROUP BY
SELECT DATE(fecha_pedido) AS dia, COUNT(*) AS total_ventas
FROM ventas_online
GROUP BY DATE(fecha_pedido)
ORDER BY dia;

-- 99. Mostrar gastos cuyo monto este entre $5,000 y $20,000.
SELECT * FROM gastos_operativos WHERE monto BETWEEN 5000 AND 20000;

-- 100. (Pedido por el profe en el pdf) Muestra clientes que gastaron mas de $5000 usando HAVING
SELECT id_cliente_ref, SUM(total_pagado) AS gasto_total
FROM ventas_online
GROUP BY id_cliente_ref
HAVING SUM(total_pagado) > 5000;

-- 101. Mostrar logs donde el modulo sea 'E-Commerce'.
SELECT * FROM log_auditoria WHERE modulo = 'E-Commerce';

-- 102. (Pedido por el profe en el pdf) Muestra pagos agrupados por pasarela con GROUP BY
SELECT pasarela_aprobacion, COUNT(*) AS total_pagos
FROM pagos_online
GROUP BY pasarela_aprobacion;

-- 103. Mostrar las direcciones de envio en MAYUSCULAS.
SELECT id_pedido_web, UPPER(direccion_envio) AS direccion_mayusculas FROM ventas_online;

-- 104. Mostrar pagos online ordenados por fecha de cobro de mas reciente a mas antigua.
SELECT * FROM pagos_online ORDER BY fecha_cobro DESC;

-- 105. (Pedido por el profe en el pdf) Muestra el total mas $99 de envio con operacion aritmetica
SELECT id_pedido_web, total_pagado, total_pagado + 99 AS total_con_envio FROM ventas_online;

-- 106. Mostrar membresias que estan inactivas (activa = false).
SELECT * FROM membresias_mix WHERE activa = FALSE;

-- 107. Mostrar pagos online que pasaron por la pasarela 'Stripe' o 'MercadoPago'.
SELECT * FROM pagos_online WHERE pasarela_aprobacion IN ('Stripe', 'MercadoPago');

-- 108. (Pedido por el profe en el pdf) Cuenta logs agrupados por modulo con GROUP BY
SELECT modulo, COUNT(*) AS total_logs FROM log_auditoria GROUP BY modulo;

-- 109. (Pedido por el profe en el pdf) Muestra el pedido del dia del gasto mas fuerte con subconsulta
SELECT * FROM ventas_online
WHERE DATE(fecha_pedido) = (
    SELECT DATE(fecha_gasto) FROM gastos_operativos ORDER BY monto DESC LIMIT 1
);

-- 110. (Pedido por el profe en el pdf) Muestra membresias de clientes sobre el promedio con subconsulta
SELECT * FROM membresias_mix
WHERE id_cliente_ref IN (
    SELECT id_cliente_ref
    FROM ventas_online
    GROUP BY id_cliente_ref
    HAVING SUM(total_pagado) > (SELECT AVG(total_pagado) FROM ventas_online)
);

-- 111. (Pedido por el profe en el pdf) Muestra la longitud del campo JSON con LENGTH
SELECT id_log, LENGTH(detalles::TEXT) AS longitud_json FROM log_auditoria;

-- 112. Mostrar el gasto operativo mas bajo en el historial.
SELECT * FROM gastos_operativos ORDER BY monto ASC LIMIT 1;

-- 113. Mostrar pedidos web cuyo total supere el promedio general de ventas online.
SELECT * FROM ventas_online
WHERE total_pagado > (SELECT AVG(total_pagado) FROM ventas_online);

-- 114. Mostrar los 10 logs de auditoria mas recientes ordenados por fecha.
SELECT * FROM log_auditoria ORDER BY fecha DESC LIMIT 10;

-- 115. (Pedido por el profe en el pdf) Suma ventas por estado de envio con GROUP BY
SELECT estado_envio, SUM(total_pagado) AS total_ingresos
FROM ventas_online
GROUP BY estado_envio;

-- 116. Mostrar el ID del pedido web con el cobro mas alto.
SELECT id_pedido_web, total_pagado FROM ventas_online ORDER BY total_pagado DESC LIMIT 1;

-- 117. Contar cuantos clientes distintos (referencias) han comprado en linea.
SELECT COUNT(DISTINCT id_cliente_ref) AS clientes_distintos FROM ventas_online;

-- 118. (Pedido por el profe en el pdf) Muestra logs del mes actual usando EXTRACT
SELECT * FROM log_auditoria
WHERE EXTRACT(MONTH FROM fecha) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM fecha) = EXTRACT(YEAR FROM CURRENT_DATE);

-- 119. (Pedido por el profe en el pdf) Agrupa ventas por mes con EXTRACT y GROUP BY
SELECT EXTRACT(YEAR FROM fecha_pedido) AS anio,
       EXTRACT(MONTH FROM fecha_pedido) AS mes,
       SUM(total_pagado) AS total_ingresado
FROM ventas_online
GROUP BY anio, mes
ORDER BY anio, mes;

-- 120. (Pedido por el profe en el pdf) Muestra logs con error critico usando el operador ->> de JSON
SELECT * FROM log_auditoria WHERE detalles->>'error' = 'fatal';
