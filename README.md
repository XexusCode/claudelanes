# Lanes

Run several Claude desktop accounts side by side on your Mac — work and personal, each in
its own window, at the same time. Free and open source.

*[Español más abajo](#español)*

> Lanes is an independent project. It is not made by, affiliated with or endorsed by Anthropic.
> "Claude" is a trademark of Anthropic. Lanes is for using your own legitimate accounts, not for
> sharing credentials.

## How it works

The official Claude app keeps one account signed in. Lanes starts extra instances of the
**unmodified** Claude app you installed, each with its own data folder (`--user-data-dir`), so
every profile keeps its own sign-in, settings and history. Lanes never changes, copies or
re-signs Claude, and your normal Claude stays as it is.

- **Menu bar app** — open, bring to front or quit each profile, and see which ones are running.
- **Window labels** — a small pill with the profile colour and name sits at the top of each
  profile's window, so you always know which account you are in. Turn it off from the menu.
- **One launcher per profile** — `~/Applications/Lanes/<Name> (Lanes).app`, with a coloured icon
  and the profile initials. Find it with Spotlight or Launchpad, or drag it to the Dock. It works
  even when Lanes is not running.
- **No duplicates** — opening a profile that is already running brings its window to the front
  instead of starting a second process on the same data, which could corrupt it.
- **Open at login** — optional.

## Install

1. Download `Lanes-x.y.z.zip` from [Releases](https://github.com/XexusCode/lanes/releases) and
   move `Lanes.app` to `/Applications`.
2. The app is not notarized, so macOS will warn you the first time. Right-click it → **Open** →
   **Open**. If you prefer, build it yourself from source (below).
3. The profiles window opens. Click **Add Profile**, name it, pick a colour, click **Open** and
   sign in with that account.

Requires macOS 14 or later and [Claude for Mac](https://claude.ai/download).

## Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`); full Xcode is not required.

```sh
make test      # unit tests
make install   # builds dist/Lanes.app and copies it to /Applications
make zip       # dist/Lanes-<version>.zip for a release
```

## Where things are

| What | Where |
| --- | --- |
| Profile list | `~/Library/Application Support/Lanes/profiles.json` |
| Profile data (sign-in, settings, history) | `~/Library/Application Support/Lanes/Profiles/<id>/` |
| Launchers | `~/Applications/Lanes/` |

Deleting a profile removes its launcher. Its data is kept unless you tick
"Also move its session data to the Trash".

## Known limitations

- **Dock and ⌘-Tab.** Every open profile shows as "Claude" with Claude's icon, because that is
  the app that is running. Use the window labels or the Lanes menu to tell them apart.
- **Links.** `claude://` links from the browser open in whichever Claude instance macOS picks.
- If a Claude update changes how `--user-data-dir` works, Lanes may need an update.

## Licence

MIT

---

## Español

Usa varias cuentas de Claude a la vez en tu Mac, por ejemplo trabajo y personal, cada una en su
ventana. Gratis y de código abierto. Proyecto independiente, sin relación con Anthropic. Es para
usar tus propias cuentas legítimas, no para compartir credenciales.

**Cómo funciona:** Lanes abre la app oficial de Claude **sin modificar** varias veces, cada una
con su propia carpeta de datos, así que cada perfil guarda aparte su sesión, ajustes e historial.
Lanes no cambia, copia ni vuelve a firmar Claude, y tu Claude normal no se toca.

- Menú en la barra superior para abrir, traer al frente o cerrar cada perfil.
- Etiqueta con el color y el nombre del perfil en la parte superior de su ventana, para saber
  siempre en qué cuenta estás. Se puede desactivar desde el menú.
- Un lanzador por perfil en `~/Applications/Lanes/<Nombre> (Lanes).app`, con un icono de color y
  sus iniciales. Sale en Spotlight y Launchpad, y lo puedes anclar al Dock.
- Si el perfil ya está abierto, lo trae al frente en vez de abrir otro encima de los mismos datos.
- Opción de abrir Lanes al iniciar sesión.

**Instalar:** descarga el zip de *Releases*, mueve `Lanes.app` a Aplicaciones y la primera vez
ábrela con clic derecho → **Abrir**. Se abre la ventana de perfiles: **Add Profile**, ponle
nombre y color, **Open** e inicia sesión.

**Limitación:** en el Dock y en ⌘-Tab todos los perfiles abiertos salen como «Claude». Usa las
etiquetas de las ventanas o el menú de Lanes para distinguirlos.
