# Studio Empire - Incremental Game Dev

Un juego incremental estilo Game Dev Story donde administras un estudio de desarrollo de juegos.

## Controles

- **Click**: Interactuar con botones
- **S**: Guardar juego
- **ESC**: Salir

## Cómo Jugar

### Inicio
1. Empiezas en un garaje con $500
2. Contrata tu primer empleado
3. Desarrolla tu primer juego (RPG o Action para PC)
4. Gana dinero y fama

### Progresión
- **Desarrolla juegos** → Gana dinero y fama
- **Mejora tu oficina** → Más capacidad y bonuses
- **Contrata staff** → Mejora la calidad de tus juegos
- **Descubre combos** → Género + Plataforma con bonuses especiales

### Prestige
Cuando la progresión se estanque:
1. Haz click en "Prestige"
2. Ganas Legado (moneda premium)
3. Reseteas dinero, staff y oficina
4. Desbloqueas consolas y mejoras permanentes

### Consolas
Cada prestige puede desbloquear una nueva consola con bonuses:
- Retro Boy (8-bit)
- Super System (16-bit)
- PlayStation (3D)
- NextGen (VR)

## Fórmulas

- **Costo de staff**: 100 * 1.15^n (n = empleados actuales)
- **Costo de juegos**: 100 * 1.1^n (n = juegos creados)
- **Ingresos**: Calidad^1.5 * Fama * Reputación * 100
- **Legado**: log10(dinero_total) * (1 + 0.1 * prestiges)

## Guardado

Presiona **S** para guardar. El juego también guarda automáticamente al cerrar.

## Contenido

- 8 géneros de juegos
- 4 plataformas
- 5 combos ocultos
- 6 niveles de oficina
- 6 mejoras de equipo
- 4 generaciones de consolas
- 6 mejoras de legado
- Sistema de staff con 5 carreras
