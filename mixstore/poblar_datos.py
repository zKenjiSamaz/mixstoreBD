import mysql.connector
import psycopg2
import pyodbc
import random
import json
from datetime import datetime, timedelta
from faker import Faker

fake = Faker('es_MX')

BANDAS_REALES = [
    ("Metallica", "Thrash Metal", "Estados Unidos"),
    ("Queen", "Rock Clasico", "Reino Unido"),
    ("BTS", "K-Pop", "Corea del Sur"),
    ("The Beatles", "Rock Clasico", "Reino Unido"),
    ("Pink Floyd", "Rock Progresivo", "Reino Unido"),
    ("Nirvana", "Grunge", "Estados Unidos"),
    ("AC/DC", "Hard Rock", "Australia"),
    ("Led Zeppelin", "Hard Rock", "Reino Unido"),
    ("Dua Lipa", "Pop", "Reino Unido"),
    ("Bad Bunny", "Reggaeton", "Puerto Rico"),
    ("The Rolling Stones", "Rock Clasico", "Reino Unido"),
    ("Iron Maiden", "Heavy Metal", "Reino Unido"),
    ("Shakira", "Pop Latino", "Colombia"),
    ("Muse", "Rock Alternativo", "Reino Unido"),
    ("Red Hot Chili Peppers", "Funk Rock", "Estados Unidos"),
    ("Blackpink", "K-Pop", "Corea del Sur"),
    ("The Weeknd", "R&B", "Canada"),
    ("Taylor Swift", "Pop", "Estados Unidos"),
    ("Guns N' Roses", "Hard Rock", "Estados Unidos"),
    ("Coldplay", "Rock Alternativo", "Reino Unido"),
    ("Adele", "Soul", "Reino Unido"),
    ("Ed Sheeran", "Pop", "Reino Unido"),
    ("Imagine Dragons", "Rock Alternativo", "Estados Unidos"),
    ("Rosalia", "Flamenco Pop", "Espana"),
    ("Billie Eilish", "Pop Alternativo", "Estados Unidos"),
    ("Slayer", "Thrash Metal", "Estados Unidos"),
    ("Megadeth", "Thrash Metal", "Estados Unidos"),
    ("Rammstein", "Metal Industrial", "Alemania"),
    ("System of a Down", "Metal Alternativo", "Armenia/Estados Unidos"),
    ("Foo Fighters", "Rock Alternativo", "Estados Unidos"),
    ("Stray Kids", "K-Pop", "Corea del Sur"),
    ("TWICE", "K-Pop", "Corea del Sur"),
    ("NCT 127", "K-Pop", "Corea del Sur"),
    ("Seventeen", "K-Pop", "Corea del Sur"),
    ("Ateez", "K-Pop", "Corea del Sur"),
    ("Soda Stereo", "Rock Latino", "Argentina"),
    ("Caifanes", "Rock Latino", "Mexico"),
    ("Cafe Tacvba", "Rock Alternativo", "Mexico"),
    ("Molotov", "Rap Rock", "Mexico"),
    ("Los Fabulosos Cadillacs", "Ska Latino", "Argentina"),
    ("Juanes", "Rock Latino", "Colombia"),
    ("Luis Miguel", "Bolero", "Mexico"),
    ("Vicente Fernandez", "Ranchera", "Mexico"),
    ("Grupo Firme", "Regional Mexicano", "Mexico"),
    ("Natalia Lafourcade", "Pop Alternativo", "Mexico"),
    ("Julieta Venegas", "Pop Rock", "Mexico"),
    ("Mon Laferte", "Pop Rock", "Chile"),
    ("Zoe", "Rock Alternativo", "Mexico"),
    ("Enrique Iglesias", "Pop Latino", "Espana"),
    ("Manu Chao", "World Music", "Francia/Espana"),
]

