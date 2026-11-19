// Correos fijos del juego (bienvenida y el malware de las 15 tareas).

export const WELCOME = {
  subject: 'Bienvenido a su nuevo puesto', from: 'admin@empresa.com', type: 'news', read: true,
  body: `Estimado empleado:

Bienvenido a su nuevo puesto. Le explicamos cómo funciona:

1. TRABAJO
Abra "Trabajo" y acepte un encargo. Su PC avanza solo, pero es más rápido si usted escribe.

2. OBJETIVOS
Complete objetivos para desbloquear nuevas aplicaciones.

3. CORREO
Revise su correo regularmente. Pero cuidado: hay correos peligrosos que pueden dañar su equipo.

4. PLAZOS
Entregue a tiempo. Los clientes se acuerdan.

Su gerente.`,
};

export const MALWARE_DESKTOP = {
  subject: 'Descarga disponible: WinOptimizer Pro', from: 'downloads@freeware.com', type: 'malware', desktop: true,
  body: `¡Hola!

Hemos detectado que su PC podría funcionar mejor.

Descargue WinOptimizer Pro para optimizar su sistema y aumentar su velocidad hasta un 300%.

¡Gratis por tiempo limitado!`,
};
