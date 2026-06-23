# Plan de Juego: Studio Empire (Incremental Game Dev)

## Concepto
Gestiona un estudio de desarrollo de juegos estilo Game Dev Story, con mecánicas incrementales profundas. Pixel art minimalista.

## Estructura de Recursos

### Recursos Principales
| Recurso | Descripción | Obtención |
|---------|-------------|-----------|
| **Dinero** | Moneda primaria | Ventas de juegos |
| **Puntos de Investigación** | Desbloquea mejoras | Contratos, tiempo |
| **Fama** | Atracción de fans | Juegos exitosos |
| **Reputación** | Calidad percibida | Calidad de juegos |

### Recursos Premium (Post-Prestige)
| Recurso | Descripción |
|---------|-------------|
| **Legado** | Moneda de prestige, persiste entre generaciones |
| **Hitos** | Logros desbloqueados que dan bonuses永久 |

## Loop Principal

```
Desarrollar Juego → Ganar Dinero → Comprar Upgrades → Desarrollar Mejores Juegos → Repetir
```

### Ciclos de Progreso
- **Corto (30s-2min):** Cada juego desarrollado
- **Medio (5-15min):** Upgrades de oficina, contrataciones
- **Largo (30min+):** Consola propia, prestige
- **Muy largo (horas):** Múltiples generaciones, 100% logros

## Sistemas del Juego

### 1. Sistema de Desarrollo de Juegos
```
Elegir Género + Plataforma → Asignar Staff → Desarrollar → Lanzar → Ganar Dinero
```

**Géneros (desbloqueables):**
- RPG, Acción, Deportes, Estrategia, Simulación, Aventura, Puzzle, Terror

**Plataformas:**
- PC (base), Consola, Móvil, Handheld

**Combos Ocultos (descubrimiento):**
- RPG + Fantasía = +50% fama
- Terror + PS5 = +30% ventas
- Simulación + Móvil = +40% retención

### 2. Sistema de Staff
**Stats por empleado:**
- Programación (velocidad de desarrollo)
- Diseño (calidad del juego)
- Arte (gráficos)
- Sonido (música/efectos)
- Comercial (marketing)

**Carreras:**
- Junior → Senior → Lead → Director → Leyenda

**Contratación:**
- Reclutamiento básico (aleatorio)
- Agencias (mejor calidad, cuesta dinero)
- Reclutamiento legendary (requiere reputación alta)

### 3. Sistema de Oficina
**Mejoras de Oficina:**
| Nivel | Capacidad | Costo | Bonus |
|-------|-----------|-------|-------|
| 1 | 3 empleados | Base | - |
| 2 | 5 empleados | 10x | +10% velocidad |
| 3 | 8 empleados | 100x | +20% calidad |
| 4 | 12 empleados | 1000x | +30% todo |
| 5 | 20 empleados | 10000x | +50% todo |

**Equipamiento:**
- Computadoras (velocidad)
- Consolas de prueba (calidad)
- Estudio de grabación (sonido)
- Sala de descanso (moral)

### 4. Sistema de Consola (Prestige Mayor)
Al alcanzar hitos específicos, puedes crear tu propia consola:
- Costo: Todo tu dinero acumulado
- Reset: Pierdes dinero, staff, oficina
- Ganas: Bonuses永久 + nueva plataforma exclusiva

**Generaciones de Consolas:**
1. Gen 1: Básica, 8-bit
2. Gen 2: 16-bit, mejor calidad
3. Gen 3: 3D, online
4. Gen 4: VR, next-gen

### 5. Sistema Prestige (Generational Succession)
**Cuándo prestigear:**
- Cuando la progresión se estanca
- Cuando desbloqueas suficiente contenido
- Cuando quieres bonuses de legado

**Qué resetea:**
- Dinero actual
- Staff actual
- Oficina actual
- Upgrades temporales

**Qué persiste:**
- Legado (moneda premium)
- Géneros/plataformas desbloqueados
- Hitos/Logros
- Bonuses de legado

**Fórmula de Legado:**
```
Legado = log10(dinero_total_generado) * multiplicador_generacion
```

### 6. Sistema de Automatización
**Managers (post-prestige):**
- Auto-desarrollan juegos
- Auto-contratan staff
- Auto-mejoran oficina

**Upgrades de Auto:**
- Velocidad de desarrollo automático
- Calidad mínima garantizada
- Selección automática de genre combo

## Fórmulas de Balance

### Costo de Empleados
```
costo = base_costo * 1.15 ^ empleados_actuales
```

### Costo de Oficina
```
costo = 1000 * 10 ^ nivel_actual
```

### Ingresos por Juego
```
ingreso = (calidad_base * multi_genre * multi_plataforma * multi_fama) * 1000
```

### Calidad del Juego
```
calidad = (suma_stats_staff / num_staff) * (1 + bonus_equipo) * random(0.8, 1.2)
```

## Contenido por Fase

### Fase 1: Early Game (0-30 min)
- Tutorial: Primer juego
- Desbloqueo de géneros básicos
- Primeras contrataciones
- Primera mejora de oficina

### Fase 2: Mid Game (30min - 2 horas)
- Múltiples géneros/plataformas
- Staff especializado
- Consola Gen 1
- Primer prestige

### Fase 3: Late Game (2-5 horas)
- Consola Gen 2-3
- Combos ocultos descubiertos
- Managers automáticos
- Múltiples prestiges

### Fase 4: Endgame (5+ horas)
- Consola Gen 4 (VR)
- Todos los géneros
- Staff leyenda
- 100% logros
- Leaderboards

## Logros (Ejemplos)

| Logro | Condición | Bonus |
|-------|-----------|-------|
| Primer Juego | Lanzar primer juego | +10% ingresos |
| Estudio Famoso | 100k de fama | Desbloquea RPG |
| Consola Propia | Crear Gen 1 | +20% calidad |
| Millionario | 1M de dinero | +15% todo |
| Leyenda | Staff nivel max | +50% experiencia |
| Combo Master | Descubrir 10 combos | +25% descubrimientos |

## Progreso Offline
- Staff continúa trabajando (reducido)
- Ingresos pasivos (50% eficiencia)
- Desarrollo avanza (sin input)

## UI/UX

### Pantalla Principal
```
[Dinero] [Investigación] [Fama] [Reputación]
[Botón Desarrollar] [Botón Staff] [Botón Oficina] [Botón Consola]
[Panel de Juegos Activos]
[Logros Recientes]
```

### Feedback Visual
- Números flotantes al ganar dinero
- Animaciones de staff trabajando
- Efectos de partículas al lanzar juego
- Barra de progreso de desarrollo
- Notificaciones de hitos

## Métricas de Éxito
- Tiempo promedio de sesión: 15-30 min
- Retención D1: >40%
- Retención D7: >20%
- Prestiges promedio: 3-5 por sesión

## Orden de Implementación

1. **Core Loop:** Desarrollo de juego simple
2. **Recursos:** Dinero, stats básicos
3. **Staff:** Contratación, stats, niveles
4. **Upgrades:** Mejoras de oficina, equipo
5. **Géneros/Plataformas:** Desbloqueos
6. **Consola:** Sistema prestige mayor
7. **Legado:** Prestige menor, bonuses
8. **Automatización:** Managers
9. **Contenido:** Logros, combos, eventos
10. **UI/UX:** Animaciones, feedback, pulido