DISCOS_DESTACADOS = {
    "Metallica": ["Master of Puppets", "Ride the Lightning", "The Black Album", "And Justice for All", "Kill 'Em All", "Hardwired to Self-Destruct", "Death Magnetic", "72 Seasons"],
    "Queen": ["A Night at the Opera", "News of the World", "The Game", "Greatest Hits", "Innuendo", "A Kind of Magic"],
    "BTS": ["Love Yourself: Answer", "Map of the Soul: 7", "BE", "Proof", "Wings", "Dark & Wild"],
    "The Beatles": ["Abbey Road", "Sgt. Pepper's", "Revolver", "The White Album", "Let It Be", "Rubber Soul"],
    "Pink Floyd": ["The Dark Side of the Moon", "The Wall", "Wish You Were Here", "Animals", "The Division Bell"],
    "Nirvana": ["Nevermind", "In Utero", "MTV Unplugged", "Bleach", "Incesticide"],
    "AC/DC": ["Back in Black", "Highway to Hell", "Power Up", "The Razors Edge", "For Those About to Rock"],
    "Led Zeppelin": ["Led Zeppelin IV", "Physical Graffiti", "Houses of the Holy", "Led Zeppelin II", "Presence"],
    "Bad Bunny": ["Un Verano Sin Ti", "YHLQMDLG", "El Ultimo Tour del Mundo", "X 100PRE", "Nadie Sabe"],
}

DISCOS_GENERICOS = [
    "Greatest Hits Collection", "Live in Concert", "The Best of",
    "Unplugged Session", "En Vivo", "Acoustic Versions",
    "Remastered Edition", "Deluxe Anniversary", "The Lost Tapes",
    "Studio Sessions Vol. 1", "Live at Wembley", "BBC Sessions",
    "Electric Nights", "The Journey So Far", "Chronicles",
    "Breaking Through", "Revolution", "Timeless",
]

CENTROS_COMERCIALES = [
    "Angelopolis", "Galerias", "Perisur", "Santa Fe", "Antara",
    "Plaza Universidad", "Centro Mayor", "Plaza Las Americas",
    "Multiplaza", "Plaza Sendero", "Parque Tezontle", "Plaza Satelite",
    "Plaza Carso", "Miyana", "Paseo Interlomas", "Plaza Coapa",
    "Forum Buenavista", "Plaza Lindavista", "Patio Revolucion", "Parque Delta",
]

CIUDADES = ["CDMX", "Puebla", "Guadalajara", "Monterrey", "Cancun", "Queretaro", "Leon", "Tijuana", "Merida", "Toluca"]

DISCOGRAFICAS_REALES = [
    "Sony Music Entertainment", "Universal Music Group", "Warner Music Group",
    "EMI Records", "Columbia Records", "Interscope Records",
    "Atlantic Records", "Capitol Records", "Epic Records",
    "Republic Records", "Def Jam Recordings", "Island Records",
    "RCA Records", "Polydor Records", "Virgin Records",
    "Geffen Records", "Motown Records", "Mercury Records",
    "A&M Records", "Elektra Records",
]

CONCEPTOS_GASTOS = ["Luz", "Renta", "Agua", "Internet", "Seguridad", "Limpieza", "Mantenimiento", "Publicidad", "Nominas", "Papeleria"]

METODOS_PAGO = ['Tarjeta de Credito', 'PayPal', 'Transferencia', 'Tarjeta de Debito']
PASARELAS = ['Stripe', 'MercadoPago', 'PayPal Checkout', 'OpenPay', 'Conekta']

