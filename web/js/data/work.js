// Trabajos freelance y proyectos (portado de trabajo.lua y explorer.lua)

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

// Dificultades de tareas freelance que se desbloquean por cantidad de tareas
export const TASK_UNLOCKS = { normal: 50, dificil: 100, muy_dificil: 200, pesadilla: 350 };

export const FREELANCE_TASKS = [
  { name: 'Entrada de datos', time: 1.1, difficulty: 'muy_facil' },
  { name: 'Clasificación de archivos', time: 0.9, difficulty: 'muy_facil' },
  { name: 'Archivo de correspondencia', time: 0.7, difficulty: 'muy_facil' },
  { name: 'Inventario de equipo', time: 1.1, difficulty: 'muy_facil' },
  { name: 'Corrección de documentos', time: 1.65, difficulty: 'facil' },
  { name: 'Revisión de facturas', time: 1.3, difficulty: 'facil' },
  { name: 'Digitación de formularios', time: 1.45, difficulty: 'facil' },
  { name: 'Procesamiento de nóminas', time: 2.2, difficulty: 'normal' },
  { name: 'Redacción de cartas', time: 2.0, difficulty: 'normal' },
  { name: 'Traducción simple', time: 1.8, difficulty: 'normal' },
  { name: 'Base de datos Access', time: 2.5, difficulty: 'dificil' },
  { name: 'Configuración de red', time: 2.8, difficulty: 'dificil' },
  { name: 'Página web HTML', time: 3.0, difficulty: 'dificil' },
  { name: 'App Visual Basic', time: 3.5, difficulty: 'muy_dificil' },
  { name: 'Sistema de facturación', time: 4.0, difficulty: 'muy_dificil' },
  { name: 'Red corporativa', time: 4.5, difficulty: 'pesadilla' },
  { name: 'Sistema ERP', time: 5.0, difficulty: 'pesadilla' },
];

export const PROJECTS = [
  { name: 'Ordenar escritorio', desc: 'Organizar papeles y limpiar escritorio.', hp: 30, reward: 50, difficulty: 'muy_facil' },
  { name: 'Archivar recibos', desc: 'Guardar 50 recibos en carpetas.', hp: 30, reward: 60, difficulty: 'muy_facil' },
  { name: 'Copiar documentos', desc: 'Hacer 20 copias de formularios.', hp: 30, reward: 70, difficulty: 'muy_facil' },
  { name: 'Digitación de formularios', desc: 'Digitar 200 formularios de seguros.', hp: 60, reward: 150, difficulty: 'facil' },
  { name: 'Clasificación de archivos', desc: 'Clasificar 500 archivos por categoría y fecha.', hp: 60, reward: 180, difficulty: 'facil' },
  { name: 'Traducción de documentos', desc: 'Traducir 10 documentos legales al español.', hp: 60, reward: 200, difficulty: 'facil' },
  { name: 'Soporte técnico', desc: 'Dar soporte técnico por teléfono a clientes.', hp: 60, reward: 220, difficulty: 'facil' },
  { name: 'Revisión de facturas', desc: 'Revisar 150 facturas por errores.', hp: 60, reward: 250, difficulty: 'facil' },
  { name: 'Copia de documentos', desc: 'Digitalizar 300 documentos con scanner.', hp: 150, reward: 400, difficulty: 'normal' },
  { name: 'Inventario de almacén', desc: 'Inventariar productos del almacén.', hp: 150, reward: 450, difficulty: 'normal' },
  { name: 'Procesamiento de nóminas', desc: 'Calcular nóminas de 50 empleados.', hp: 150, reward: 550, difficulty: 'normal' },
  { name: 'Help Desk interno', desc: 'Resolver tickets de soporte interno.', hp: 150, reward: 500, difficulty: 'normal' },
  { name: 'Redacción de cartas', desc: 'Redactar 50 cartas comerciales.', hp: 150, reward: 600, difficulty: 'normal' },
  { name: 'Archivo de correspondencia', desc: 'Archivar 400 cartas y documentos.', hp: 300, reward: 800, difficulty: 'dificil' },
  { name: 'Base de datos de clientes', desc: 'Crear BD de 200 clientes en Access.', hp: 300, reward: 1000, difficulty: 'dificil' },
  { name: 'Revisión de impresiones', desc: 'Revisar documentos impresos por erratas.', hp: 300, reward: 900, difficulty: 'dificil' },
  { name: 'Base de datos Access', desc: 'Crear sistema de inventario para empresa local.', hp: 300, reward: 1200, difficulty: 'dificil' },
  { name: 'Página web corporativa', desc: 'Diseño de sitio web con HTML y tablas.', hp: 300, reward: 1500, difficulty: 'dificil' },
  { name: 'Reporte de nóminas', desc: 'Sistema de nómina en hoja de cálculo.', hp: 550, reward: 2500, difficulty: 'muy_dificil' },
  { name: 'Presentación multimedia', desc: 'Diapositivas con animaciones y transiciones.', hp: 550, reward: 3000, difficulty: 'muy_dificil' },
  { name: 'Soporte de red', desc: 'Configurar red local entre 5 computadoras.', hp: 550, reward: 3500, difficulty: 'muy_dificil' },
  { name: 'App de inventario', desc: 'Programa de control de stock en Visual Basic.', hp: 550, reward: 5000, difficulty: 'muy_dificil' },
  { name: 'Compilador básico', desc: 'Crear compilador para lenguaje simple.', hp: 850, reward: 7000, difficulty: 'extremo' },
  { name: 'Servidor web', desc: 'Montar servidor HTTP con scripts CGI.', hp: 850, reward: 8500, difficulty: 'extremo' },
  { name: 'Motor de búsqueda', desc: 'Indexador de páginas web con arañas.', hp: 850, reward: 10000, difficulty: 'extremo' },
  { name: 'Sistema de facturación', desc: 'Generador de facturas con base de datos.', hp: 1100, reward: 8000, difficulty: 'pesadilla' },
  { name: 'Conversor de formatos', desc: 'Herramienta para convertir archivos entre formatos.', hp: 1100, reward: 10000, difficulty: 'pesadilla' },
  { name: 'Editor de código fuente', desc: 'IDE con resaltado de sintaxis.', hp: 1500, reward: 15000, difficulty: 'inframundo' },
  { name: 'Cliente de correo', desc: 'Cliente SMTP/POP3 con interfaz gráfica.', hp: 1500, reward: 18000, difficulty: 'inframundo' },
  { name: 'Antivirus', desc: 'Escáner de virus con firmas actualizadas.', hp: 1500, reward: 22000, difficulty: 'inframundo' },
  { name: 'Sistema operativo', desc: 'Kernel con multitarea y sistema de archivos.', hp: 1800, reward: 30000, difficulty: 'infierno' },
  { name: 'Base de datos relacional', desc: 'Motor SQL completo con transacciones.', hp: 1800, reward: 35000, difficulty: 'infierno' },
  { name: 'Navegador web', desc: 'Navegador con motor de render HTML 3.2.', hp: 1800, reward: 40000, difficulty: 'infierno' },
];

export const PROJECT_DAYS = 14;
