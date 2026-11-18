// Correos fijos del juego (bienvenida y el malware de las 15 tareas).

export const WELCOME = {
  subject: 'Bienvenido a su nuevo puesto', from: 'admin@empresa.com', type: 'news', read: true,
  body: `Estimado empleado:

Bienvenido a su nuevo puesto. Le explicamos cómo funciona:

1. GANAR DINERO
Abra "Trabajo" en el escritorio y presione "Trabajar". Cada tarea le paga unos pocos dólares. Trabaje más para ganar más y mejorar su PC.

2. OBJETIVOS
Complete objetivos para desbloquear nuevas aplicaciones.

3. CORREO
Revise su correo regularmente. Pero cuidado: hay correos peligrosos que pueden dañar su equipo.

4. PROYECTOS
Acepte proyectos en la Bolsa de Trabajo de Internet Explorer. Sus componentes generan círculos de progreso automáticamente. Mejores componentes = más rápido. Complete la barra antes de que se acabe el tiempo.

Su gerente.`,
};

export const MALWARE_DESKTOP = {
  subject: 'Descarga disponible: WinOptimizer Pro', from: 'downloads@freeware.com', type: 'malware', desktop: true,
  body: `¡Hola!

Hemos detectado que su PC podría funcionar mejor.

Descargue WinOptimizer Pro para optimizar su sistema y aumentar su velocidad hasta un 300%.

¡Gratis por tiempo limitado!`,
};
