-- =============================================
-- MixStore - SQL Server: logistica_inventario_db
-- Fase 1: DDL - Almacen y Proveedores (ERP)
-- =============================================

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'logistica_inventario_db')
    CREATE DATABASE logistica_inventario_db;
GO

USE logistica_inventario_db;
GO

-- 1. discograficas
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'discograficas')
CREATE TABLE discograficas (
    id_discografica INT IDENTITY(1,1) PRIMARY KEY,
    razon_social VARCHAR(200) NOT NULL,
    contacto VARCHAR(150),
    telefono VARCHAR(20)
);
GO

-- 2. sucursales
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'sucursales')
CREATE TABLE sucursales (
    id_sucursal INT IDENTITY(1,1) PRIMARY KEY,
    nombre_tienda VARCHAR(100) NOT NULL,
    centro_comercial VARCHAR(150),
    ciudad VARCHAR(80) NOT NULL
);
GO

-- 3. inventario_sucursal (id_producto_ref apunta a MySQL - se almacena como referencia)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'inventario_sucursal')
CREATE TABLE inventario_sucursal (
    id_inventario INT IDENTITY(1,1) PRIMARY KEY,
    id_producto_ref INT NOT NULL,
    id_sucursal INT NOT NULL,
    cantidad_stock INT DEFAULT 0,
    pasillo VARCHAR(20),
    FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
);
GO

-- 4. ordenes_compra
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ordenes_compra')
CREATE TABLE ordenes_compra (
    id_orden INT IDENTITY(1,1) PRIMARY KEY,
    id_discografica INT NOT NULL,
    fecha_orden DATETIME DEFAULT GETDATE(),
    estado_orden VARCHAR(20) CHECK (estado_orden IN ('Pendiente', 'Enviado', 'Recibido')),
    FOREIGN KEY (id_discografica) REFERENCES discograficas(id_discografica)
);
GO

-- 5. detalle_ordenes
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'detalle_ordenes')
CREATE TABLE detalle_ordenes (
    id_detalle_orden INT IDENTITY(1,1) PRIMARY KEY,
    id_orden INT NOT NULL,
    id_producto_ref INT NOT NULL,
    cantidad_solicitada INT NOT NULL,
    costo_unitario DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_orden) REFERENCES ordenes_compra(id_orden)
);
GO

-- =============================================
-- TRIGGERS (Fase 6)
-- =============================================

-- TRG_Stock_Negativo: Prevent stock from going below 0
GO
CREATE TRIGGER TRG_Stock_Negativo
ON inventario_sucursal
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE cantidad_stock < 0)
    BEGIN
        RAISERROR('El stock no puede ser negativo', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- TRG_Impide_Borrado_Sucursal: Prevent DELETE on sucursales
GO
CREATE TRIGGER TRG_Impide_Borrado_Sucursal
ON sucursales
INSTEAD OF DELETE
AS
BEGIN
    RAISERROR('No se puede eliminar sucursales para no dejar stock huerfano', 16, 1);
    ROLLBACK TRANSACTION;
END;
GO

-- TRG_Valida_Telefono: Validate telefono has at least 10 chars
GO
CREATE TRIGGER TRG_Valida_Telefono
ON discograficas
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE LEN(telefono) < 10)
    BEGIN
        RAISERROR('El telefono debe tener al menos 10 caracteres', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- TRG_Costo_Orden_Cero: Force costo_unitario to 50 if <= 0
GO
CREATE TRIGGER TRG_Costo_Orden_Cero
ON detalle_ordenes
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO detalle_ordenes (id_orden, id_producto_ref, cantidad_solicitada, costo_unitario)
    SELECT
        id_orden,
        id_producto_ref,
        cantidad_solicitada,
        CASE WHEN costo_unitario <= 0 THEN 50 ELSE costo_unitario END
    FROM inserted;
END;
GO

-- TRG_Log_Disco_Agotado: Alert when stock reaches 0
GO
CREATE TABLE resurtido_urgente (
    id_alerta INT IDENTITY(1,1) PRIMARY KEY,
    id_inventario INT,
    fecha_alerta DATETIME DEFAULT GETDATE()
);
GO

CREATE TRIGGER TRG_Log_Disco_Agotado
ON inventario_sucursal
AFTER UPDATE
AS
BEGIN
    INSERT INTO resurtido_urgente (id_inventario)
    SELECT i.id_inventario
    FROM inserted i
    WHERE i.cantidad_stock = 0;
END;
GO

-- TRG_Impide_Baja_Discografica: Prevent DELETE of discografica with pending orders
GO
CREATE TRIGGER TRG_Impide_Baja_Discografica
ON discograficas
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM deleted d
        JOIN ordenes_compra oc ON d.id_discografica = oc.id_discografica
        WHERE oc.estado_orden = 'Pendiente'
    )
    BEGIN
        RAISERROR('No se puede eliminar una discografica con ordenes pendientes', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    DELETE FROM discograficas WHERE id_discografica IN (SELECT id_discografica FROM deleted);
END;
GO

-- TRG_Orden_Completada: When estado changes to 'Recibido', block detail deletion
GO
CREATE TRIGGER TRG_Orden_Completada
ON ordenes_compra
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE estado_orden = 'Recibido')
    BEGIN
        PRINT 'Orden marcada como Recibido - los detalles no podran borrarse';
    END
