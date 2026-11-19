// Encargos: plantillas, tipos (con su perfil de hardware), clientes,
// reputación y las líneas que se escriben en el minijuego.

export const DIFFICULTIES = {
  muy_facil: { label: 'Muy Fácil', color: '#40a040' },
  facil: { label: 'Fácil', color: '#208020' },
  normal: { label: 'Normal', color: '#a09000' },
  dificil: { label: 'Difícil', color: '#c07000' },
  muy_dificil: { label: 'Muy Difícil', color: '#c03030' },
  extremo: { label: 'Extremo', color: '#e02000' },
  pesadilla: { label: 'Pesadilla', color: '#800080' },
  inframundo: { label: 'Inframundo', color: '#a000e0' },
  infierno: { label: 'Infierno', color: '#e0004c' },
};
export const DIFFICULTY_ORDER = ['muy_facil', 'facil', 'normal', 'dificil', 'muy_dificil', 'extremo', 'pesadilla', 'inframundo', 'infierno'];

export const PROJECTS = [
  { name: 'Ordenar escritorio', type: 'datos', desc: 'Organizar papeles y limpiar escritorio.', hp: 150, reward: 40, difficulty: 'muy_facil' },
  { name: 'Archivar recibos', type: 'datos', desc: 'Guardar 50 recibos en carpetas.', hp: 150, reward: 45, difficulty: 'muy_facil' },
  { name: 'Copiar documentos', type: 'texto', desc: 'Hacer 20 copias de formularios.', hp: 150, reward: 50, difficulty: 'muy_facil' },
  { name: 'Digitación de formularios', type: 'datos', desc: 'Digitar 200 formularios de seguros.', hp: 250, reward: 55, difficulty: 'facil' },
  { name: 'Clasificación de archivos', type: 'datos', desc: 'Clasificar 500 archivos por categoría y fecha.', hp: 250, reward: 70, difficulty: 'facil' },
  { name: 'Traducción de documentos', type: 'texto', desc: 'Traducir 10 documentos legales al español.', hp: 250, reward: 75, difficulty: 'facil' },
  { name: 'Soporte técnico', type: 'redes', desc: 'Dar soporte técnico por teléfono a clientes.', hp: 250, reward: 80, difficulty: 'facil' },
  { name: 'Revisión de facturas', type: 'datos', desc: 'Revisar 150 facturas por errores.', hp: 250, reward: 95, difficulty: 'facil' },
  { name: 'Copia de documentos', type: 'grafico', desc: 'Digitalizar 300 documentos con scanner.', hp: 450, reward: 95, difficulty: 'normal' },
  { name: 'Inventario de almacén', type: 'datos', desc: 'Inventariar productos del almacén.', hp: 450, reward: 110, difficulty: 'normal' },
  { name: 'Procesamiento de nóminas', type: 'datos', desc: 'Calcular nóminas de 50 empleados.', hp: 450, reward: 130, difficulty: 'normal' },
  { name: 'Help Desk interno', type: 'redes', desc: 'Resolver tickets de soporte interno.', hp: 450, reward: 120, difficulty: 'normal' },
  { name: 'Redacción de cartas', type: 'texto', desc: 'Redactar 50 cartas comerciales.', hp: 450, reward: 145, difficulty: 'normal' },
  { name: 'Archivo de correspondencia', type: 'texto', desc: 'Archivar 400 cartas y documentos.', hp: 750, reward: 125, difficulty: 'dificil' },
  { name: 'Base de datos de clientes', type: 'software', desc: 'Crear BD de 200 clientes en Access.', hp: 750, reward: 155, difficulty: 'dificil' },
  { name: 'Revisión de impresiones', type: 'grafico', desc: 'Revisar documentos impresos por erratas.', hp: 750, reward: 140, difficulty: 'dificil' },
  { name: 'Base de datos Access', type: 'software', desc: 'Crear sistema de inventario para empresa local.', hp: 750, reward: 190, difficulty: 'dificil' },
  { name: 'Página web corporativa', type: 'grafico', desc: 'Diseño de sitio web con HTML y tablas.', hp: 750, reward: 235, difficulty: 'dificil' },
  { name: 'Reporte de nóminas', type: 'datos', desc: 'Sistema de nómina en hoja de cálculo.', hp: 1200, reward: 170, difficulty: 'muy_dificil' },
  { name: 'Presentación multimedia', type: 'grafico', desc: 'Diapositivas con animaciones y transiciones.', hp: 1200, reward: 205, difficulty: 'muy_dificil' },
  { name: 'Soporte de red', type: 'redes', desc: 'Configurar red local entre 5 computadoras.', hp: 1200, reward: 240, difficulty: 'muy_dificil' },
  { name: 'App de inventario', type: 'software', desc: 'Programa de control de stock en Visual Basic.', hp: 1200, reward: 345, difficulty: 'muy_dificil' },
  { name: 'Compilador básico', type: 'software', desc: 'Crear compilador para lenguaje simple.', hp: 1800, reward: 270, difficulty: 'extremo' },
  { name: 'Servidor web', type: 'redes', desc: 'Montar servidor HTTP con scripts CGI.', hp: 1800, reward: 330, difficulty: 'extremo' },
  { name: 'Motor de búsqueda', type: 'software', desc: 'Indexador de páginas web con arañas.', hp: 1800, reward: 390, difficulty: 'extremo' },
  { name: 'Sistema de facturación', type: 'software', desc: 'Generador de facturas con base de datos.', hp: 2600, reward: 390, difficulty: 'pesadilla' },
  { name: 'Conversor de formatos', type: 'software', desc: 'Herramienta para convertir archivos entre formatos.', hp: 2600, reward: 490, difficulty: 'pesadilla' },
  { name: 'Editor de código fuente', type: 'software', desc: 'IDE con resaltado de sintaxis.', hp: 3600, reward: 490, difficulty: 'inframundo' },
  { name: 'Cliente de correo', type: 'software', desc: 'Cliente SMTP/POP3 con interfaz gráfica.', hp: 3600, reward: 590, difficulty: 'inframundo' },
  { name: 'Antivirus', type: 'software', desc: 'Escáner de virus con firmas actualizadas.', hp: 3600, reward: 720, difficulty: 'inframundo' },
  { name: 'Sistema operativo', type: 'software', desc: 'Kernel con multitarea y sistema de archivos.', hp: 5000, reward: 685, difficulty: 'infierno' },
  { name: 'Base de datos relacional', type: 'software', desc: 'Motor SQL completo con transacciones.', hp: 5000, reward: 800, difficulty: 'infierno' },
  { name: 'Navegador web', type: 'software', desc: 'Navegador con motor de render HTML 3.2.', hp: 5000, reward: 915, difficulty: 'infierno' },
];


