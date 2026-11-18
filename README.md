# GameVibeStory

## Versión web (nueva)

La versión principal ahora corre en el navegador (HTML + CSS + JavaScript, sin dependencias) y está en `web/`.

```
python web/serve.py
```

Luego abre http://localhost:8095/web/ (agrega `?debug` para usar F1 = +$1000 y F2 = desbloquear apps).

- `web/css/win95.css`: todo el aspecto de Windows 95. Cada era futura tendrá su propio archivo de tema.
- `web/js/core/`: ventanas, sonido, guardado y estado del juego.
- `web/js/apps/`: cada aplicación del escritorio.
- `web/js/data/`: tablas de hardware, trabajos y correos.
- La partida se guarda sola cada 30 segundos en el navegador (y hay 3 ranuras manuales en el menú Inicio).

La versión original en LÖVE (`main.lua`, `src/`) se mantiene como referencia.

Un juego incremental de nostalgia donde visualizas la evolución de componentes, así como de interfaces.

## Controles

- **Click**: Interactuar con botones
- **S**: Guardar juego
- **ESC**: Salir

## Cómo Jugar

### Inicio
1. Empiezas en un garaje con $0
2. Ejecuta "Trabajo" para empezar a generar dinero
3. Gana dinero y mejora tu PC
4. ¡Mejora tu OS y llega hasta la actualidad!

## Visualiza la evolución

Pasa por múltiples sistemas operativos, ve la evolución no solo de tu compañía si no de tu PC virtual.

