# GameVibeStory — Documento de Diseño

## Concepto

Un incremental de nostalgia: empiezas con un PC viejo con Windows 95 en un garaje y terminas con Windows 11 y agentes de IA que trabajan por ti. **La evolución del sistema operativo ES el contenido**: cada instalación cambia el escritorio, los sonidos, las apps disponibles y, sobre todo, **las reglas del juego**.

### Pilares

1. **Cada era cambia cómo juegas**, no solo los números.
2. **La nostalgia es la recompensa**: arranque, sonido, wallpaper y apps nuevas al instalar un sistema.
3. **De hacer clic a mirar**: lo que haces a mano en una era lo automatizas en la siguiente, con la herramienta real de esa época.
4. **El PC es tu árbol de mejoras**: el hardware que compras es lo que te deja instalar el siguiente sistema.

> **Nombres**: si el juego se publica, usar nombres de parodia (p. ej. "Ventanas 95", "Ventanas XP"...). En este documento se usan los nombres reales como referencia.

---

## Las 6 eras

| # | Era | Años | Fantasía | Mecánica nueva | Automatización | Peligro de la era |
|---|-----|------|----------|----------------|----------------|-------------------|
| 1 | **95** | 1995–2000 | Freelancer en el garaje | Tareas freelance + proyectos con componentes | Macros y `.bat` (WinBatch) | Pantallazo azul (BSOD) |
| 2 | **XP** | 2001–2008 | Llega la banda ancha | **Red de contactos** (Messenger) que trae clientes | VBScript + Programador de tareas | Virus/gusanos que se propagan por tus contactos |
| 3 | **7** | 2009–2012 | Creador de contenido | **Audiencia**: blog, videos, seguidores | PowerShell | Phishing y cuentas hackeadas |
| 4 | **8** | 2012–2015 | Todo cambia de golpe | **Mosaicos vivos** + tienda de apps móviles | Apps de la tienda | Tus automatizaciones se rompen con la nueva interfaz |
| 5 | **10** | 2015–2021 | Empresa en la nube | **Suscripciones (SaaS)** y reparto de la GPU | Servidores en la nube / bots | Windows Update reinicia en el peor momento |
| 6 | **11** | 2021– | La IA hace todo | **Agentes de IA** que manejan cada app | Agentes autónomos | Alucinaciones de la IA sin supervisión |

### Era 1 — Windows 95: "El garaje"

- **Lo que ya existe**: Trabajo (freelance + proyectos particulares con círculos de GPU/CPU/RAM/Refrigeración), Coding (shareware con ingreso mensual), Email (encargos), Explorer (tienda de apps y música), Winamp, Personal, Logros.
- **Mecánica principal**: clic en tareas → dinero → mejorar componentes → proyectos más difíciles.
- **Riesgo/recompensa — Overclock**: subir el overclock aumenta las ganancias, pero también la probabilidad de **BSOD**, que cancela el proyecto en curso. Es una apuesta: "¿lo fuerzo un poco más?".
- **Automatización**: WinBatch permite grabar una secuencia de tareas y repetirla sola.
- **Mejora de mitad de era**: paquete **Plus!**, que trae temas de escritorio y +10 % de velocidad.
- **Evento**: "¡Viene el jefe!": ventana de 5 s para abrir el Buscaminas. Si fallas, pierdes el encargo actual.

### Era 2 — Windows XP: "Conectado"

- **Recurso nuevo: Contactos.** Una app de mensajería con una lista de contactos. Cada contacto tiene un rubro (tienda, colegio, banda de música…) y te manda encargos. Más contactos = más trabajos simultáneos.
- **Trabajos nuevos**: páginas web para clientes, foros, reparar PCs de conocidos.
- **Descargas P2P**: consigues música, apps y herramientas gratis, pero con probabilidad de virus.
- **Subastas**: vendes tu hardware viejo para recuperar parte de lo invertido.
- **Peligro — Gusano**: un virus infecta un contacto y se propaga por la lista. Tienes que limpiarlo con el antivirus antes de que se coma los ingresos.
- **Automatización**: el Programador de tareas ejecuta tus scripts cada X segundos, sin clics.
- **Mejora de mitad de era**: **Service Pack 2**, con firewall: menos virus.

### Era 3 — Windows 7: "La audiencia"

