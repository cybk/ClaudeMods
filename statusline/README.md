# Status line con TAG por ventana

Script de status line para Claude Code que muestra `[TAG] repo/subcarpeta · rama* ↑N↓N · Modelo · #sesión`, con un color determinista por tag para distinguir varias ventanas de un vistazo.

- `repo/subcarpeta`: aparece la ruta relativa cuando trabajas dentro de una subcarpeta del repo.
- `↑N↓N`: commits adelantados/atrasados respecto al remoto (se omite si es 0 o no hay remoto).
- `#a3f9`: primeros 4 caracteres del `session_id`; distingue dos ventanas en la misma carpeta y rama. Si Claude Code envía `session_name` (tras `/rename`), se muestra ese nombre en su lugar (no verificado: probar con `claude --debug`).

## Instalación en una computadora nueva (Windows)

### Requisitos
- **Git for Windows** (incluye Git Bash). Claude Code usa Git Bash para ejecutar la status line.
- **Claude Code** ya instalado.
- No necesita `jq` ni nada más.

### Pasos
1. Clona el repo y copia el script. En **Git Bash**:

   ```bash
   git clone https://github.com/cybk/ClaudeMods.git
   cd ClaudeMods
   mkdir -p ~/.claude
   cp statusline/statusline.sh ~/.claude/statusline.sh
   ```

   Si ya tienes el repo, haz `git pull` antes de copiar.

2. Registra la status line en `~/.claude/settings.json`.

   - **Si el archivo no existe o está vacío**, créalo así:

     ```json
     {
       "statusLine": { "type": "command", "command": "bash ~/.claude/statusline.sh" }
     }
     ```

   - **Si ya tiene configuración**, añade solo la clave `statusLine` dentro del objeto principal, separada por coma de las demás, sin borrar nada. Antes haz una copia: `cp ~/.claude/settings.json ~/.claude/settings.json.bak`. Ejemplo:

     ```json
     {
       "theme": "dark",
       "statusLine": { "type": "command", "command": "bash ~/.claude/statusline.sh" }
     }
     ```

   Si ya existe una clave `statusLine` con otro comando, se reemplaza: la clave es un único objeto, no una lista.

3. **Abre una sesión nueva de `claude`.** La sesión abierta no recarga la configuración.

### Verificar que funciona
- En la parte inferior debe aparecer algo como `[MI-CARPETA] mi-carpeta · main · Opus`.
- Prueba el tag: `CLAUDE_TAG=api claude` (en PowerShell: `$env:CLAUDE_TAG='api'; claude`) debe mostrar `[API]`.
- Prueba el archivo de tag: en una carpeta de proyecto, `echo payments > .claude-tag` desde Git Bash y lanza `claude` ahí; debe mostrar `[PAYMENTS]`.
- Prueba la marca de cambios: modifica un archivo versionado y la rama debe verse como `main*`. Los archivos nuevos sin seguimiento no cuentan.

### Si no aparece la barra
La status line falla en silencio: si el comando da error o no devuelve nada, la barra queda en blanco.

1. Comprueba que Git Bash está instalado y que `bash` funciona **en Git Bash** (no en PowerShell, donde `bash` suele ser WSL).
2. Ejecuta el script a mano, desde Git Bash:

   ```bash
   echo '{"cwd":"D:/ruta/a/un/repo","model":{"display_name":"Opus"}}' | bash ~/.claude/statusline.sh
   ```

   Debe imprimir una línea con el tag y la rama. Si da error, revisa que `~/.claude/statusline.sh` existe.
3. Comprueba que el archivo tiene finales de línea LF. Si lo copiaste desde un checkout con CRLF, falla; en este repo `.gitattributes` fuerza LF para los `.sh`.
4. Revisa que `settings.json` es JSON válido (comas y llaves). Un JSON roto hace que Claude Code ignore el archivo.
5. Ejecuta `claude --debug` para ver mensajes del comando.
6. Si usas la config **de un proyecto** (no la de usuario), la barra sale en blanco hasta que aceptes el diálogo de confianza del workspace. Con `--debug` verás "Status line command skipped: workspace trust not accepted".

### Desinstalar
Borra la clave `statusLine` de `~/.claude/settings.json` (o restaura `settings.json.bak`) y elimina `~/.claude/statusline.sh`.

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

Decisiones de diseño y despliegue por proyecto pendiente: ver `DESIGN.md`.
