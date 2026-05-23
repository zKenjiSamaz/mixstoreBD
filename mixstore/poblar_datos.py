#!/usr/bin/env python3
import mysql.connector
import psycopg2
import pyodbc
import random
import json
from datetime import datetime, timedelta
from dataclasses import dataclass
from faker import Faker

fake = Faker('es_MX')

@dataclass
class Cliente:
    nombre_completo: str
    email: str
    telefono: str
    puntos_mix: int

@dataclass
class Artista:
    nombre_banda: str
    genero_principal: str
    pais_origen: str

@dataclass
class Producto:
    titulo: str
    id_artista: int
    formato: str
    precio_unitario: float

@dataclass
class VentaFisica:
    id_cliente: int
    fecha_venta: datetime

@dataclass
class DetalleVenta:
    id_venta: int
    id_producto: int
    cantidad: int

@dataclass
class Discografica:
    razon_social: str
    contacto: str
    telefono: str

@dataclass
class Sucursal:
    nombre_tienda: str
    centro_comercial: str
    ciudad: str

@dataclass
class Inventario:
    id_producto_ref: int
    id_sucursal: int
    cantidad_stock: int
    pasillo: str

@dataclass
class OrdenCompra:
    id_discografica: int
    fecha_orden: datetime
    estado_orden: str

@dataclass
class DetalleOrden:
    id_orden: int
    id_producto_ref: int
    cantidad_solicitada: int
    costo_unitario: float

@dataclass
class Membresia:
    id_cliente_ref: int
    nivel: str
    fecha_suscripcion: str
    activa: bool

@dataclass
class VentaOnline:
    id_cliente_ref: int
    direccion_envio: str
    fecha_pedido: datetime
    total_pagado: float
    estado_envio: str

@dataclass
class PagoOnline:
    id_pedido_web: int
    metodo_pago: str
    pasarela_aprobacion: str
    fecha_cobro: datetime

@dataclass
class Gasto:
    id_sucursal_ref: int
    concepto: str
    monto: float
    fecha_gasto: str

@dataclass
class LogAuditoria:
    usuario: str
    modulo: str
    accion: str
    fecha: datetime
    detalles: dict

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
    gran_total = 0

    # MySQL
    print("--- Conectando a MySQL (punto_venta_db) ---")
    try:
        cnx = mysql.connector.connect(user='root', password='MixStore2026!', host='127.0.0.1', port=3306, database='punto_venta_db')
        print("✅ MySQL: Conexion exitosa")
    except Exception as e:
        print(f"❌ MySQL: {e}")
        return

    cur = cnx.cursor()
    total = 0

    print("   Insertando 80 clientes...")
    for _ in range(80):
        c = Cliente(nombre_completo=fake.name(), email=fake.unique.email(), telefono=fake.phone_number()[:20], puntos_mix=random.randint(0, 2000))
        cur.execute("INSERT INTO clientes (nombre_completo, email, telefono, puntos_mix) VALUES (%s, %s, %s, %s)", (c.nombre_completo, c.email, c.telefono, c.puntos_mix))
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
        titulo = random.choice(DISCOS_GENERICOS)
        cur.execute("INSERT INTO productos_musicales (titulo, id_artista, formato, precio_unitario) VALUES (%s, %s, %s, %s)", (titulo, random.randint(1, 20), random.choice(['CD', 'Vinilo', 'K-Pop', 'Merch']), round(random.uniform(199, 1299), 2)))
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
    gran_total += total

    # SQL Server
    print("\n--- Conectando a SQL Server (logistica_inventario_db) ---")
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
    gran_total += total

    # PostgreSQL
    print("\n--- Conectando a PostgreSQL (ecommerce_auditoria_db) ---")
    try:
        cnx_pg = psycopg2.connect(user='mixstore', password='MixStore2026!', host='127.0.0.1', port=5432, database='ecommerce_auditoria_db')
        print("✅ PostgreSQL: Conexion exitosa")
    except Exception as e:
        print(f"❌ PostgreSQL: {e}")
        return

    cur_pg = cnx_pg.cursor()
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
    gran_total += total

    print(f"\n🎯 POBLACION COMPLETADA: {gran_total} registros")
    print("Ve a DBeaver para comprobar que los datos estan ahi.")

poblar_todo()
