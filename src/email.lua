local Email = {}
Email.__index = Email

local WindowManager = require("src.window")

local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    titleText = {1, 1, 1},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    text = {0, 0, 0},
    textDim = {0.4, 0.4, 0.4},
    white = {1, 1, 1},
    fieldBg = {1, 1, 1},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    green = {0, 0.5, 0},
    red = {0.8, 0, 0},
    yellow = {0.8, 0.6, 0},
    link = {0, 0, 0.8},
}

local allEmails = {
    {subject = "Proyecto: Digitacion de formularios", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos digitar 200 formularios\npara una empresa de seguros.\n\nRequisitos:\n- Velocidad de digitacion\n- Atencion al detalle\n- Sin errores de tipeo\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Digitacion de formularios", desc = "Digitar 200 formularios\nde seguros.", hp = 80, days = 14, reward = 50}},
    {subject = "NOTICIAS: Windows 95 supera ventas", sender = "press@microsoft.com", type = "news", body = "Windows 95 vende mas de 7 millones\nde copias en sus primeros 5 meses.\nMicrosoft celebra el exito\ncon nuevas actualizaciones."},
    {subject = "Driver de refrigeracion", sender = "drivers@cooling.com", type = "beneficial", body = "Descargue el driver actualizado\npara su sistema de refrigeracion.\nMejora el control de ventiladores\ny reduce el ruido del PC."},
    {subject = "Proyecto: Clasificacion de archivos", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos clasificar 500 archivos\npor categoria y fecha.\n\nRequisitos:\n- Orden alfabetico\n- Clasificar por tipo\n- Crear indice\n\nRecompensa: $55\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Clasificacion de archivos", desc = "Clasificar 500 archivos\npor categoria y fecha.", hp = 85, days = 14, reward = 55}},
    {subject = "NOTICIAS: Netscape Navigator 2.0", sender = "press@netscape.com", type = "news", body = "Netscape lanza Navigator 2.0,\ncon soporte para Java y\nframes. El navegador mas\npopular del mundo."},
    {subject = "Disco duro IDE 1.2GB - $99", sender = "ofertas@compumail.com", type = "ad", body = "Disco duro IDE 1.2GB por solo $99!\nOferta por tiempo limitado.\nLlame al 555-0123."},
    {subject = "Proyecto: Traduccion de documentos", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos traductor ingles-espanol\npara 10 documentos legales.\n\nRequisitos:\n- Dominio del ingles\n- Terminologia legal\n- Formato original\n\nRecompensa: $65\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Traduccion de documentos", desc = "Traducir 10 documentos\nlegales al espanol.", hp = 95, days = 14, reward = 65}},
    {subject = "NOTICIAS: CompuServe ofrece acceso a Internet", sender = "noticias@tech.com", type = "news", body = "CompuServe lanza servicio\nde acceso a Internet.\nNavegacion y correo electronico\nincluidos. Competencia directa\ncon America Online."},
    {subject = "Impresoras Matriciales $49", sender = "ventas@printers.com", type = "ad", body = "Impresoras Matriciales desde $49!\nEnvio gratis a todo el pais.\nVisite nuestra tienda en linea."},
    {subject = "Proyecto: Soporte tecnico telefónico", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos personal para soporte\ntecnico por telefono.\n\nRequisitos:\n- Conocimiento de Windows\n- Paciencia con clientes\n- Solucionar problemas basicos\n\nRecompensa: $60\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Soporte tecnico", desc = "Dar soporte tecnico\npor telefono a clientes.", hp = 90, days = 14, reward = 60}},
    {subject = "NOTICIAS: OJ Simpson - juicio del siglo", sender = "noticias@cnn.com", type = "news", body = "El juicio a OJ Simpson comienza\nen Los Angeles. El caso ha captado\nla atencion de todo el pais.\nCobertura en vivo por CNN."},
    {subject = "Monitor CRT 15\" - oferta", sender = "monitores@techshop.com", type = "ad", body = "Monitor CRT 15 pulgadas SVGA\npor solo $189. Envio incluido.\nUltimas unidades disponibles."},
    {subject = "Proyecto: Revision de facturas", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos revisar 150 facturas\npara detectar errores.\n\nRequisitos:\n- Atencion a numeros\n- Verificar impuestos\n- Reportar discrepancias\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Revision de facturas", desc = "Revisar 150 facturas\npor errores.", hp = 75, days = 14, reward = 50}},
    {subject = "NOTICIAS: Windows 95 supera ventas", sender = "noticias@tech.com", type = "news", body = "Windows 95 vende mas de 7 millones\nde copias en sus primeros 5 meses.\nMicrosoft celebra el exito\ncon nuevas actualizaciones."},
    {subject = "Tarjetas de-video Cirrus Logic", sender = "tarjetas@pcshop.com", type = "ad", body = "Tarjetas de video Cirrus Logic\n5430 desde $79. Compatibles\ncon Windows 95 y DOS."},
    {subject = "Proyecto: Copia de documentos", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos copiar 300 documentos\na formato digital.\n\nRequisitos:\n- Scanner funcionando\n- Organizar por carpetas\n- Nombres correctos\n\nRecompensa: $55\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Copia de documentos", desc = "Digitalizar 300 documentos\ncon scanner.", hp = 85, days = 14, reward = 55}},
    {subject = "NOTICIAS: Titanic - taquilla historica", sender = "noticias@hollywood.com", type = "news", body = "Titanic de James Cameron rompe\nrecords en taquilla, superando\nlos $600 millones en EE.UU.\nLa pelicula mas exitosa de todos\nlos tiempos en ese momento."},
    {subject = "Disquetes 3.5\" x 50 - $12", sender = "disquetes@supplies.com", type = "ad", body = "Paquete de 50 disquetes 3.5\"\ndensidad alta por solo $12.\nEnvio por correo incluido."},
    {subject = "Proyecto: Inventario de almacen", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos inventariar todo\nel almacen de la empresa.\n\nRequisitos:\n- Contar productos\n- Registrar cantidades\n- Crear hoja de calculo\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Inventario de almacen", desc = "Inventariar productos\ndel almacen.", hp = 70, days = 14, reward = 50}},
    {subject = "NOTICIAS: Princesa Diana - fin de la monarquia", sender = "noticias@bbc.com", type = "news", body = "La princesa Diana anuncia su\nseparacion del principe Carlos.\nEl divorcio mas esperado del siglo\nen la monarquia britanica."},
    {subject = "Mouse Genius optico $8", sender = "mouse@pcparts.com", type = "ad", body = "Mouse Genius optico serial\npor solo $8. Precision de\n800 DPI. Color gris."},
    {subject = "Proyecto: Procesamiento de nominas", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos procesar las nominas\nde 50 empleados.\n\nRequisitos:\n- Calcular deducciones\n- Generar recibos\n- Entregar en tiempo\n\nRecompensa: $70\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Procesamiento de nominas", desc = "Calcular nominas de\n50 empleados.", hp = 100, days = 14, reward = 70}},
    {subject = "NOTICIAS: Internet crece 2300%", sender = "noticias@wired.com", type = "news", body = "El uso de Internet crece un 2300%\nen 1995. Mas de 16 millones\nde personas tienen acceso.\nEl correo electronico se vuelve\nel metodo de comunicacion favorito."},
    {subject = "Grabadora CD-ROM $299", sender = "cdrom@techstore.com", type = "ad", body = "Grabadora CD-ROM 2x por\nsolo $299. Grabe sus propios\ndiscos en casa! Oferta especial."},
    {subject = "Proyecto: Help Desk interno", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos persona para Help Desk\ninterno de la empresa.\n\nRequisitos:\n- Conocimiento de redes\n- Resolver tickets\n- Documentar soluciones\n\nRecompensa: $65\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Help Desk interno", desc = "Resolver tickets de soporte\ninterno.", hp = 95, days = 14, reward = 65}},
    {subject = "NOTICIAS: DVD - el futuro del entretenimiento", sender = "noticias@tech.com", type = "news", body = "Los primeros reproducores DVD\nllegan a las tiendas. El formato\nalmacena 4.7GB por disco.\nLa era del VHS termina.\nPrecio: $500 el reproducor."},
    {subject = "Carpeta compartida C$", sender = "hacker@anon.com", type = "malware", body = "Acceda a carpetas compartidas\nde otros usuarios. Herramienta\ninclusa en el archivo adjunto.", moneyLoss = 55},
    {subject = "Modem 56K USRobotics $89", sender = "modems@dialup.com", type = "ad", body = "Modem 56K USRobotics Sportster\npor solo $89. Navegue a toda\nvelocidad por Internet!"},
    {subject = "Proyecto: Redaccion de cartas", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos redactar 50 cartas\ncomerciales para clientes.\n\nRequisitos:\n- Redaccion formal\n- Sin errores ortograficos\n- Formato profesional\n\nRecompensa: $55\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Redaccion de cartas", desc = "Redactar 50 cartas\ncomerciales.", hp = 80, days = 14, reward = 55}},
    {subject = "NOTICIAS: AltaVista - buscador mas popular", sender = "noticias@tech.com", type = "news", body = "AltaVista se convierte en el\nbuscador mas usado de Internet.\nIndexa mas de 30 millones\nde paginas web. El motor de\nbusqueda por excelencia."},
    {subject = "Serial de WinZip 6.3", sender = "serials@shareware.com", type = "malware", body = "Serial completo para WinZip 6.3.\nCopie y pegue durante la\ninstalacion para activar.", moneyLoss = 10},
    {subject = "Disquete ZIP 100MB $49", sender = "zip@storage.com", type = "ad", body = "Disquetes ZIP Iomega 100MB\npor solo $49. El futuro\ndel almacenamiento portatil."},
    {subject = "Scanner HP ScanJet $149", sender = "scanner@hpshop.com", type = "ad", body = "Scanner HP ScanJet 3100C\npor solo $149. Resolucion\n600x1200 dpi. Incluye software."},
    {subject = "Proyecto: Archivo de correspondencia", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos archivar 400 cartas\ny documentos entrada.\n\nRequisitos:\n- Ordenar por fecha\n- Clasificar por remitente\n- Crear indice\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Archivo de correspondencia", desc = "Archivar 400 cartas\ny documentos.", hp = 70, days = 14, reward = 50}},
    {subject = "NOTICIAS: AOL alcanza 8 millones", sender = "noticias@aol.com", type = "news", body = "America Online supera los 8 millones\nde suscriptores en 1997.\nEl servicio de internet por\nmarcador domina el mercado.\n'You've got mail!' se vuelve iconico."},
    {subject = "Turbo Pascal gratis", sender = "free@programming.com", type = "malware", body = "Turbo Pascal 7.0 completo.\nIdeal para aprender a programar.\nDescargue el instalador.", moneyLoss = 8},
    {subject = "Teclado IBM Model M $35", sender = "teclados@retro.com", type = "ad", body = "Teclado IBM Model M mecanico\npor solo $35. El mejor teclado\njamas fabricado. Aproveche!"},
    {subject = "NOTICIAS: Sony PlayStation llega a EE.UU.", sender = "noticias@gaming.com", type = "news", body = "Sony lanza la PlayStation\nen Estados Unidos a $299.\n32 bits de potencia grafica.\nLa consola que cambiara\nlos videojuegos para siempre."},
    {subject = "Proyecto: Base de datos de clientes", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos crear una base de datos\nde 200 clientes en Access.\n\nRequisitos:\n- Formulario de entrada\n- Busqueda rapida\n- Reportes basicos\n\nRecompensa: $65\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Base de datos de clientes", desc = "Crear BD de 200 clientes\nen Access.", hp = 95, days = 14, reward = 65}},
    {subject = "Buenas noticias!", sender = "noticias@buenas.com", type = "malware", body = "Usted ha sido seleccionado\npara recibir un regalo especial.\nHaga clic en el enlace adjunto.", moneyLoss = 30},
    {subject = "CD-ROM enciclopedia $29", sender = "cdrom@edu.com", type = "ad", body = "Enciclopedia Microsoft Encarta\n97 en CD-ROM por solo $29.\nMas de 1 million de articulos!"},
    {subject = "Proyecto: Revision de impresiones", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos revisor de documentos\nimpresos para deteccion de erratas.\n\nRequisitos:\n- Atencion al detalle\n- Conocimiento de ortografia\n- Rapidez visual\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Revision de impresiones", desc = "Revisar documentos\nimpresos por erratas.", hp = 70, days = 14, reward = 50}},
    {subject = "NOTICIAS: Juegos Olimpicos Atlanta 96", sender = "noticias@olympics.com", type = "news", body = "Atlanta 1996: EE.UU. gana 101 medallas\nen los Juegos Olimpicos de verano.\nMichael Johnson rompe record\nmundial en 200 metros."},
    {subject = "Patch de DirectX gratis", sender = "drivers@microsoft.com", type = "beneficial", body = "Descargue el parche de DirectX 5.0\npara mejorar el rendimiento\nde sus juegos en Windows 95.\nCompatibilidad mejorada."},
    {subject = "Pantallazo azul - solucion", sender = "soporte@microsoft.com", type = "beneficial", body = "Si su PC muestra el error\nde pantalla azul, descargue\nesta herramienta de recuperacion.\nRepara archivos de sistema corruptos."},
    {subject = "Anti-spam para Outlook", sender = "seguridad@microsoft.com", type = "beneficial", body = "Proteja su correo contra spam.\nDescargue el filtro anti-spam\ncompatible con Windows 95.\nMantiene su bandeja limpia."},
    {subject = "Driver de impresora HP", sender = "drivers@hp.com", type = "beneficial", body = "Driver actualizado para impresoras\nHP LaserJet 4. Mejora la calidad\ny velocidad de impresion.\nCompatible con Windows 95."},
    {subject = "Compresor de archivos", sender = "tools@shareware.com", type = "beneficial", body = "Herramienta de compresion\nde archivos rapida y segura.\nAhorre espacio en su disco duro.\nCompatible con ZIP, RAR, TAR."},
    {subject = "Proteccion contra virus", sender = "seguridad@mcafee.com", type = "beneficial", body = "Descargue la base de datos\nactualizada de McAfee VirusScan.\nProteja su PC de las ultimas\namenazas de virus conocidas."},
    {subject = "Optimizador de Windows", sender = "tools@norton.com", type = "beneficial", body = "Norton Utilities incluye\nherramientas para limpiar\ny optimizar su Windows 95.\nMejore el rendimiento de su PC."},
    {subject = "Backup de archivos", sender = "tools@stac.com", type = "beneficial", body = "Herramienta gratuita de respaldo\npara Windows 95. Copie sus archivos\nimportantes a disquetes o cinta.\nNo pierda sus datos nunca mas."},
    {subject = "Traductor de paginas web", sender = "tools@altavista.com", type = "beneficial", body = "Descargue el traductor de\nAltaVista para paginas web.\nTraduzca ingles a espanol\nautomaticamente en su navegador."},
    {subject = "Organizador de contactos", sender = "tools@ziff.com", type = "beneficial", body = "Ziff-Davis Contact Manager\nle ayuda a organizar sus\ncontactos y numeros de telefono.\nBusqueda rapida y exportacion."},
    {subject = "Reproductor multimedia", sender = "tools@real.com", type = "beneficial", body = "RealPlayer para Windows 95.\nEscuche radios y vea videos\npor Internet. Primera version\nde streaming multimedia."},
    {subject = "Lector de PDF", sender = "tools@adobe.com", type = "beneficial", body = "Adobe Acrobat Reader 3.0.\nDescargue y lea archivos PDF\nen su PC con Windows 95.\nGratis y sin licencia."},
    {subject = "Proteccion de privacidad", sender = "seguridad@microsoft.com", type = "beneficial", body = "Herramienta de Microsoft para\nproteger su informacion personal\nmientras navega por Internet.\nBloquea rastreadores y cookies."},
    {subject = "NOTICIAS: Pentium Pro disponible", sender = "noticias@tech.com", type = "news", body = "Intel lanza el Pentium Pro,\nnuevo procesador de 200MHz\ncon cache integrado.\nRendimiento sin precedentes\npara estaciones de trabajo."},
    {subject = "NOTICIAS: USB 1.0 - futuro de la conectividad", sender = "noticias@tech.com", type = "news", body = "El estandar USB 1.0 es anunciado\npor Intel, Compaq y Microsoft.\nVelocidad de 12 Mbps.\nEl futuro de la conexion\nde perifericos al PC."},
    {subject = "NOTICIAS: Mars Pathfinder aterriza", sender = "noticias@nasa.com", type = "news", body = "NASA aterriza exitosamente\nel Pathfinder en Marte.\nEl rover Sojourner explora\nla superficie marciana.\nExito de la ciencia espacial."},
    {subject = "NOTICIAS: Apple presenta el iMac", sender = "noticias@tech.com", type = "news", body = "Apple Computer presenta el iMac,\ncomputador todo en uno de color\nazul traslucido. Diseno revolucionario\ny puerto USB. Steve Jobs regresa\nal poder en Apple."},
    {subject = "NOTICIAS: ICQ - messenger en linea", sender = "noticias@tech.com", type = "news", body = "ICQ supera los 5 millones\nde usuarios. El programa de\nmensajeria instantanea mas\npopular de Internet.\n'Mensajeria en tiempo real'."},
    {subject = "NOTICIAS: Nintendo 64 - consolea del futuro", sender = "noticias@gaming.com", type = "news", body = "Nintendo 64 supera las\nexpectativas de ventas.\nSuper Mario 64 revoluciona\nlos juegos en 3D.\nLa guerra de consolas arde."},
    {subject = "NOTICIAS: Apple casi quiebra", sender = "noticias@tech.com", type = "news", body = "Apple Computer esta al borde\nde la quiebra. Steve Jobs regresa\ncomo CEO interino. La empresa\nbusca inversores para sobrevivir.\nEl futuro de Apple es incierto."},
    {subject = "Proyecto: Base de datos de inventario", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos a alguien para crear\nuna base de datos de inventario\npara una empresa local.\n\nRequisitos:\n- Microsoft Access\n- Formularios de entrada\n- Reportes automaticos\n\nRecompensa: $80\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Base de datos Access", desc = "Crear sistema de inventario\npara empresa local.", hp = 100, days = 14, reward = 80}},
    {subject = "Proyecto: Pagina web corporativa", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos una pagina web\ncorporativa para nuestra empresa.\n\nRequisitos:\n- HTML basico\n- Tablas de contenido\n- Formulario de contacto\n\nRecompensa: $100\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Pagina web corporativa", desc = "Diseno de sitio web\ncon HTML y tablas.", hp = 120, days = 14, reward = 100}},
    {subject = "Proyecto: Reporte de nominas", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos un sistema de nomina\nen hoja de calculo.\n\nRequisitos:\n- Formulas automaticas\n- Calculo de impuestos\n- Impresion de recibos\n\nRecompensa: $60\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Reporte de nominas", desc = "Sistema de nomina\nen Hoja de calculo.", hp = 80, days = 14, reward = 60}},
    {subject = "Proyecto: Presentacion multimedia", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos a alguien para crear\nuna presentacion multimedia.\n\nRequisitos:\n- Diapositivas con imagenes\n- Animaciones y transiciones\n- Sonido de fondo\n\nRecompensa: $70\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Presentacion multimedia", desc = "Slides con animaciones\ny transiciones.", hp = 90, days = 14, reward = 70}},
    {subject = "Proyecto: Configuracion de red", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos configurar una\nred local de 5 computadoras.\n\nRequisitos:\n- Cableado de red\n- Configuracion TCP/IP\n- Compartir impresora\n\nRecompensa: $90\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Soporte de red", desc = "Configurar red local\nentre 5 computadoras.", hp = 110, days = 14, reward = 90}},
    {subject = "Proyecto: App de inventario VB", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nRequerimos una aplicacion\nde control de stock en VB.\n\nRequisitos:\n- Visual Basic 3.0\n- Base de datos Jet\n- Interfaz grafica\n\nRecompensa: $120\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "App de inventario", desc = "Programa de control\nde stock en Visual Basic.", hp = 140, days = 14, reward = 120}},
    {subject = "Proyecto: Sistema de facturacion", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nBuscamos un sistema de facturacion.\n\nRequisitos:\n- Generador de facturas\n- Base de datos de clientes\n- Reportes mensuales\n\nRecompensa: $110\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Sistema de facturacion", desc = "Generador de facturas\ncon base de datos.", hp = 130, days = 14, reward = 110}},
    {subject = "Proyecto: Conversor de formatos", sender = "clientes@freelance.com", type = "project", body = "Estimado freelancer:\n\nNecesitamos una herramienta\npara convertir archivos.\n\nRequisitos:\n- Convertir TXT a DOC\n- Convertir BMP a JPG\n- Interfaz simple\n\nRecompensa: $50\nPlazo: 14 días\n\nResponda para aceptar el proyecto.", projectData = {name = "Conversor de formatos", desc = "Herramienta para convertir\narchivos entre formatos.", hp = 70, days = 14, reward = 50}},
    {subject = "NOTICIAS: Windows 98 - la nueva era", sender = "press@microsoft.com", type = "news", body = "Microsoft anuncia Windows 98,\nnueva version con mejoras\nen Internet Explorer 4.0,\nsoporte USB y FAT32.\nLanzamiento: junio de 1998."},
}

function Email.new(x, y)
    local self = setmetatable({}, Email)
    self.window = WindowManager.new("Correo Electronico", x or 180, y or 90, 620, 500)

    self.inbox = {}
    self.selectedEmail = nil
    self.selectedIndex = 0
    self.lastMX = 0
    self.lastMY = 0
    self.trabajoRef = nil
    self.notepadRef = nil
    self.emailIndex = 1
    self.pendingApplications = 0
    self.workSinceApplication = 0
    self.workThreshold = 1 + math.random(5)
    self.chimeSound = nil
    self.initialized = false
    self.smallFont = love.graphics.newFont(11)
    self.buttons = {}
    self.scrollY = 0
    self.inboxScrollY = 0
    self.maxInboxScroll = 0
    self.malwareSent = false
    self.downloadIconActive = false
    self.totalTasksDone = 0

    local ok, snd = pcall(love.audio.newSource, "assets/sounds/CHIMES.WAV", "static")
    if ok then
        self.chimeSound = snd
        self.chimeSound:setVolume(0.6)
    end

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    self.initialized = true

    local welcomeEmail = {
        subject = "Bienvenido a su nuevo puesto",
        sender = "admin@empresa.com",
        type = "news",
        body = "Estimado empleado:\n\nBienvenido a su nuevo puesto.\nLe explicaremos como funciona:\n\n1. GANAR DINERO:\nHaga click en el icono \"Trabajo\"\ny presione \"Trabajar\". Cada tarea\nle paga $1-2. Trabaje mas para\nganar mas y mejorar su PC.\n\n2. COMPRAR MEJORAS:\nAbra Internet Explorer y vaya\na \"Tienda\" en Favoritos. Ahí podra\ncomprar mejoras para su PC:\nCPU, RAM, Disco, Video,\nRefrigeracion.\n\n3. CORREO:\nRevise su correo regularmente.\nAlgunos correos son ofertas de\nproyectos con mejor recompensa.\nPero cuidado: hay correos\npeligrosos que le roban dinero.\n\n4. PROYECTOS:\nLos proyectos se resuelven por\ndias. Cada accion consume RAM.\n- GPU: daño principal\n- CPU: acciones y critico\n- RAM: maná (5 base, cuesta 2)\n- Refrigeracion: controla calor\n\n5. OBJETIVOS:\nEl Bloc de notas muestra sus\nobjetivos y progreso.\n\nSu gerente.",
        handled = true,
        read = true,
    }
    table.insert(self.inbox, welcomeEmail)
    self.selectedIndex = 1
    self.selectedEmail = welcomeEmail

    return self
end

function Email:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Email:playChime()
    if self.chimeSound and self.initialized then
        self.chimeSound:stop()
        self.chimeSound:play()
    end
end

function Email:addNextEmail()
    if self.emailIndex <= #allEmails then
        local email = allEmails[self.emailIndex]
        email.read = false
        email.handled = false
        table.insert(self.inbox, email)
        self.emailIndex = self.emailIndex + 1
        self:playChime()
    end
end

function Email:addEmailToInbox(email)
    email.read = false
    email.handled = false
    table.insert(self.inbox, email)
    self.selectedIndex = #self.inbox
    self.selectedEmail = email
    self.scrollY = 0
    self:playChime()
end

function Email:onWorkCompleted()
    self.workSinceApplication = self.workSinceApplication + 1
    self.totalTasksDone = self.totalTasksDone + 1

    if not self.malwareSent and self.totalTasksDone >= 8 then
        self.malwareSent = true
        self:addEmailToInbox({
            subject = "Descarga disponible: WinOptimizer Pro",
            sender = "downloads@freeware.com",
            type = "malware",
            body = "Hola!\n\nHemos detectado que su PC\npodria funcionar mejor.\n\nDescargue WinOptimizer Pro\npara optimizar su sistema.\n\nGratis por tiempo limitado!",
            moneyLoss = 0,
            isDesktopMalware = true,
        })
        return
    end

    if self.workSinceApplication >= self.workThreshold then
        self.workSinceApplication = 0
    self.workThreshold = 1 + math.random(10)

        if self.pendingApplications > 0 then
            self.pendingApplications = self.pendingApplications - 1
            local accepted = math.random() < 0.5
            if accepted then
                self:addEmailToInbox({
                    subject = "CV ACEPTADO - Felicidades!",
                    sender = "rrhh@empresa.com",
                    type = "news",
                    body = "Estimado candidato:\n\nSu CV ha sido aceptado.\nSe le contactara pronto para\nuna entrevista.\n\nSaludos cordiales.",
                    moneyReward = 50,
                })
                if self.trabajoRef then
                    self.trabajoRef.tabUnlocked = true
                end
            else
                self:addEmailToInbox({
                    subject = "CV Rechazado",
                    sender = "rrhh@empresa.com",
                    type = "news",
                    body = "Estimado candidato:\n\nLamentamos informarle que\nsu perfil no coincide con\nnuestras necesidades.\n\nLe deseamos exito.",
                })
            end
        else
            if self.emailIndex <= #allEmails then
                self:addNextEmail()
            end
        end
    end
end

function Email:update(dt)
end

function Email:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Email:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Email:getActionButtonText(email)
    if email.type == "job" then return "Enviar CV"
    elseif email.type == "malware" then return "Descargar"
    elseif email.type == "beneficial" then return "Descargar"
    elseif email.type == "project" then return "Aceptar"
    elseif email.type == "personal_unlock" then return "Descargar"
    else return nil
    end
end

function Email:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    local menuH = 18
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)
    local menuItems = {"Archivo", "Editar", "Ver", "Correo", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = self.smallFont:getWidth(item) + 12
        love.graphics.setColor(W95.text)
        love.graphics.print(item, mx_off, cy + 3)
        mx_off = mx_off + iw
    end

    local toolbarH = 28
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + menuH, cw, toolbarH)
    self:drawBevel(cx, cy + menuH, cw, toolbarH)

    local tbButtons = {"Nuevo", "Responder", "Reenviar", "Eliminar"}
    local tbX = cx + 4
    local tbY = cy + menuH + 3
    local tbW = 60
    local tbH = 22
    for i, label in ipairs(tbButtons) do
        local bx = tbX + (i - 1) * (tbW + 2)
        love.graphics.setColor(W95.bg)
        love.graphics.rectangle("fill", bx, tbY, tbW, tbH)
        self:drawBevel(bx, tbY, tbW, tbH)
        love.graphics.setColor(W95.text)
        love.graphics.printf(label, bx, tbY + 5, tbW, "center")
    end

    local listY = cy + menuH + toolbarH
    local listH = 140
    local listW = cw

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, listY, listW, listH)
    self:drawInset(cx, listY, listW, listH)

    local colW = {20, cw - 100, 80}
    local headers = {"", "Asunto", "De"}
    local headerY = listY + 2

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 2, headerY, listW - 4, 16)

    local hx = cx + 6
    for i, header in ipairs(headers) do
        love.graphics.setColor(W95.text)
        love.graphics.print(header, hx, headerY + 2)
        hx = hx + colW[i]
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 4, headerY + 16, cx + listW - 4, headerY + 16)

    local inboxContentY = headerY + 18
    local inboxContentH = listH - 20
    local totalInboxH = #self.inbox * 18
    self.maxInboxScroll = math.max(0, totalInboxH - inboxContentH)

    love.graphics.setScissor(cx + 2, inboxContentY, listW - 4, inboxContentH)
    for i, email in ipairs(self.inbox) do
        local ey = inboxContentY + (i - 1) * 18 + self.inboxScrollY
        if ey + 18 < inboxContentY or ey > inboxContentY + inboxContentH then

        else
        local isSelected = (i == self.selectedIndex)
        local mx, my = love.mouse.getPosition()
        local isHovered = mx >= cx + 2 and mx <= cx + listW - 2 and my >= ey and my <= ey + 17

        if isSelected then
            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", cx + 2, ey, listW - 4, 17)
            love.graphics.setColor(W95.highlightText)
        elseif isHovered then
            love.graphics.setColor({0.85, 0.85, 0.85})
            love.graphics.rectangle("fill", cx + 2, ey, listW - 4, 17)
            love.graphics.setColor(W95.text)
        else
            love.graphics.setColor(email.read and W95.textDim or W95.text)
        end

        local ex = cx + 6
        love.graphics.print(email.handled and "  " or " * ", ex, ey + 1)
        ex = ex + colW[1]
        love.graphics.print(email.subject, ex, ey + 1)
        ex = ex + colW[2]
        love.graphics.print(email.sender, ex, ey + 1)

        table.insert(self.buttons, {x = cx + 2, y = ey, w = listW - 4, h = 17, action = "select", index = i})
        end
    end
    love.graphics.setScissor()

    if self.maxInboxScroll > 0 then
        local scrollBarX = cx + listW - 14
        local scrollBarY = inboxContentY
        local scrollBarH = inboxContentH
        local thumbH = math.max(20, scrollBarH * (inboxContentH / totalInboxH))
        local thumbY = scrollBarY + (-self.inboxScrollY / self.maxInboxScroll) * (scrollBarH - thumbH)

        love.graphics.setColor({0.7, 0.7, 0.7})
        love.graphics.rectangle("fill", scrollBarX, scrollBarY, 10, scrollBarH)
        love.graphics.setColor({0.5, 0.5, 0.5})
        love.graphics.rectangle("fill", scrollBarX, thumbY, 10, thumbH)
    end

    local contentY = listY + listH + 4
    local contentH = ch - menuH - toolbarH - listH - 50

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx + 2, contentY, cw - 4, contentH)
    self:drawInset(cx + 2, contentY, cw - 4, contentH)

    if self.selectedEmail then
        local email = self.selectedEmail

        love.graphics.setColor(W95.text)
        love.graphics.print("De: " .. email.sender, cx + 8, contentY + 6)
        love.graphics.print("Asunto: " .. email.subject, cx + 8, contentY + 20)

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(cx + 8, contentY + 36, cx + cw - 10, contentY + 36)

        local lines = {}
        for line in email.body:gmatch("[^\n]*") do
            table.insert(lines, line)
        end

        local lineH = 14
        local bodyY = contentY + 40
        local bodyH = contentH - 44
        local totalTextH = #lines * lineH
        self.maxScroll = math.max(0, totalTextH - bodyH)

        love.graphics.setScissor(cx + 2, bodyY, cw - 4, bodyH)
        for j, line in ipairs(lines) do
            local ly = bodyY + (j - 1) * lineH + self.scrollY
            love.graphics.setColor(W95.text)
            love.graphics.print(line, cx + 10, ly)
        end
        love.graphics.setScissor()

        if not email.handled then
            local btnY = contentY + contentH - 28
            local btnW = 90
            local btnH = 22
            local actionText = self:getActionButtonText(email)

            if actionText then
                local actionX = cx + cw - btnW * 2 - 16
                local mx, my = love.mouse.getPosition()
                local actionHov = mx >= actionX and mx <= actionX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(actionHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", actionX, btnY, btnW, btnH)
                self:drawBevel(actionX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf(actionText, actionX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = actionX, y = btnY, w = btnW, h = btnH, action = "download"})

                local deleteX = cx + cw - btnW - 8
                local delHov = mx >= deleteX and mx <= deleteX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(delHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", deleteX, btnY, btnW, btnH)
                self:drawBevel(deleteX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf("Eliminar", deleteX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = deleteX, y = btnY, w = btnW, h = btnH, action = "delete"})
            else
                local deleteX = cx + cw - btnW - 8
                local mx, my = love.mouse.getPosition()
                local delHov = mx >= deleteX and mx <= deleteX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(delHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", deleteX, btnY, btnW, btnH)
                self:drawBevel(deleteX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf("Eliminar", deleteX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = deleteX, y = btnY, w = btnW, h = btnH, action = "delete"})
            end
        else
            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Correo procesado", cx + 8, contentY + contentH - 20, cw - 16, "center")
        end
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Seleccione un correo para leer", cx + 8, contentY + contentH / 2 - 6, cw - 16, "center")
    end

    local statusH = 20
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + ch - statusH, cw, statusH)
    self:drawBevel(cx, cy + ch - statusH, cw, statusH)
    love.graphics.setColor(W95.text)
    local unread = 0
    for _, e in ipairs(self.inbox) do
        if not e.read then unread = unread + 1 end
    end
    love.graphics.print("  Correos: " .. #self.inbox .. "  |  No leidos: " .. unread, cx + 4, cy + ch - statusH + 4)

    love.graphics.setFont(prevFont)
end

function Email:handleClick(x, y, button)
    if button ~= 1 then return false end
    if not self.window.visible then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "select" then
                self.selectedIndex = btn.index
                self.selectedEmail = self.inbox[btn.index]
                self.scrollY = 0
                if self.selectedEmail then
                    self.selectedEmail.read = true
                end
            elseif btn.action == "download" and self.selectedEmail and not self.selectedEmail.handled then
                self.selectedEmail.handled = true
                if self.selectedEmail.type == "job" and self.selectedEmail.moneyReward and self.trabajoRef then
                    self.trabajoRef.money = self.trabajoRef.money + self.selectedEmail.moneyReward
                    self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + self.selectedEmail.moneyReward
                    self.pendingApplications = self.pendingApplications + 1
                    self.workSinceApplication = 0
    self.workThreshold = 1 + math.random(10)
                    if self.notepadRef then
                        self.notepadRef.emailJobsAccepted = (self.notepadRef.emailJobsAccepted or 0) + 1
                    end
                elseif self.selectedEmail.type == "malware" and self.selectedEmail.isDesktopMalware then
                    self.downloadIconActive = true
                    if self.notepadRef then
                        self.notepadRef.malwareDownloaded = (self.notepadRef.malwareDownloaded or 0) + 1
                    end
                elseif self.selectedEmail.type == "malware" and self.selectedEmail.moneyLoss and self.selectedEmail.moneyLoss > 0 and self.trabajoRef then
                    self.trabajoRef.money = math.max(0, self.trabajoRef.money - self.selectedEmail.moneyLoss)
                    if self.notepadRef then
                        self.notepadRef.malwareDownloaded = (self.notepadRef.malwareDownloaded or 0) + 1
                    end
                elseif self.selectedEmail.type == "project" and self.selectedEmail.projectData and self.trabajoRef then
                    if not self.trabajoRef.activeProject then
                        self.trabajoRef.tabUnlocked = true
                        self.trabajoRef:startProject(self.selectedEmail.projectData)
                    end
                elseif self.selectedEmail.type == "personal_unlock" then
                    self.selectedEmail.handled = true
                    if self.notepadRef then
                        self.notepadRef.personalReady = true
                    end
                end
            elseif btn.action == "delete" and self.selectedEmail and not self.selectedEmail.handled then
                self.selectedEmail.handled = true
                if self.notepadRef then
                    self.notepadRef.emailsDeleted = (self.notepadRef.emailsDeleted or 0) + 1
                    if self.selectedEmail.type == "malware" then
                        self.notepadRef.malwareDeleted = (self.notepadRef.malwareDeleted or 0) + 1
                    end
                end
            end
            return true
        end
    end
    return false
end

function Email:draw(mx, my)
    self.lastMX = mx
    self.lastMY = my
    self.window:drawFrame()
end

function Email:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Email:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Email:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Email:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

function Email:wheelmoved(x, y)
    if not self.window.visible or self.window.minimized then return end
    local mx, my = love.mouse.getPosition()
    local cx, cy, cw, ch = self.window:getContentArea()
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
        local menuH = 18
        local toolbarH = 28
        local inboxY = cy + menuH + toolbarH
        local inboxH = 140

        if my >= inboxY and my <= inboxY + inboxH then
            self.inboxScrollY = self.inboxScrollY + y * 18
            if self.inboxScrollY > 0 then self.inboxScrollY = 0 end
            if self.maxInboxScroll and self.inboxScrollY < -self.maxInboxScroll then
                self.inboxScrollY = -self.maxInboxScroll
            end
        else
            self.scrollY = self.scrollY + y * 20
            if self.scrollY > 0 then self.scrollY = 0 end
            if self.maxScroll and self.scrollY < -self.maxScroll then
                self.scrollY = -self.maxScroll
            end
        end
    end
end

return Email