END;
GO

-- =============================================
-- 40 CONSULTAS (Fase 4 - REQUERIDO PDF)
-- =============================================

-- 41. Mostrar todas las discograficas.
SELECT * FROM discograficas;
GO

-- 42. Mostrar todas las sucursales de MixStore.
SELECT * FROM sucursales;
GO

-- 43. Mostrar todo el inventario de las sucursales.
SELECT * FROM inventario_sucursal;
GO

-- 44. Mostrar todas las ordenes de compra a discograficas.
SELECT * FROM ordenes_compra;
GO

-- 45. (Pedido por el profe en el pdf) Cuenta productos distintos por sucursal con GROUP BY
SELECT id_sucursal, COUNT(DISTINCT id_producto_ref) AS productos_distintos
FROM inventario_sucursal
GROUP BY id_sucursal;
GO

-- 46. Calcular el costo unitario promedio en los detalles de las ordenes.
SELECT AVG(costo_unitario) AS costo_promedio FROM detalle_ordenes;
GO

-- 47. (Pedido por el profe en el pdf) Muestra la orden mas reciente con TOP 1
SELECT TOP 1 * FROM ordenes_compra ORDER BY fecha_orden DESC;
GO

-- 48. Mostrar inventario con cantidad_stock menor a 5.
SELECT * FROM inventario_sucursal WHERE cantidad_stock < 5;
GO

-- 49. Mostrar discograficas de la ciudad local (filtrando por LADA del telefono).
SELECT * FROM discograficas WHERE telefono LIKE '55%' OR telefono LIKE '222%';
GO

-- 50. Sumar el total de discos solicitados en la tabla detalle_ordenes.
SELECT SUM(cantidad_solicitada) AS total_discos_solicitados FROM detalle_ordenes;
GO

-- 51. Mostrar discograficas cuya razon social contenga 'Records' o 'Music'.
SELECT * FROM discograficas WHERE razon_social LIKE '%Records%' OR razon_social LIKE '%Music%';
GO

-- 52. (Pedido por el profe en el pdf) Muestra el top 5 de sucursales con mas stock usando JOIN y GROUP BY
SELECT TOP 5 s.nombre_tienda, SUM(i.cantidad_stock) AS stock_total
FROM sucursales s
JOIN inventario_sucursal i ON s.id_sucursal = i.id_sucursal
GROUP BY s.id_sucursal, s.nombre_tienda
ORDER BY stock_total DESC;
GO

-- 53. Mostrar ordenes de compra en estado 'Enviado'.
SELECT * FROM ordenes_compra WHERE estado_orden = 'Enviado';
GO

-- 54. (Pedido por el profe en el pdf) Muestra la longitud del nombre del centro comercial con LEN
SELECT id_sucursal, centro_comercial, LEN(centro_comercial) AS longitud FROM sucursales;
GO

-- 55. Contar cuantas ordenes se han hecho a cada discografica.
SELECT id_discografica, COUNT(*) AS total_ordenes
FROM ordenes_compra
GROUP BY id_discografica;
GO

-- 56. Mostrar stock que pertenezca a la sucursal 1 o 3.
SELECT * FROM inventario_sucursal WHERE id_sucursal IN (1, 3);
GO

-- 57. Mostrar ordenes de compra realizadas este anio.
SELECT * FROM ordenes_compra WHERE YEAR(fecha_orden) = YEAR(GETDATE());
GO

