// Taller (solo modo 3D): PCs de clientes con fallas, virus y pedidos de mejora.

// Qué se puede romper, y cómo lo cuenta el cliente
export const FAULTS = {
  psu: 'No prende. Ni la lucecita.',
  cooling: 'Se apaga solo después de un rato y quema de caliente.',
  ram: 'Le salen pantallazos azules a cada rato.',
  display: 'Prende, suena, pero la pantalla queda negra.',
  disk: 'Hace un ruido como de grillo y no arranca Windows.',
};
export const VIRUS_COMPLAINT = 'Anda lentísimo y se abren ventanas solas.';

// Pedidos de mejora: [componente, nivel mínimo, cómo lo pide]
export const UPGRADES = [
  ['ram', 2, 'Mi hijo quiere jugar y dice que le falta memoria.'],
  ['ram', 3, 'Quiero que ande más rápido con varios programas abiertos.'],
  ['display', 2, 'Quiero una tarjeta de video mejor para los juegos.'],
  ['disk', 2, 'Ya no me caben las fotos. Pónganle un disco más grande.'],
  ['cooling', 2, 'Suena como avión. ¿Algo más silencioso?'],
];

export const REPAIR_CLIENTS = [
  'Sra. Marta (vecina)', 'Don Raúl, almacén', 'Tío Hernán', 'Colegio San Andrés', 'Pablo, del liceo',
  'Peluquería Glamour', 'Consulta Dr. Fuentes', 'Junta de vecinos', 'Kevin, gamer', 'Notaría Pérez',
];

// Archivos del disco del cliente: [nombre, tamaño, fecha]
export const CLEAN_FILES = [
  ['COMMAND.COM', '92.870', '24/08/95', 'system'], ['WIN.INI', '3.112', '02/11/95', 'system'],
  ['SYSTEM.INI', '2.208', '02/11/95', 'system'], ['AUTOEXEC.BAT', '412', '14/09/95', 'system'],
  ['CONFIG.SYS', '226', '14/09/95'], ['KRNL386.EXE', '75.490', '24/08/95', 'system'],
  ['CARTA.DOC', '18.432', '30/10/95'], ['PRESUP.XLS', '24.064', '28/10/95'], ['NOTAS.TXT', '1.204', '01/11/95'],
  ['FOTOS.ZIP', '1.482.102', '19/10/95'], ['DOOM.WAD', '4.196.020', '10/12/94'], ['SOLITARIO.EXE', '180.224', '24/08/95'],
  ['RECETAS.DOC', '9.728', '07/07/95'], ['CLIENTES.MDB', '322.560', '29/10/95'],
];
export const VIRUS_FILES = [
  ['FOTO_PLAYA.JPG.EXE', '12.288', '01/01/80'], ['CARTA_AMOR.TXT.VBS', '4.096', '01/01/80'],
  ['GANASTE.EXE', '8.704', '13/13/95'], ['CHISTE.COM', '2.560', '01/01/80'],
  ['ACELERADOR_PC.EXE', '31.744', '00/00/00'], ['SALVAPANTALLA.SCR', '6.144', '01/01/80'],
  ['WIN_UPDATE32.EXE', '9.216', '31/02/95'], ['NO_ABRIR.EXE', '1.024', '01/01/80'],
];