def poblar_todo():
    print("MixStore - Poblacion Masiva de Datos\n")

    try:
        cnx = mysql.connector.connect(user='root', password='MixStore2026!', host='127.0.0.1', port=3306, database='punto_venta_db')
        print("✅ MySQL: Conexion exitosa")
    except Exception as e:
        print(f"❌ MySQL: {e}")
        return

    cur = cnx.cursor()

    cur.execute("""CREATE TABLE IF NOT EXISTS clientes (
        id_cliente INT AUTO_INCREMENT PRIMARY KEY,
        nombre_completo VARCHAR(150) NOT NULL,
        email VARCHAR(120) UNIQUE NOT NULL,
        telefono VARCHAR(20),
        puntos_mix INT DEFAULT 0
    )""")

    cur.execute("""CREATE TABLE IF NOT EXISTS artistas (
        id_artista INT AUTO_INCREMENT PRIMARY KEY,
        nombre_banda VARCHAR(150) NOT NULL,
        genero_principal VARCHAR(60) NOT NULL,
        pais_origen VARCHAR(80) NOT NULL
    )""")

    cur.execute("""CREATE TABLE IF NOT EXISTS productos_musicales (
        id_producto INT AUTO_INCREMENT PRIMARY KEY,
        titulo VARCHAR(200) NOT NULL,
        id_artista INT NOT NULL,
        formato ENUM('CD', 'Vinilo', 'K-Pop', 'Merch') NOT NULL,
        precio_unitario DECIMAL(10, 2) NOT NULL,
        FOREIGN KEY (id_artista) REFERENCES artistas(id_artista)
    )""")

    cur.execute("""CREATE TABLE IF NOT EXISTS ventas_tienda (
        id_venta INT AUTO_INCREMENT PRIMARY KEY,
        id_cliente INT NOT NULL,
        fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
        total_venta DECIMAL(12, 2) DEFAULT 0,
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
    )""")

    cur.execute("""CREATE TABLE IF NOT EXISTS detalle_ventas (
        id_detalle INT AUTO_INCREMENT PRIMARY KEY,
        id_venta INT NOT NULL,
        id_producto INT NOT NULL,
        cantidad INT NOT NULL,
        subtotal DECIMAL(12, 2) DEFAULT 0,
        FOREIGN KEY (id_venta) REFERENCES ventas_tienda(id_venta),
        FOREIGN KEY (id_producto) REFERENCES productos_musicales(id_producto)
    )""")

    cnx.commit()
    print("   Tablas creadas/verificadas")

    total = 0

    print("   Insertando 80 clientes...")
    for _ in range(80):
        cur.execute("INSERT INTO clientes (nombre_completo, email, telefono, puntos_mix) VALUES (%s, %s, %s, %s)", (fake.name(), fake.unique.email(), fake.phone_number()[:20], random.randint(0, 2000)))
    cnx.commit()
    total += 80
    print("   ✅ 80 clientes insertados")

    print("   Insertando 20 artistas...")
    for banda, genero, pais in BANDAS_REALES[:20]:
        cur.execute("INSERT INTO artistas (nombre_banda, genero_principal, pais_origen) VALUES (%s, %s, %s)", (banda, genero, pais))
    cnx.commit()
    total += 20
    print("   ✅ 20 artistas insertados")

    print("   Insertando 100 productos...")
    count = 0
    for idx in range(20):
        discos = DISCOS_DESTACADOS.get(BANDAS_REALES[idx][0], DISCOS_GENERICOS[:4])
        for titulo in discos[:4]:
            if count >= 100:
                break
            precio = round(random.uniform(199, 1299), 2)
            fmt = 'CD' if random.random() > 0.3 else 'Vinilo'
            cur.execute("INSERT INTO productos_musicales (titulo, id_artista, formato, precio_unitario) VALUES (%s, %s, %s, %s)", (titulo, idx + 1, fmt, precio))
            count += 1
        if count >= 100:
            break
    while count < 100:
        cur.execute("INSERT INTO productos_musicales (titulo, id_artista, formato, precio_unitario) VALUES (%s, %s, %s, %s)", (random.choice(DISCOS_GENERICOS), random.randint(1, 20), random.choice(['CD', 'Vinilo', 'K-Pop', 'Merch']), round(random.uniform(199, 1299), 2)))
        count += 1
    cnx.commit()
    total += 100
    print("   ✅ 100 productos insertados")

    print("   Insertando 100 ventas con detalles...")
    for _ in range(100):
        cur.execute("INSERT INTO ventas_tienda (id_cliente, fecha_venta, total_venta) VALUES (%s, %s, 0)", (random.randint(1, 80), fake.date_time_between(start_date='-1y', end_date='now')))
        id_venta = cur.lastrowid
        for _ in range(random.randint(1, 5)):
            cur.execute("INSERT INTO detalle_ventas (id_venta, id_producto, cantidad) VALUES (%s, %s, %s)", (id_venta, random.randint(1, 100), random.randint(1, 3)))
    cnx.commit()
    total += 100
    print("   ✅ 100 ventas con detalles insertadas")

    cnx.close()
    print(f"📊 MySQL: {total} registros insertados")
    print("✅ MySQL: Datos guardados correctamente\n")

    try:
        conn_str = 'DRIVER={ODBC Driver 18 for SQL Server};SERVER=127.0.0.1,1433;UID=sa;PWD=MixStore2026!;TrustServerCertificate=yes;'
        cnx_ss = pyodbc.connect(conn_str, autocommit=False)
        print("✅ SQL Server: Conexion exitosa")
    except Exception as e:
        print(f"❌ SQL Server: {e}")
        return

    cur_ss = cnx_ss.cursor()
    cnx_ss.autocommit = True
    cur_ss.execute("IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'logistica_inventario_db') CREATE DATABASE logistica_inventario_db")
    cur_ss.execute("USE logistica_inventario_db")
    cnx_ss.autocommit = False

    cur_ss.execute("""IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'discograficas')
    CREATE TABLE discograficas (
        id_discografica INT IDENTITY(1,1) PRIMARY KEY,
        razon_social VARCHAR(200) NOT NULL,
        contacto VARCHAR(150),
        telefono VARCHAR(20)
    )""")

    cur_ss.execute("""IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'sucursales')
    CREATE TABLE sucursales (
        id_sucursal INT IDENTITY(1,1) PRIMARY KEY,
        nombre_tienda VARCHAR(100) NOT NULL,
        centro_comercial VARCHAR(150),
        ciudad VARCHAR(80) NOT NULL
    )""")

    cur_ss.execute("""IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'inventario_sucursal')
    CREATE TABLE inventario_sucursal (
        id_inventario INT IDENTITY(1,1) PRIMARY KEY,
        id_producto_ref INT NOT NULL,
        id_sucursal INT NOT NULL,
        cantidad_stock INT DEFAULT 0,
        pasillo VARCHAR(20),
        FOREIGN KEY (id_sucursal) REFERENCES sucursales(id_sucursal)
    )""")

    cur_ss.execute("""IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ordenes_compra')
    CREATE TABLE ordenes_compra (
        id_orden INT IDENTITY(1,1) PRIMARY KEY,
        id_discografica INT NOT NULL,
        fecha_orden DATETIME DEFAULT GETDATE(),
        estado_orden VARCHAR(20) CHECK (estado_orden IN ('Pendiente', 'Enviado', 'Recibido')),
        FOREIGN KEY (id_discografica) REFERENCES discograficas(id_discografica)
    )""")

    cur_ss.execute("""IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'detalle_ordenes')
    CREATE TABLE detalle_ordenes (
        id_detalle_orden INT IDENTITY(1,1) PRIMARY KEY,
        id_orden INT NOT NULL,
        id_producto_ref INT NOT NULL,
        cantidad_solicitada INT NOT NULL,
        costo_unitario DECIMAL(10, 2) NOT NULL,
        FOREIGN KEY (id_orden) REFERENCES ordenes_compra(id_orden)
    )""")

    cnx_ss.commit()
    print("   Tablas creadas/verificadas")

    total = 0

    print("   Insertando 15 discograficas...")
    for razon in DISCOGRAFICAS_REALES[:15]:
        cur_ss.execute("INSERT INTO discograficas (razon_social, contacto, telefono) VALUES (?, ?, ?)", (razon, fake.name(), fake.phone_number()[:20]))
    cnx_ss.commit()
    total += 15
    print("   ✅ 15 discograficas insertadas")

    print("   Insertando 10 sucursales...")
    for _ in range(10):
        cur_ss.execute("INSERT INTO sucursales (nombre_tienda, centro_comercial, ciudad) VALUES (?, ?, ?)", (f"MixStore {fake.city()}"[:100], random.choice(CENTROS_COMERCIALES), random.choice(CIUDADES)))
    cnx_ss.commit()
    total += 10
    print("   ✅ 10 sucursales insertadas")

    print("   Insertando 150 registros de inventario...")
    for _ in range(150):
        cur_ss.execute("INSERT INTO inventario_sucursal (id_producto_ref, id_sucursal, cantidad_stock, pasillo) VALUES (?, ?, ?, ?)", (random.randint(1, 100), random.randint(1, 10), random.randint(0, 100), f"{random.choice('ABCDEFGH')}{random.randint(1,20)}"))
    cnx_ss.commit()
    total += 150
    print("   ✅ 150 inventarios insertados")

    print("   Insertando 75 ordenes con detalles...")
    for _ in range(75):
        cur_ss.execute("INSERT INTO ordenes_compra (id_discografica, fecha_orden, estado_orden) OUTPUT INSERTED.id_orden VALUES (?, ?, ?)", (random.randint(1, 15), fake.date_time_between(start_date='-1y', end_date='now'), random.choice(['Pendiente', 'Enviado', 'Recibido'])))
        id_orden = int(cur_ss.fetchone()[0])
        for _ in range(random.randint(1, 5)):
            cur_ss.execute("INSERT INTO detalle_ordenes (id_orden, id_producto_ref, cantidad_solicitada, costo_unitario) VALUES (?, ?, ?, ?)", (id_orden, random.randint(1, 100), random.randint(10, 500), round(random.uniform(50, 300), 2)))
    cnx_ss.commit()
    total += 75
    print("   ✅ 75 ordenes con detalles insertadas")

    cnx_ss.close()
    print(f"📊 SQL Server: {total} registros insertados")
    print("✅ SQL Server: Datos guardados correctamente\n")

    try:
        cnx_pg = psycopg2.connect(user='mixstore', password='MixStore2026!', host='127.0.0.1', port=5432, database='ecommerce_auditoria_db')
        print("✅ PostgreSQL: Conexion exitosa")
    except Exception as e:
        print(f"❌ PostgreSQL: {e}")
        return

    cur_pg = cnx_pg.cursor()

    cur_pg.execute("""CREATE TABLE IF NOT EXISTS membresias_mix (
        id_membresia SERIAL PRIMARY KEY,
        id_cliente_ref INT NOT NULL,
        nivel VARCHAR(20) CHECK (nivel IN ('Oro', 'Platino')),
        fecha_suscripcion DATE DEFAULT CURRENT_DATE,
        activa BOOLEAN DEFAULT TRUE
    )""")

    cur_pg.execute("""CREATE TABLE IF NOT EXISTS ventas_online (
        id_pedido_web SERIAL PRIMARY KEY,
        id_cliente_ref INT NOT NULL,
        direccion_envio TEXT NOT NULL,
        fecha_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        total_pagado DECIMAL(12, 2) NOT NULL,
        estado_envio VARCHAR(30) DEFAULT 'Pendiente'
    )""")

    cur_pg.execute("""CREATE TABLE IF NOT EXISTS pagos_online (
        id_pago SERIAL PRIMARY KEY,
        id_pedido_web INT NOT NULL,
        metodo_pago VARCHAR(50),
        pasarela_aprobacion VARCHAR(100),
        fecha_cobro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_pedido_web) REFERENCES ventas_online(id_pedido_web)
    )""")

    cur_pg.execute("""CREATE TABLE IF NOT EXISTS gastos_operativos (
        id_gasto SERIAL PRIMARY KEY,
        id_sucursal_ref INT NOT NULL,
        concepto VARCHAR(150) NOT NULL,
        monto DECIMAL(12, 2) NOT NULL,
        fecha_gasto DATE DEFAULT CURRENT_DATE
    )""")

    cur_pg.execute("""CREATE TABLE IF NOT EXISTS log_auditoria (
        id_log SERIAL PRIMARY KEY,
        usuario VARCHAR(100) NOT NULL,
        modulo VARCHAR(50) NOT NULL,
        accion VARCHAR(50) NOT NULL,
        fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        detalles JSONB
    )""")

    cnx_pg.commit()
    print("   Tablas creadas/verificadas")

    total = 0

    print("   Insertando 60 membresias...")
    for _ in range(60):
        cur_pg.execute("INSERT INTO membresias_mix (id_cliente_ref, nivel, fecha_suscripcion, activa) VALUES (%s, %s, %s, %s)", (random.randint(1, 80), random.choice(['Oro', 'Platino']), fake.date_between(start_date='-2y', end_date='today'), random.random() > 0.3))
    cnx_pg.commit()
    total += 60
    print("   ✅ 60 membresias insertadas")

    print("   Insertando 60 ventas online...")
    ids_ventas = []
    for _ in range(60):
        cur_pg.execute("INSERT INTO ventas_online (id_cliente_ref, direccion_envio, fecha_pedido, total_pagado, estado_envio) VALUES (%s, %s, %s, %s, %s) RETURNING id_pedido_web", (random.randint(1, 80), fake.address().replace('\n', ', '), fake.date_time_between(start_date='-1y', end_date='now'), round(random.uniform(100, 10000), 2), random.choice(['Pendiente', 'Enviado', 'En Ruta', 'Entregado', 'Cancelado'])))
        ids_ventas.append(cur_pg.fetchone()[0])
    cnx_pg.commit()
    total += 60
    print("   ✅ 60 ventas online insertadas")

    print("   Insertando 60 pagos online...")
    for vid in ids_ventas:
        cur_pg.execute("INSERT INTO pagos_online (id_pedido_web, metodo_pago, pasarela_aprobacion, fecha_cobro) VALUES (%s, %s, %s, %s)", (vid, random.choice(METODOS_PAGO), random.choice(PASARELAS), fake.date_time_between(start_date='-1y', end_date='now')))
    cnx_pg.commit()
    total += 60
    print("   ✅ 60 pagos online insertados")

    print("   Insertando 40 gastos operativos...")
    for _ in range(40):
        cur_pg.execute("INSERT INTO gastos_operativos (id_sucursal_ref, concepto, monto, fecha_gasto) VALUES (%s, %s, %s, %s)", (random.randint(1, 10), random.choice(CONCEPTOS_GASTOS), round(random.uniform(500, 150000), 2), fake.date_between(start_date='-1y', end_date='today')))
    cnx_pg.commit()
    total += 40
    print("   ✅ 40 gastos insertados")

    print("   Insertando 30 registros de auditoria...")
    modulos = ['E-Commerce', 'Autenticacion', 'Inventario', 'Pagos', 'Usuarios']
    acciones = ['INSERT', 'UPDATE', 'DELETE', 'SELECT']
    for _ in range(30):
        cur_pg.execute("INSERT INTO log_auditoria (usuario, modulo, accion, fecha, detalles) VALUES (%s, %s, %s, %s, %s::jsonb)", (fake.user_name()[:100], random.choice(modulos), random.choice(acciones), fake.date_time_between(start_date='-6m', end_date='now'), json.dumps({'usuario_sistema': fake.user_name()[:50], 'ip_cliente': fake.ipv4(), 'error': random.choice(['none', 'none', 'none', 'fatal', 'warning'])})))
    cnx_pg.commit()
    total += 30
    print("   ✅ 30 logs insertados")

    cnx_pg.close()
    print(f"📊 PostgreSQL: {total} registros insertados")
    print("✅ PostgreSQL: Datos guardados correctamente")

    print("\nProceso terminado. Ve a DBeaver para comprobar que los datos están ahí.")

if __name__ == "__main__":
    poblar_todo()