- **Recurso nuevo: Seguidores.** Publicas en blog y videos. Los seguidores generan ingresos por publicidad y atraen mejores clientes.
- **Gadgets de escritorio**: reloj, CPU, clima… cada gadget es un **generador pasivo** que vive en el escritorio.
- **Interfaz Aero**: ventanas translúcidas y vista previa en la barra de tareas.
- **Peligro — Phishing**: aparecen correos falsos mezclados con encargos reales. Si haces clic en uno falso, pierdes seguidores o dinero.
- **Automatización**: scripts de PowerShell que encadenan apps (p. ej. "terminar proyecto → publicar en el blog").

### Era 4 — Windows 8: "El cambio brusco"

- **Golpe de timón**: el menú Inicio desaparece y llega la **pantalla de mosaicos**. Tus automatizaciones de la era anterior **dejan de funcionar** hasta que las "adaptas" (cuestan dinero o tiempo). Es un mini-reinicio que se siente como el original.
- **Mosaicos vivos**: cada mosaico es un generador que muestra sus números en tiempo real. Los ordenas y les cambias el tamaño, y su posición da bonus por adyacencia ("los mosaicos de redes junto al de noticias dan +20 %").
- **Tienda de apps**: Coding ahora publica apps móviles. Muchas ventas pequeñas en vez de pocas grandes.
- **Mejora de mitad de era (chiste)**: **8.1**, que te **devuelve el botón de Inicio**. Es una mejora cara y todo el mundo la compra.

### Era 5 — Windows 10: "La nube"

- **Suscripciones**: tus apps pasan a ingresos recurrentes. Los clientes pueden cancelar si la calidad baja (abandono).
- **Reparto de la GPU**: la GPU se divide entre **trabajar**, **hacer streaming** y **minar**. Es una decisión constante de asignación.
- **Equipo remoto**: el Personal ahora trabaja desde casa. Contratas en todo el mundo, con husos horarios distintos.
- **Peligro — Windows Update**: "Su equipo se reiniciará en 10 minutos". Si no guardas o pospones, pierdes el progreso del proyecto en curso.
- **Automatización**: servidores en la nube que ejecutan tus apps incluso con el juego cerrado (**progreso offline** a partir de aquí).

### Era 6 — Windows 11: "Los agentes"

- **Requisito de entrada (chiste)**: necesitas **TPM 2.0**. Es una pieza que tienes que conseguir y que no sirve para nada más.
- **Agentes de IA**: le asignas un agente a cada app (Trabajo, Coding, Email…). Trabajan solos y el juego pasa a ser casi totalmente idle.
- **Supervisión**: los agentes a veces "alucinan" y entregan trabajo malo. Puedes revisar a mano (bonus) o subir el nivel del agente.
- **Final**: la IA termina haciendo tu trabajo mejor que tú. Llega un último correo: *"Ya no necesitamos tus servicios."* → créditos → **Nueva Partida+**.

---

## Estructura de progresión

### Tres ciclos

| Ciclo | Duración | Qué haces |
|-------|----------|-----------|
| **Corto** | 5–60 s | Tareas, proyectos, encargos, eventos |
| **Medio** | 5–20 min | Comprar componentes, contratar, mejoras de la era |
| **Largo** | 1–2 h por era | Cumplir los requisitos e **instalar el siguiente sistema** |

### Instalar un sistema = prestige ("Formatear")

Instalar el siguiente Windows **formatea el disco**:

- **Se pierde**: el dinero, los proyectos en curso y las mejoras de software de la era.
- **Se mantiene**: el hardware (que necesitas para el siguiente sistema), los logros, el Personal (con un costo de reentrenamiento) y el **Conocimiento**.
- **Conocimiento** (moneda permanente): `conocimiento = floor(sqrt(dinero_total_era / 1000))`. Se gasta en multiplicadores permanentes.

#### Respaldo: elige qué te llevas

Antes de formatear eliges qué respaldar, con **capacidad limitada** según el medio de la era:

| Era | Medio | Capacidad |
|-----|-------|-----------|
| 95 | Disquetes | 1,44 MB × cantidad de disquetes comprados |
| XP | CD-R | 700 MB |
| 7 | Pendrive | 8 GB |
| 8 | Disco externo | 500 GB |
| 10 | Nube | Ilimitada (suscripción) |

Cada cosa que puedes llevarte ocupa espacio: una app publicada, un contacto, un script, un % del dinero… Esto convierte el prestige en una **decisión** en vez de un botón.

### Requisitos mínimos (barrera natural)

Basados en los requisitos reales:

| Sistema | CPU | RAM | Otros |
|---------|-----|-----|-------|
| 95 | 386 DX | 4 MB | — |
| XP | 233 MHz | 64 MB (128 recomendado) | Tarjeta de red |
| 7 | 1 GHz | 1 GB | GPU con DirectX 9 |
| 8 | 1 GHz | 1 GB | Pantalla táctil (opcional, +bonus) |
| 10 | 1 GHz | 2 GB | SSD (+bonus de arranque) |
| 11 | 1 GHz, 2 núcleos | 4 GB | **TPM 2.0**, arranque seguro |

Además se exige un **hito de era** (p. ej. "gana $X en total con este sistema") para que no se pueda saltar contenido solo comprando hardware.

### Resolución como mejora

El área usable del escritorio crece con la era o con mejoras de monitor: 640×480 → 800×600 → 1024×768 → 1366×768 → 1920×1080 → 4K. Más resolución = más ventanas abiertas a la vez = más producción.

### Nueva Partida+

Al terminar la era 11 se vuelve a Windows 95 con:
- **Legado**: un multiplicador permanente según tus logros.
- **Modo retro**: los conocimientos de los "agentes" aparecen como trucos en el 95 (p. ej. empiezas con WinBatch desbloqueado).
- Logros exclusivos de la segunda vuelta.

---

## Cómo evolucionan las apps existentes

Cada app ya creada **evoluciona con las eras** en vez de reemplazarse. Esto reutiliza el código existente:

| App actual | 95 | XP | 7 | 8 | 10 | 11 |
|-----------|----|----|---|---|----|----|
| **Trabajo** | Freelance offline | + webs y reparaciones | + encargos de contenido | Mosaico vivo | Contratos SaaS | Agente de trabajo |
| **Coding** | Shareware | Programas descargables | Apps de escritorio | Apps móviles | Suscripciones | Apps generadas por IA |
| **Email** | Encargos | + Mensajería (contactos) | + phishing | Notificaciones | Equipos/chat | Agente de bandeja |
| **Explorer** | Tienda en CD | Navegador + P2P | Navegador con pestañas | Tienda de apps | Tienda + nube | Buscador con IA |
| **Winamp** | Buff mientras suena | Lista de reproducción P2P | Reproductor multimedia | App de música | Streaming | Música generada |
| **Personal** | Ayudantes | Socios | Editores | Desarrolladores de apps | Equipo remoto | Agentes de IA |
| **MiPC** | Componentes | + red | + GPU DirectX | + táctil | + SSD, GPU repartida | + TPM |

---

## Eventos

Interrupciones cortas y opcionales que rompen la monotonía. Como máximo una cada 2–4 minutos.

| Era | Evento | Decisión |
|-----|--------|----------|
| 95 | BSOD | Ninguna: es el castigo del overclock |
| 95 | Viene el jefe | Abrir el Buscaminas a tiempo |
| XP | Gusano | Limpiar contactos infectados |
| XP | Y2K (transición) | Prepararse o arriesgarse |
| 7 | Phishing | Distinguir correos reales de falsos |
| 7 | Video viral | Aprovechar la racha (multiplicador temporal) |
| 8 | Usuario confundido | Pagar por soporte o perder reseñas |
| 10 | Windows Update | Guardar o posponer |
| 10 | Pico de la cripto | Pasar la GPU a minar o no |
| 11 | Alucinación | Revisar el trabajo del agente |

---

## Balance (referencia)

```
costo_componente(nivel)   = base * 1.15 ^ nivel
ingreso_tarea             = recompensa_base * mult_componentes * mult_era * (1 + conocimiento * 0.05)
mult_era                  = 10 ^ (indice_era - 1)        -- cada era vale ~10x la anterior
costo_instalar_sistema    = 50_000 * 10 ^ (indice_era - 1)
prob_bsod(overclock)      = 0.02 * overclock ^ 2         -- overclock de 0 a 5
```

Objetivo de ritmo:

| Era | Tiempo hasta el siguiente sistema |
|-----|-----------------------------------|
| 95 | 30–45 min |
| XP | 45–60 min |
| 7 | 60 min |
| 8 | 45 min (era corta a propósito) |
| 10 | 60–90 min |
| 11 | 30 min + idle |

---

## Arquitectura técnica

### Problema actual

Cada módulo (`trabajo.lua`, `coding.lua`, `email.lua`…) define su propia tabla `W95` de colores y dibuja los biseles por su cuenta. Cambiar de sistema obligaría a tocar todos los archivos.

