# ClaudeLanes

Run several Claude desktop accounts side by side on your Mac — work and personal, each in
its own window, at the same time. Free and open source.

*[Español más abajo](#español)*

<p align="center"><img src="docs/demo.gif" width="800" alt="Two Claude accounts open side by side, each window labelled with its ClaudeLanes profile"></p>

> ClaudeLanes is an independent, unofficial project. It is not made by, affiliated with or
> endorsed by Anthropic. "Claude" is a trademark of Anthropic. ClaudeLanes is for using your own
> legitimate accounts, not for sharing credentials.

## How it works

The official Claude app keeps one account signed in. ClaudeLanes starts extra instances of the
**unmodified** Claude app you installed, each with its own data folder (`--user-data-dir`), so
every profile keeps its own sign-in, settings and history. ClaudeLanes never changes, copies or
re-signs Claude, and your normal Claude stays as it is.

- **Menu bar app** — open, bring to front or quit each profile, and see which ones are running.
- **Window labels** — a small pill with the profile colour and name sits at the top of each
  profile's window, so you always know which account you are in. Turn it off from the menu.
- **One launcher per profile** — `~/Applications/ClaudeLanes/<Name> (ClaudeLanes).app`, with a
  coloured icon and the profile initials. Find it with Spotlight or Launchpad, or drag it to the
  Dock. It works even when ClaudeLanes is not running.
- **Import your current Claude** — turn the account you already use into a profile, with its
  sign-in, settings and history. The original stays untouched as a backup.
- **No duplicates** — opening a profile that is already running brings its window to the front
  instead of starting a second process on the same data, which could corrupt it.
- **Open at login** — optional.

<p align="center"><img src="docs/profiles-window.png" width="560" alt="ClaudeLanes profiles window"></p>

## Install

With [Homebrew](https://brew.sh):

```sh
brew trust --cask xexuscode/tap/claudelanes   # Homebrew 7+ asks you to trust third-party casks once
brew install --cask xexuscode/tap/claudelanes
```

Or download `ClaudeLanes-x.y.z.zip` from
[Releases](https://github.com/XexusCode/claudelanes/releases) and move `ClaudeLanes.app` to
`/Applications`.

The app is not notarized by Apple, so the first time macOS blocks it. Open it once, then go to
**System Settings → Privacy & Security** and click **Open Anyway**. If you prefer, build it
yourself from source (below).

Requires a Mac with Apple Silicon (M1 or later), macOS 14 or later and
[Claude for Mac](https://claude.ai/download). The release build does not run on Intel Macs; on
an Intel Mac, build it from source (below).

## Use

1. Open ClaudeLanes. The profiles window appears.
2. Click **+ → New Profile**, name it, pick a colour, click **Open** and sign in with that
   account. Or click **+ → Import from Current Claude…** to turn the account you already use into
   a profile (quit Claude first).
3. Open profiles from the menu bar icon, from the window, or from their launchers in Spotlight.

## Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`); full Xcode is not required.

```sh
make test      # unit tests
make install   # builds dist/ClaudeLanes.app and copies it to /Applications
make zip       # dist/ClaudeLanes-<version>.zip for a release
```

## Where things are

| What | Where |
| --- | --- |
| Profile list | `~/Library/Application Support/ClaudeLanes/profiles.json` |
| Profile data (sign-in, settings, history) | `~/Library/Application Support/ClaudeLanes/Profiles/<id>/` |
| Launchers | `~/Applications/ClaudeLanes/` |

Deleting a profile removes its launcher. Its data is kept unless you tick
"Also move its session data to the Trash". Profiles from the earlier "Lanes" version are moved
here automatically.

## Uninstall

With Homebrew, `brew uninstall --cask claudelanes` removes the app, and
`brew uninstall --zap --cask claudelanes` also removes your profiles, their data and the
launchers.

By hand: quit ClaudeLanes and its profiles, delete `/Applications/ClaudeLanes.app`, and, to remove
everything else, `~/Applications/ClaudeLanes/` and `~/Library/Application Support/ClaudeLanes/`.
Your normal Claude is not affected either way.

## Troubleshooting

- **"Claude is not installed".** ClaudeLanes looks for the official Claude app by its bundle ID,
  wherever it is. Install [Claude for Mac](https://claude.ai/download) and open it once.
- **macOS says the app is damaged or can't be opened.** It is not notarized: open it once, then
  use **Open Anyway** in **System Settings → Privacy & Security**.
- **Import fails.** Quit the normal Claude first, so its data is not copied half-written.

## Known limitations

- **Dock and ⌘-Tab.** Every open profile shows as "Claude" with Claude's icon, because that is
  the app that is running. Use the window labels or the ClaudeLanes menu to tell them apart.
- **Links.** `claude://` links from the browser open in whichever Claude instance macOS picks.
- If a Claude update changes how `--user-data-dir` works, ClaudeLanes may need an update.

## Licence

MIT

---

## Español

Usa varias cuentas de Claude a la vez en tu Mac, por ejemplo trabajo y personal, cada una en su
ventana. Gratis y de código abierto. Proyecto independiente y no oficial, sin relación con
Anthropic. Es para usar tus propias cuentas legítimas, no para compartir credenciales.

**Cómo funciona:** ClaudeLanes abre la app oficial de Claude **sin modificar** varias veces, cada
una con su propia carpeta de datos, así que cada perfil guarda aparte su sesión, ajustes e
historial. No cambia, copia ni vuelve a firmar Claude, y tu Claude normal no se toca.

- Menú en la barra superior para abrir, traer al frente o cerrar cada perfil.
- Etiqueta con el color y el nombre del perfil en la parte superior de su ventana.
- Un lanzador por perfil en `~/Applications/ClaudeLanes/`, con icono de color e iniciales. Sale
  en Spotlight y Launchpad, y lo puedes anclar al Dock.
- Importar tu Claude actual como perfil, con su sesión, ajustes e historial. El original se
  queda intacto como copia de seguridad.
- Si el perfil ya está abierto, lo trae al frente en vez de abrir otro encima de los mismos datos.

### Instalar

Con [Homebrew](https://brew.sh):

```sh
brew trust --cask xexuscode/tap/claudelanes   # Homebrew 7+ pide confiar una vez en casks de terceros
brew install --cask xexuscode/tap/claudelanes
```

O descarga `ClaudeLanes-x.y.z.zip` de
[Releases](https://github.com/XexusCode/claudelanes/releases) y mueve `ClaudeLanes.app` a
`/Aplicaciones`.

La app no está notarizada por Apple, así que la primera vez macOS la bloquea: ábrela una vez, ve a
**Ajustes del Sistema → Privacidad y seguridad** y pulsa **Abrir igualmente**.

Requiere un Mac con Apple Silicon (M1 o posterior), macOS 14 o posterior y
[Claude para Mac](https://claude.ai/download). La versión publicada no funciona en Macs con Intel;
en uno de ellos, compílala desde el código.

### Uso

1. Abre ClaudeLanes. Aparece la ventana de perfiles.
2. Pulsa **+ → New Profile**, ponle nombre, elige un color, pulsa **Open** e inicia sesión con esa
   cuenta. O pulsa **+ → Import from Current Claude…** para convertir la cuenta que ya usas en un
   perfil (cierra Claude antes).
3. Abre los perfiles desde el icono de la barra de menús, desde la ventana o desde sus lanzadores
   en Spotlight.

### Compilar desde el código

Necesitas las Command Line Tools de Xcode (`xcode-select --install`); no hace falta Xcode completo.

```sh
make test      # tests unitarios
make install   # genera dist/ClaudeLanes.app y la copia a /Applications
make zip       # dist/ClaudeLanes-<versión>.zip para una release
```

### Dónde se guarda todo

| Qué | Dónde |
| --- | --- |
| Lista de perfiles | `~/Library/Application Support/ClaudeLanes/profiles.json` |
| Datos de cada perfil (sesión, ajustes, historial) | `~/Library/Application Support/ClaudeLanes/Profiles/<id>/` |
| Lanzadores | `~/Applications/ClaudeLanes/` |

Al borrar un perfil se borra su lanzador. Sus datos se conservan salvo que marques
"Also move its session data to the Trash".

### Desinstalar

Con Homebrew, `brew uninstall --cask claudelanes` quita la app, y
`brew uninstall --zap --cask claudelanes` además borra los perfiles, sus datos y los lanzadores.

A mano: cierra ClaudeLanes y sus perfiles, borra `/Applications/ClaudeLanes.app` y, para quitar
todo lo demás, `~/Applications/ClaudeLanes/` y `~/Library/Application Support/ClaudeLanes/`. Tu
Claude normal no se toca en ningún caso.

### Problemas frecuentes

- **"Claude is not installed".** ClaudeLanes busca la app oficial de Claude por su identificador,
  esté donde esté. Instala [Claude para Mac](https://claude.ai/download) y ábrela una vez.
- **macOS dice que la app está dañada o que no se puede abrir.** No está notarizada: ábrela una
  vez y usa **Abrir igualmente** en **Ajustes del Sistema → Privacidad y seguridad**.
- **Falla la importación.** Cierra antes tu Claude normal, para que sus datos no se copien a medio
  escribir.

### Limitaciones conocidas

- **Dock y ⌘-Tab.** Todos los perfiles abiertos salen como «Claude» con el icono de Claude, porque
  es la app que se está ejecutando. Usa las etiquetas de las ventanas o el menú de ClaudeLanes para
  distinguirlos.
- **Enlaces.** Los enlaces `claude://` del navegador se abren en la instancia de Claude que elija
  macOS.
- Si una actualización de Claude cambia cómo funciona `--user-data-dir`, puede que ClaudeLanes
  necesite actualizarse.