/** Días de plazo según la dificultad (1 día = 10 s). */
export const contractDays = (difficulty) => 14 + 2 * DIFFICULTY_ORDER.indexOf(difficulty);

// Perfil: cuánto rinde cada componente en este tipo de encargo (1 = normal).
export const CONTRACT_TYPES = {
  datos: { label: 'Datos', color: '#206090', hint: 'CPU y RAM', profile: { display: 0.6, cpu: 1.3, ram: 1.2, cooling: 0.8 } },
  texto: { label: 'Texto', color: '#606020', hint: 'Parejo', profile: { display: 0.9, cpu: 1.0, ram: 1.0, cooling: 0.9 } },
  grafico: { label: 'Gráfico', color: '#a03080', hint: 'GPU', profile: { display: 1.7, cpu: 0.8, ram: 0.9, cooling: 0.6 } },
  redes: { label: 'Redes', color: '#207050', hint: 'Refrigeración', profile: { display: 0.5, cpu: 0.9, ram: 0.9, cooling: 1.7 } },
  software: { label: 'Software', color: '#6020a0', hint: 'CPU y refrigeración', profile: { display: 0.6, cpu: 1.4, ram: 1.0, cooling: 1.2 } },
};

export const CLIENTS = [
  'Ferretería El Clavo', 'Colegio San Andrés', 'Panadería La Espiga', 'Estudio Jurídico Rojas', 'Radio Comunal',
  'Taller Mecánico Díaz', 'Club Deportivo Unión', 'Municipalidad', 'Clínica Dental Sonrisa', 'Banda Los Módems',
  'Imprenta Gutenberg', 'Videoclub Estelar', 'Botillería Don Lucho', 'Agencia de Viajes Sol', 'Constructora Ladrillo',
];

// Reputación: cada nivel desbloquea la siguiente dificultad.
export const REP_LEVELS = [
  { name: 'Desconocido', need: 0 },
  { name: 'Conocido en el barrio', need: 15 },
  { name: 'Recomendado', need: 50 },
  { name: 'Confiable', need: 120 },
  { name: 'Profesional', need: 250 },
  { name: 'Experto', need: 450 },
  { name: 'Referente', need: 750 },
  { name: 'Leyenda', need: 1150 },
  { name: 'Mito del garaje', need: 1700 },
];
/** Reputación que da cada dificultad (índice de DIFFICULTY_ORDER). */
export const REP_GAIN = [1, 2, 3, 5, 8, 12, 18, 26, 36];

// Líneas del minijuego de escritura según el tipo de encargo
// (el software usa los fragmentos de código del Code Editor).
export const LINES = {
  datos: [
    'Factura 0142 - Ferreteria - $12.500', 'Cliente: Perez, Juan - Fono 555-1234', 'Recibo 0087 pagado el 12/03/95',
    'Stock: 40 cajas de tornillos 3/8', 'Codigo 7791 - Martillo - $3.990', 'Total del mes: $1.284.300',
    'Rut 12.345.678-9 - Soto, Maria', 'Pedido 551 - 12 resmas de papel', 'Saldo pendiente: $45.000',
  ],
  texto: [
    'Estimado cliente: adjunto el informe solicitado.', 'Sin otro particular, le saluda atentamente.',
    'De acuerdo a lo conversado por telefono...', 'Se ruega confirmar la recepcion de este documento.',
    'El plazo de entrega vence el viernes.', 'Quedamos atentos a sus comentarios.',
  ],
  grafico: [
    'capa fondo: degradado azul a negro', 'logo.bmp 640x480 a 256 colores', 'texto titulo: Arial 36 negrita',
    'transicion: barrido desde la izquierda', '<table border=1 bgcolor="#c0c0c0">', '<img src="logo.gif" width=120>',
  ],
  redes: [
    'ping 192.168.0.1', 'ipconfig /all', 'net use F: \\SERVIDOR\datos', 'route add 10.0.0.0 mask 255.0.0.0 192.168.0.254',
    'tracert www.empresa.com', 'netstat -an', 'arp -a',
  ],
};