### Solución

```
src/
  theme.lua          -- tema activo: colores, fuentes, sonidos y funciones de dibujo
  themes/
    win95.lua        -- biseles grises, barra azul marino
    winxp.lua        -- Luna: degradados azules, botones redondeados
    win7.lua         -- Aero: translúcido (shader de desenfoque)
    win8.lua         -- plano, colores sólidos, mosaicos
    win10.lua        -- plano, oscuro/claro, acento
    win11.lua        -- esquinas redondeadas, Mica
  eras.lua           -- datos de cada era: requisitos, apps, eventos, multiplicadores
  install.lua        -- pantalla de instalación + respaldo + formateo
```

- **`theme.lua`** expone `Theme.color("titleActive")`, `Theme.drawWindowFrame(...)`, `Theme.drawButton(...)`, `Theme.sound("error")`. Las apps **no saben en qué era están**: solo piden al tema que dibuje.
- **`eras.lua`** es una tabla de datos. Agregar contenido a una era = agregar datos, no código.
- **Guardado**: agregar `saveVersion` y `eraIndex` al guardado para poder migrar partidas viejas.

---

## Assets

### Qué necesita cada era

| Asset | Cantidad por era | Cómo obtenerlo |
|-------|------------------|----------------|
| Marco de ventanas, botones, barra de tareas | — | **Dibujado por código** en `themes/*.lua` (ya se hace así con el 95) |
| Wallpaper | 1–2 | Procedural (shader/degradado) o ilustración propia |
| Íconos de apps | ~12 | Pixel art propio, packs CC0, o generados con IA siguiendo una guía de estilo |
| Sonido de arranque | 1 | Sintetizado / compuesto propio |
| Sonidos de UI (error, aviso, clic) | 3–5 | Sintetizados o CC0 |
| Pantalla de arranque | 1 | Dibujada por código |
| Cursor | 1–2 | Pixel art propio o CC0 |
| Fuente | 1 | Fuentes con licencia libre |

### Guía de estilo por era (para crear o generar íconos)

| Era | Íconos | Paleta | Ventanas |
|-----|--------|--------|----------|
| 95 | 32×32, 16 colores, sin transparencia parcial | Gris #C0C0C0, azul marino #000080, teal #008080 | Biseles 3D, barra de título sólida |
| XP | 48×48, colores saturados, sombra suave | Azul Luna, verde Inicio | Barra azul con degradado, esquinas superiores redondeadas |
| 7 | 48–256 px, brillo, reflejos | Vidrio translúcido, azules | Translúcidas con desenfoque |
| 8 | Planos, monocromos blancos sobre color | Colores sólidos fuertes | Sin bordes, planas |
| 10 | Planos, líneas finas | Gris oscuro/claro + acento | Planas, borde de 1 px |
| 11 | Planos con ligero degradado, redondeados | Pasteles, Mica | Esquinas redondeadas, fondo semitransparente |

### Advertencia legal

Los wallpapers, sonidos (p. ej. el arranque de 95, compuesto por Brian Eno), íconos y logos reales de Windows **tienen derechos de autor de Microsoft**. Sirven como referencia para un proyecto personal, pero **no deben ir en una versión publicada**. Archivos actuales a reemplazar antes de publicar:

- `recursos/(HQ) Windows 95 Startup Sound - Brian Eno - The Microsoft Sound.mp3`
- `assets/sounds/startupWindows.wav`, `CHIMES.WAV`, `ding95.wav`, `errorw95.wav`, `BSOD_Sound.*` (si son los originales)
- `assets/sprites/windows-95.svg` (logo)

---

## Orden de implementación

1. **`theme.lua` + `themes/win95.lua`**: mover las tablas `W95` y el dibujo de biseles al tema. El juego debe verse igual que hoy.
2. **`eras.lua` + `install.lua`**: requisitos, pantalla de instalación, respaldo y formateo.
3. **Era XP completa**: tema Luna, contactos, P2P, gusano. **Esta es la prueba de que la fórmula engancha.**
4. **Balance de 95 → XP** con pruebas de juego reales (medir los tiempos de la tabla de ritmo).
5. **Era 7**, **era 8**, **era 10**, **era 11**, en ese orden.
6. **Nueva Partida+** y logros de la segunda vuelta.
7. Pulido: transiciones de instalación, partículas, sonidos definitivos.
