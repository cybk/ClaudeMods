# Status line con TAG por ventana

Script de status line para Claude Code que muestra `[TAG] repo · rama* · Modelo`, con un color determinista por tag para distinguir varias ventanas de un vistazo.

## Instalación

1. Copia `statusline.sh` a `~/.claude/statusline.sh`.
2. Añade esta clave a `~/.claude/settings.json` (sin borrar el resto de la configuración):

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline.sh" }
```

Requiere `bash` (Git Bash en Windows) y `git`. No necesita `jq`.

## Cómo se decide el tag

1. Variable de entorno `CLAUDE_TAG`.
2. Archivo `.claude-tag` (primera línea) en la carpeta o en un directorio padre, hasta la raíz del repo.
3. Nombre de la carpeta actual.

La rama se colorea con su propio hash y los worktrees enlazados se marcan como `wt:nombre`, para distinguir dos ramas de la misma área.

## Probarlo sin Claude

```bash
echo '{"cwd":"/ruta/al/repo","model":{"display_name":"Opus"}}' | bash statusline.sh
```

## Extras (PowerShell 7)

Copia `tag.ps1` y `claude-tabs.ps1` a `~/.claude/`.

**`tag`** crea, muestra o borra el `.claude-tag` de la carpeta actual. Añade esta línea a tu `$PROFILE`:

```powershell
function tag { & "$HOME\.claude\tag.ps1" @args }
```

```powershell
tag api          # escribe .claude-tag con "api"
tag              # muestra el tag en vigor
tag -Remove      # borra el .claude-tag
```

**`claude-tabs.ps1`** abre una pestaña de Windows Terminal por proyecto, con título y color del tag, ejecutando `claude` en su carpeta con `CLAUDE_TAG` ya puesto. Lee `~/.claude/tabs.txt` (formato `tag=ruta`, ver `tabs.example.txt`):

```powershell
~\.claude\claude-tabs.ps1                       # usa tabs.txt
~\.claude\claude-tabs.ps1 -Tab api=D:\code\api, web=D:\code\web
~\.claude\claude-tabs.ps1 -DryRun               # solo muestra el comando wt
```

La paleta y el hash de `claude-tabs.ps1` deben coincidir con los de `statusline.sh` para que el color de la pestaña sea el de la barra.

Nota: en PowerShell, `bash` puede ser el de WSL y no Git Bash. La status line la ejecuta Claude Code con Git Bash, así que no afecta, pero no pruebes `statusline.sh` con `bash` desde PowerShell: usa Git Bash.