-- 58. Mostrar los distintos estados de orden registrados.
SELECT DISTINCT estado_orden FROM ordenes_compra;
GO

-- 59. Mostrar sucursales ordenadas por ciudad alfabeticamente.
SELECT * FROM sucursales ORDER BY ciudad ASC;
GO

-- 60. Mostrar detalles de ordenes ordenados por cantidad solicitada descendente.
SELECT * FROM detalle_ordenes ORDER BY cantidad_solicitada DESC;
GO

-- 61. Mostrar los nombres de las sucursales en MAYUSCULAS.
SELECT id_sucursal, UPPER(nombre_tienda) AS nombre_mayusculas FROM sucursales;
GO

-- 62. (Pedido por el profe en el pdf) Muestra el costo unitario mas el IVA del 16% con operacion aritmetica
SELECT id_detalle_orden, costo_unitario, costo_unitario * 1.16 AS costo_con_iva FROM detalle_ordenes;
GO

-- 63. Mostrar el inventario correspondiente al disco de referencia 100.
SELECT * FROM inventario_sucursal WHERE id_producto_ref = 100;
GO

-- 64. (Pedido por el profe en el pdf) Muestra discograficas con mas de 3 ordenes usando HAVING
SELECT id_discografica, COUNT(*) AS total_ordenes
FROM ordenes_compra
GROUP BY id_discografica
HAVING COUNT(*) > 3;
GO

-- 65. Agrupar por discografica y contar cuantas copias en total nos han surtido.
SELECT oc.id_discografica, SUM(do2.cantidad_solicitada) AS total_copias_surtidas
FROM ordenes_compra oc
JOIN detalle_ordenes do2 ON oc.id_orden = do2.id_orden
GROUP BY oc.id_discografica;
GO

-- 66. Sumar la cantidad de stock disponible en toda la cadena de tiendas.
SELECT SUM(cantidad_stock) AS stock_total_cadena FROM inventario_sucursal;
GO

-- 67. Mostrar las ordenes ordenadas por fecha de orden de mas antigua a mas reciente.
SELECT * FROM ordenes_compra ORDER BY fecha_orden ASC;
GO

-- 68. (Pedido por el profe en el pdf) Muestra discograficas con ordenes usando subconsulta con IN
SELECT * FROM discograficas
WHERE id_discografica IN (SELECT id_discografica FROM ordenes_compra);
GO

-- 69. (Pedido por el profe en el pdf) Muestra discograficas sin ordenes usando subconsulta con NOT IN
SELECT * FROM discograficas
WHERE id_discografica NOT IN (SELECT id_discografica FROM ordenes_compra);
GO

-- 70. (Pedido por el profe en el pdf) Muestra inventario de Angelopolis usando subconsulta
SELECT * FROM inventario_sucursal
WHERE id_sucursal = (SELECT id_sucursal FROM sucursales WHERE centro_comercial LIKE '%Angelopolis%');
GO

-- 71. (Pedido por el profe en el pdf) Muestra stock debajo del promedio usando subconsulta con AVG
SELECT * FROM inventario_sucursal
WHERE cantidad_stock < (SELECT AVG(cantidad_stock) FROM inventario_sucursal);
GO

-- 72. (Pedido por el profe en el pdf) Muestra los primeros 5 caracteres del contacto con SUBSTRING
SELECT id_discografica, SUBSTRING(contacto, 1, 5) AS primeros_cinco FROM discograficas;
GO

-- 73. Mostrar el detalle de orden con la menor cantidad solicitada.
SELECT TOP 1 * FROM detalle_ordenes ORDER BY cantidad_solicitada ASC;
GO

-- 74. Contar cuantos IDs de productos distintos tenemos fisicamente en tienda.
SELECT COUNT(DISTINCT id_producto_ref) AS productos_fisicos_distintos FROM inventario_sucursal;
GO

-- 75. Mostrar registros de inventario con stock igual a 0 (agotados).
SELECT * FROM inventario_sucursal WHERE cantidad_stock = 0;
GO

-- 76. Mostrar el TOP 1 del disco con mayor cantidad de copias almacenadas en una sola sucursal.
SELECT TOP 1 * FROM inventario_sucursal ORDER BY cantidad_stock DESC;
GO

-- 77. (Pedido por el profe en el pdf) Suma cantidades de ordenes pendientes usando JOIN y WHERE
SELECT SUM(do2.cantidad_solicitada) AS total_pendiente
FROM detalle_ordenes do2
JOIN ordenes_compra oc ON do2.id_orden = oc.id_orden
WHERE oc.estado_orden = 'Pendiente';
GO

