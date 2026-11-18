// Hardware de la era 95 (portado de explorer.lua). `tiers[i]` es la mejora
// que se compra estando en el nivel i (de `from` a `to`).

export const HW_ORDER = ['cpu', 'ram', 'disk', 'display', 'cooling', 'psu', 'motherboard'];

export const HW = {
  cpu: {
    name: 'Procesador', short: 'CPU', icon: 'cpuIcon', basePrice: 80,
    tiers: [
      { from: 'Pentium 75MHz', to: 'Pentium 100MHz', watts: 40 },
      { from: 'Pentium 100MHz', to: 'Pentium 133MHz', watts: 50 },
      { from: 'Pentium 133MHz', to: 'Pentium 166MHz', watts: 55 },
      { from: 'Pentium 166MHz', to: 'Pentium 200MHz', watts: 70 },
      { from: 'Pentium 200MHz', to: 'Pentium MMX 233', watts: 80 },
      { from: 'Pentium MMX 233', to: 'Pentium II 233', watts: 90 },
    ],
    baseWatts: 30,
    effect: 'Tareas más rápidas y más círculos por segundo en proyectos.',
  },
  ram: {
    name: 'Memoria RAM', short: 'RAM', icon: 'ramIcon', basePrice: 200,
    tiers: [
      { from: '16 MB', to: '32 MB', watts: 5 },
      { from: '32 MB', to: '48 MB', watts: 7 },
      { from: '48 MB', to: '64 MB', watts: 10 },
      { from: '64 MB', to: '128 MB', watts: 14 },
      { from: '128 MB', to: '192 MB', watts: 18 },
      { from: '192 MB', to: '256 MB', watts: 22 },
    ],
    baseWatts: 3,
    effect: '+1 tarea simultánea por nivel y círculos con más puntos.',
  },
  disk: {
    name: 'Disco Duro', short: 'HDD', icon: 'hddIcon', basePrice: 90,
    tiers: [
      { from: '850 MB', to: '1.2 GB', watts: 10 },
      { from: '1.2 GB', to: '2.1 GB', watts: 12 },
      { from: '2.1 GB', to: '4.3 GB', watts: 15 },
      { from: '4.3 GB', to: '8.4 GB', watts: 18 },
    ],
    baseWatts: 8,
    effect: 'Más ofertas en la Bolsa de Trabajo y páginas que cargan más rápido.',
  },
  display: {
    name: 'Placa de Video', short: 'GPU', icon: 'gpuIcon', basePrice: 100,
    tiers: [
      { from: 'Standard VGA', to: 'S3 Trio64', watts: 15 },
      { from: 'S3 Trio64', to: 'S3 ViRGE', watts: 20 },
      { from: 'S3 ViRGE', to: 'Matrox Mystique', watts: 25 },
      { from: 'Matrox Mystique', to: 'ATI Rage Pro', watts: 35 },
      { from: 'ATI Rage Pro', to: '3dfx Banshee', watts: 45 },
      { from: '3dfx Banshee', to: 'Voodoo 3 3000', watts: 55 },
    ],
    baseWatts: 10,
    effect: 'Duplica el pago por tarea y aumenta el daño de los círculos.',
  },
  cooling: {
    name: 'Refrigeración', short: 'FAN', icon: 'fanIcon', basePrice: 75,
    tiers: [
      { from: 'Disipador básico', to: 'Ventilador activo', watts: 4 },
      { from: 'Ventilador activo', to: 'Cooler Turbo', watts: 6 },
      { from: 'Cooler Turbo', to: 'Cooler Master', watts: 9 },
      { from: 'Cooler Master', to: 'Refrigeración semilíquida', watts: 12 },
      { from: 'Refrigeración semilíquida', to: 'Refrigeración líquida', watts: 16 },
      { from: 'Refrigeración líquida', to: 'Sistema custom', watts: 20 },
    ],
    baseWatts: 2,
    effect: 'Tareas más rápidas, mejor pago y menos bugs en proyectos.',
  },
  psu: {
    name: 'Fuente de Poder', short: 'PSU', icon: 'psuIcon', basePrice: 60,
    tiers: [
      { from: 'Fuente 150W', to: 'Fuente 200W', capacity: 200 },
      { from: 'Fuente 200W', to: 'Fuente 250W', capacity: 250 },
      { from: 'Fuente 250W', to: 'Fuente 300W', capacity: 300 },
      { from: 'Fuente 300W', to: 'Fuente 350W', capacity: 350 },
    ],
    baseCapacity: 150,
    effect: 'Más watts disponibles para el resto de los componentes.',
  },
  motherboard: {
    name: 'Placa Madre', short: 'MB', icon: 'mbIcon', basePrice: 150,
    tiers: [
      { from: 'Socket 5', to: 'Socket 7', watts: 8, intervalReduction: 0.03, powerBonus: 0.01 },
      { from: 'Socket 7', to: 'Super Socket 7', watts: 12, intervalReduction: 0.06, powerBonus: 0.02 },
      { from: 'Super Socket 7', to: 'Slot 1', watts: 16, intervalReduction: 0.09, powerBonus: 0.03 },
      { from: 'Slot 1', to: 'Slot 2', watts: 20, intervalReduction: 0.12, powerBonus: 0.04 },
      { from: 'Slot 2', to: 'Socket 370', watts: 25, intervalReduction: 0.15, powerBonus: 0.05 },
      { from: 'Socket 370', to: 'Dual Socket 370', watts: 30, intervalReduction: 0.18, powerBonus: 0.06 },
    ],
    baseWatts: 5,
    effect: 'Reduce los intervalos y sube la potencia de todos los componentes.',
  },
};

export const PRICE_GROWTH = 2.5;

// Componentes que lanzan "círculos" de progreso en los proyectos particulares
export const COMPONENTS = {
  display: { label: 'GPU', color: '#33cc4d', baseInterval: 3.2, basePower: 3,
    tiers: [[3.2, 3], [2.7, 5], [2.2, 8], [1.9, 11], [1.6, 14], [1.3, 18], [1.0, 22]] },
  cpu: { label: 'CPU', color: '#9933e6', baseInterval: 4.5, basePower: 2,
    tiers: [[4.5, 2], [4.0, 3], [3.5, 5], [3.0, 7], [2.5, 9], [2.0, 12], [1.5, 15]] },
  ram: { label: 'RAM', color: '#e6801a', baseInterval: 6.5, basePower: 0,
    tiers: [[6.5, 0], [5.5, 2], [4.5, 4], [4.0, 6], [3.5, 8], [3.0, 11], [2.5, 14]] },
  cooling: { label: 'Refrigeración', color: '#33cccc', baseInterval: 7.5, basePower: 0,
    tiers: [[7.5, 0], [6.5, 2], [5.5, 4], [5.0, 6], [4.5, 8], [4.0, 11], [3.5, 14]] },
};
export const COMPONENT_ORDER = ['display', 'cpu', 'ram', 'cooling'];

export const TIER_NAMES = ['Básico', 'Avanzado', 'Élite', 'Legendario', 'Épico', 'Mítico', 'Supremo'];
export const TIER_COLORS = ['#404040', '#20a020', '#2050e0', '#8020c0', '#d08000', '#d04010', '#e00070'];
