-- ========== MySQL (punto_venta_db) ==========

USE punto_venta_db;

-- 1. clientes
CREATE TABLE IF NOT EXISTS clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    puntos_mix INT DEFAULT 0
);

-- 2. artistas
CREATE TABLE IF NOT EXISTS artistas (
    id_artista INT AUTO_INCREMENT PRIMARY KEY,
    nombre_banda VARCHAR(150) NOT NULL,
    genero_principal VARCHAR(60) NOT NULL,
    pais_origen VARCHAR(80) NOT NULL
);

-- 3. productos_musicales
CREATE TABLE IF NOT EXISTS productos_musicales (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    titulo VARCHAR(200) NOT NULL,
    id_artista INT NOT NULL,
    formato ENUM('CD', 'Vinilo', 'K-Pop', 'Merch') NOT NULL,
    precio_unitario DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_artista) REFERENCES artistas(id_artista)
);

-- 4. ventas_tienda
CREATE TABLE IF NOT EXISTS ventas_tienda (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_venta DECIMAL(12, 2) DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

-- 5. detalle_ventas
CREATE TABLE IF NOT EXISTS detalle_ventas (
    id_detalle INT AUTO_INCREMENT PRIMARY KEY,
    id_venta INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    subtotal DECIMAL(12, 2) DEFAULT 0,
    FOREIGN KEY (id_venta) REFERENCES ventas_tienda(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos_musicales(id_producto)
);

-- ========== TRIGGERS ==========

-- TRG_Precio_Valido: Before insert producto, abort if precio <= 0
DELIMITER //
CREATE TRIGGER TRG_Precio_Valido
BEFORE INSERT ON productos_musicales
FOR EACH ROW
BEGIN
    IF NEW.precio_unitario <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio unitario debe ser mayor a 0';
    END IF;
END//
DELIMITER ;

-- TRG_Puntos_Lealtad: After insert venta, sum 10% of total to cliente puntos_mix
DELIMITER //
CREATE TRIGGER TRG_Puntos_Lealtad
AFTER INSERT ON ventas_tienda
FOR EACH ROW
BEGIN
    UPDATE clientes
    SET puntos_mix = puntos_mix + FLOOR(NEW.total_venta * 0.10)
    WHERE id_cliente = NEW.id_cliente;
END//
DELIMITER ;

-- TRG_Mayusculas_Banda: Before insert artista, convert nombre_banda to UPPER
DELIMITER //
CREATE TRIGGER TRG_Mayusculas_Banda
BEFORE INSERT ON artistas
FOR EACH ROW
BEGIN
    SET NEW.nombre_banda = UPPER(NEW.nombre_banda);
END//
DELIMITER ;

-- TRG_Impide_Baja_Artista: Prevent DELETE of artista if has products
DELIMITER //
CREATE TRIGGER TRG_Impide_Baja_Artista
BEFORE DELETE ON artistas
FOR EACH ROW
BEGIN
    DECLARE product_count INT;
    SELECT COUNT(*) INTO product_count FROM productos_musicales WHERE id_artista = OLD.id_artista;
    IF product_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No se puede eliminar el artista porque tiene productos asociados';
    END IF;
END//
DELIMITER ;

-- TRG_Calcula_Subtotal: Before insert detalle_ventas, calculate subtotal = cantidad * precio_unitario
DELIMITER //
CREATE TRIGGER TRG_Calcula_Subtotal
BEFORE INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    DECLARE precio DECIMAL(10, 2);
    SELECT precio_unitario INTO precio FROM productos_musicales WHERE id_producto = NEW.id_producto;
    SET NEW.subtotal = NEW.cantidad * precio;
END//
DELIMITER ;

-- TRG_Actualiza_Total_Venta: After insert detalle, add subtotal to ventas_tienda.total_venta
DELIMITER //
CREATE TRIGGER TRG_Actualiza_Total_Venta
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    UPDATE ventas_tienda
    SET total_venta = total_venta + NEW.subtotal
    WHERE id_venta = NEW.id_venta;
END//
DELIMITER ;

-- TRG_Valida_Formato: Prevent insert producto if formato not valid
DELIMITER //
CREATE TRIGGER TRG_Valida_Formato
BEFORE INSERT ON productos_musicales
FOR EACH ROW
BEGIN
    IF NEW.formato NOT IN ('CD', 'Vinilo', 'K-Pop', 'Merch') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Formato no valido. Use: CD, Vinilo, K-Pop o Merch';
    END IF;
END//
DELIMITER ;

-- ========== CONSULTAS ==========

-- 1. Mostrar todos los productos musicales.
SELECT * FROM productos_musicales;

-- 2. Mostrar todos los artistas registrados.
SELECT * FROM artistas;

-- 3. Mostrar todos los clientes de la tienda.
SELECT * FROM clientes;

-- 4. Mostrar ventas realizadas el dia de hoy.
SELECT * FROM ventas_tienda WHERE DATE(fecha_venta) = CURDATE();

-- 5. Contar cuantos productos se venden en formato 'Vinilo'.
SELECT COUNT(*) AS total_vinilos FROM productos_musicales WHERE formato = 'Vinilo';

-- 6. Mostrar productos cuyo precio unitario sea mayor a $800.
SELECT * FROM productos_musicales WHERE precio_unitario > 800;

-- 7. (Pedido por el profe en el pdf) Muestra el CD mas barato usando LIMIT
SELECT * FROM productos_musicales WHERE formato = 'CD' ORDER BY precio_unitario ASC LIMIT 1;

-- 8. Mostrar clientes que tengan mas de 500 puntos_mix.
SELECT * FROM clientes WHERE puntos_mix > 500;

-- 9. (Pedido por el profe en el pdf) Cuenta cuantos artistas hay por cada genero usando GROUP BY
SELECT genero_principal, COUNT(*) AS total_artistas FROM artistas GROUP BY genero_principal;

-- 10. Mostrar ventas cuyo total supere los $3,000.
SELECT * FROM ventas_tienda WHERE total_venta > 3000;

-- 11. Mostrar artistas cuyo pais de origen sea 'Corea del Sur'.
SELECT * FROM artistas WHERE pais_origen = 'Corea del Sur';

-- 12. Mostrar productos del artista con ID 5.
SELECT * FROM productos_musicales WHERE id_artista = 5;

-- 13. (Pedido por el profe en el pdf) Muestra productos filtrando por varios formatos con IN
SELECT * FROM productos_musicales WHERE formato IN ('CD', 'Vinilo', 'K-Pop');

-- 14. (Pedido por el profe en el pdf) Muestra ventas de diciembre usando funciones de fecha
SELECT * FROM ventas_tienda WHERE MONTH(fecha_venta) = 12;

-- 15. (Pedido por el profe en el pdf) Muestra los primeros 15 albumes en orden alfabetico con LIMIT
SELECT * FROM productos_musicales ORDER BY titulo ASC LIMIT 15;

-- 16. Contar cuantas compras ha realizado cada cliente.
SELECT id_cliente, COUNT(*) AS total_compras FROM ventas_tienda GROUP BY id_cliente;

-- 17. (Pedido por el profe en el pdf) Muestra artistas cuyo nombre empiece con 'The' usando LIKE
SELECT * FROM artistas WHERE nombre_banda LIKE 'The%';

-- 18. Mostrar productos que cuesten exactamente $499.
SELECT * FROM productos_musicales WHERE precio_unitario = 499;

-- 19. (Pedido por el profe en el pdf) Muestra los generos sin repetir usando DISTINCT
SELECT DISTINCT genero_principal FROM artistas;

-- 20. Mostrar detalle de ventas donde se llevaron mas de 2 copias del mismo disco.
SELECT * FROM detalle_ventas WHERE cantidad > 2;

-- 21. (Pedido por el profe en el pdf) Cuenta los productos de Metallica usando JOIN entre tablas
SELECT COUNT(*) AS total_productos
FROM productos_musicales p
JOIN artistas a ON p.id_artista = a.id_artista
WHERE a.nombre_banda = 'METALLICA';

-- 22. (Pedido por el profe en el pdf) Muestra generos con mas de 10 artistas usando HAVING
SELECT genero_principal, COUNT(*) AS total_artistas
FROM artistas
GROUP BY genero_principal
HAVING total_artistas > 10;

-- 23. (Pedido por el profe en el pdf) Muestra la longitud del nombre de cada cliente con LENGTH
SELECT id_cliente, nombre_completo, LENGTH(nombre_completo) AS longitud_nombre FROM clientes;

-- 24. (Pedido por el profe en el pdf) Muestra los titulos en mayusculas con UPPER
SELECT id_producto, UPPER(titulo) AS titulo_mayusculas FROM productos_musicales;

-- 25. Mostrar los 10 clientes mas recientes (por ID).
SELECT * FROM clientes ORDER BY id_cliente DESC LIMIT 10;

-- 26. (Pedido por el profe en el pdf) Muestra ventas ordenadas por fecha y total usando ORDER BY
SELECT * FROM ventas_tienda ORDER BY fecha_venta DESC, total_venta DESC;

-- 27. (Pedido por el profe en el pdf) Muestra clientes que han comprado usando subconsulta con IN
SELECT * FROM clientes WHERE id_cliente IN (SELECT id_cliente FROM ventas_tienda);

-- 28. (Pedido por el profe en el pdf) Muestra clientes que nunca han comprado usando subconsulta con NOT IN
SELECT * FROM clientes WHERE id_cliente NOT IN (SELECT id_cliente FROM ventas_tienda);

-- 29. (Pedido por el profe en el pdf) Muestra productos de Rock Clasico usando subconsulta con artista
SELECT * FROM productos_musicales
WHERE id_artista IN (SELECT id_artista FROM artistas WHERE genero_principal = 'Rock Clasico');

-- 30. (Pedido por el profe en el pdf) Cuenta las ventas agrupadas por mes con GROUP BY
SELECT YEAR(fecha_venta) AS anio, MONTH(fecha_venta) AS mes, COUNT(*) AS total_ventas
FROM ventas_tienda
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;

-- 31. Mostrar productos ordenados por precio de mayor a menor.
SELECT * FROM productos_musicales ORDER BY precio_unitario DESC;

-- 32. (Pedido por el profe en el pdf) Extrae el año de la fecha de venta con YEAR()
SELECT id_venta, fecha_venta, YEAR(fecha_venta) AS anio FROM ventas_tienda;

-- 33. (Pedido por el profe en el pdf) Concatena el nombre de la banda y su pais con CONCAT
SELECT CONCAT(nombre_banda, ' (', pais_origen, ')') AS banda_pais FROM artistas;

-- 34. Mostrar el detalle de venta con el subtotal mas alto.
SELECT * FROM detalle_ventas ORDER BY subtotal DESC LIMIT 1;

-- 35. (Pedido por el profe en el pdf) Muestra clientes que gastaron mas del promedio con subconsulta y HAVING
SELECT c.id_cliente, c.nombre_completo, SUM(v.total_venta) AS gasto_total
FROM clientes c
JOIN ventas_tienda v ON c.id_cliente = v.id_cliente
GROUP BY c.id_cliente, c.nombre_completo
HAVING gasto_total > (SELECT AVG(total_venta) FROM ventas_tienda);

-- 36. Contar cuantos discos distintos se llevaron en la venta con ID 10.
SELECT COUNT(DISTINCT id_producto) AS discos_distintos FROM detalle_ventas WHERE id_venta = 10;

-- 37. (Pedido por el profe en el pdf) Muestra artistas sin discos usando subconsulta con NOT IN
SELECT id_artista FROM artistas
WHERE id_artista NOT IN (SELECT id_artista FROM productos_musicales);

-- 38. Mostrar el vinilo mas caro registrado.
SELECT * FROM productos_musicales WHERE formato = 'Vinilo' ORDER BY precio_unitario DESC LIMIT 1;

-- 39. (Pedido por el profe en el pdf) Suma los ingresos del mes actual con funciones de fecha
SELECT SUM(total_venta) AS ingresos_mes_actual
FROM ventas_tienda
WHERE MONTH(fecha_venta) = MONTH(CURDATE()) AND YEAR(fecha_venta) = YEAR(CURDATE());

-- 40. (Pedido por el profe en el pdf) Muestra albumes con 'Live' o 'Greatest Hits' usando LIKE
SELECT * FROM productos_musicales
WHERE titulo LIKE '%Live%' OR titulo LIKE '%Greatest Hits%';

-- ========== JOINS ==========

-- 1. Mostrar el titulo del producto y el nombre de la banda/artista (INNER JOIN).
SELECT p.titulo, a.nombre_banda
FROM productos_musicales p
INNER JOIN artistas a ON p.id_artista = a.id_artista;

-- 2. Mostrar todos los artistas y cuantos albumes tienen registrados (LEFT JOIN).
SELECT a.id_artista, a.nombre_banda, COUNT(p.id_producto) AS total_albumes
FROM artistas a
LEFT JOIN productos_musicales p ON a.id_artista = p.id_artista
GROUP BY a.id_artista, a.nombre_banda;

-- 3. Mostrar el ID de la venta, la cantidad y el titulo del disco vendido en el detalle.
SELECT dv.id_venta, dv.cantidad, p.titulo
FROM detalle_ventas dv
INNER JOIN productos_musicales p ON dv.id_producto = p.id_producto;

-- 4. Triple JOIN: Mostrar nombre del cliente, fecha de la venta y titulo del album que compro.
SELECT c.nombre_completo, vt.fecha_venta, p.titulo
FROM clientes c
INNER JOIN ventas_tienda vt ON c.id_cliente = vt.id_cliente
INNER JOIN detalle_ventas dv ON vt.id_venta = dv.id_venta
INNER JOIN productos_musicales p ON dv.id_producto = p.id_producto;

-- 5. Mostrar artistas que NO tienen productos asignados (LEFT JOIN).
SELECT a.*
FROM artistas a
LEFT JOIN productos_musicales p ON a.id_artista = p.id_artista
WHERE p.id_producto IS NULL;

-- 6. Mostrar el nombre del cliente y la suma del total de sus compras fisicas.
SELECT c.nombre_completo, SUM(vt.total_venta) AS total_compras
FROM clientes c
LEFT JOIN ventas_tienda vt ON c.id_cliente = vt.id_cliente
GROUP BY c.id_cliente, c.nombre_completo;

-- 7. Mostrar productos que NUNCA se han vendido en mostrador (LEFT JOIN).
SELECT p.*
FROM productos_musicales p
LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
WHERE dv.id_detalle IS NULL;

-- 8. Mostrar ventas cuyo cliente tiene correo de 'hotmail.com'.
SELECT vt.*
FROM ventas_tienda vt
INNER JOIN clientes c ON vt.id_cliente = c.id_cliente
WHERE c.email LIKE '%@hotmail.com';

-- 9. Cruzar artistas y productos usando RIGHT JOIN para ver si hay discos sin artista asignado.
SELECT a.nombre_banda, p.titulo
FROM artistas a
RIGHT JOIN productos_musicales p ON a.id_artista = p.id_artista;

-- 10. Triple JOIN: Genero principal del artista, titulo del disco y la cantidad vendida en detalles.
SELECT a.genero_principal, p.titulo, dv.cantidad
FROM artistas a
INNER JOIN productos_musicales p ON a.id_artista = p.id_artista
INNER JOIN detalle_ventas dv ON p.id_producto = dv.id_producto;