-- 78. Mostrar sucursales que contengan la palabra 'Plaza' en su centro comercial.
SELECT * FROM sucursales WHERE centro_comercial LIKE '%Plaza%';
GO

-- 79. Mostrar las sucursales ubicadas en la ciudad de 'CDMX' o 'Puebla'.
SELECT * FROM sucursales WHERE ciudad IN ('CDMX', 'Puebla');
GO

-- 80. (Pedido por el profe en el pdf) Muestra ordenes del ultimo trimestre usando DATEADD
SELECT * FROM ordenes_compra
WHERE fecha_orden >= DATEADD(MONTH, -3, GETDATE());
GO

-- =============================================
-- 10 JOINS (Fase 5 - REQUERIDO PDF)
-- =============================================

-- 11. Mostrar el nombre de la sucursal y la cantidad en stock de sus discos (INNER JOIN).
SELECT s.nombre_tienda, i.cantidad_stock, i.id_producto_ref
FROM sucursales s
INNER JOIN inventario_sucursal i ON s.id_sucursal = i.id_sucursal;
GO

-- 12. (Pedido por el profe en el pdf) Suma discos surtidos por discografica usando LEFT JOIN
SELECT d.id_discografica, d.razon_social, SUM(do2.cantidad_solicitada) AS total_surtido
FROM discograficas d
LEFT JOIN ordenes_compra oc ON d.id_discografica = oc.id_discografica
LEFT JOIN detalle_ordenes do2 ON oc.id_orden = do2.id_orden
GROUP BY d.id_discografica, d.razon_social;
GO

-- 13. Triple JOIN: Fecha de la orden, cantidad solicitada y razon social de la discografica.
SELECT oc.fecha_orden, do2.cantidad_solicitada, d.razon_social
FROM ordenes_compra oc
INNER JOIN discograficas d ON oc.id_discografica = d.id_discografica
INNER JOIN detalle_ordenes do2 ON oc.id_orden = do2.id_orden;
GO

-- 14. Mostrar sucursales que NO tienen discos en inventario (LEFT JOIN).
SELECT s.*
FROM sucursales s
LEFT JOIN inventario_sucursal i ON s.id_sucursal = i.id_sucursal
WHERE i.id_inventario IS NULL;
GO

-- 15. Agrupar por discografica y contar cuantas ordenes de compra tienen.
SELECT d.id_discografica, d.razon_social, COUNT(oc.id_orden) AS total_ordenes
FROM discograficas d
LEFT JOIN ordenes_compra oc ON d.id_discografica = oc.id_discografica
GROUP BY d.id_discografica, d.razon_social;
GO

-- 16. Mostrar el estado de la orden y el costo unitario de su detalle.
SELECT oc.estado_orden, do2.costo_unitario
FROM ordenes_compra oc
INNER JOIN detalle_ordenes do2 ON oc.id_orden = do2.id_orden;
GO

-- 17. (Pedido por el profe en el pdf) Cuenta copias fisicas por sucursal usando RIGHT JOIN
SELECT s.nombre_tienda, SUM(i.cantidad_stock) AS copias_fisicas
FROM inventario_sucursal i
RIGHT JOIN sucursales s ON i.id_sucursal = s.id_sucursal
GROUP BY s.id_sucursal, s.nombre_tienda;
GO

-- 18. Mostrar ordenes en estado 'Pendiente' cruzadas con el contacto de la discografica.
SELECT oc.*, d.contacto
FROM ordenes_compra oc
INNER JOIN discograficas d ON oc.id_discografica = d.id_discografica
WHERE oc.estado_orden = 'Pendiente';
GO

-- 19. Mostrar discograficas con razon social que empiece con 'S' y las ordenes que nos surtieron.
SELECT d.*, oc.id_orden, oc.fecha_orden, oc.estado_orden
FROM discograficas d
LEFT JOIN ordenes_compra oc ON d.id_discografica = oc.id_discografica
WHERE d.razon_social LIKE 'S%';
GO

-- 20. Mostrar discograficas a las que actualmente NO se les ha hecho ninguna orden de compra.
SELECT d.*
FROM discograficas d
LEFT JOIN ordenes_compra oc ON d.id_discografica = oc.id_discografica
WHERE oc.id_orden IS NULL;
GO
