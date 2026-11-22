# Diseño y decisiones de la status line

Notas para quien (persona o Claude) retome este mod en otra computadora.

## Restricciones y decisiones

- **Bash, no PowerShell.** La primera versión fue en PowerShell y tardaba 1-3 s por ejecución (solo arrancar PowerShell cuesta ~0,8 s), y la status line corre tras cada mensaje del asistente. En bash baja a ~0,5 s, casi todo del `git status`. En Windows, Claude Code ejecuta el comando con Git Bash.
- **Sin `jq`.** No está instalado de serie. El JSON se lee con expresiones regulares de bash; las rutas llegan con barras invertidas escapadas y se normalizan a `/`. Cualquier campo puede faltar: el script debe salir siempre con código 0.
- **Una sola llamada a git.** La raíz del repo y el worktree se detectan subiendo carpetas en busca de `.git` (directorio = repo, archivo = worktree enlazado) y luego se hace un único `git status --porcelain=v1 -b -uno`. Por `-uno`, los archivos sin seguimiento no marcan `*`.
- **Prioridad del tag:** variable `CLAUDE_TAG`, luego `.claude-tag` (subiendo hasta la raíz del repo), luego el nombre de la carpeta.
- **Color:** hash determinista del tag sobre una paleta de 18 colores ANSI 256. La rama se colorea con su propio hash y los worktrees muestran `wt:nombre`, de modo que dos ventanas de la misma área en ramas distintas se distinguen. Dos ventanas en la misma carpeta y rama son idénticas salvo que `CLAUDE_TAG` difiera.
- **La paleta y el hash están duplicados** en `claude-tabs.ps1` (color de pestañas) y deben mantenerse iguales a los de `statusline.sh`.
- **Requiere bash 4 o superior** (`${var,,}`, `${var^^}`). El bash 3.2 de macOS fallaría; el equipo es solo Windows, así que se acepta.
- **`bash` en PowerShell suele ser WSL**, no Git Bash. Prueba el script desde Git Bash.
- **`.gitattributes` fuerza LF en `*.sh`**: con CRLF el script falla en Windows.

## Qué probar al cambiar el script

Con JSON de prueba por stdin: vacío, `{}`, roto, carpeta sin git, `.claude-tag` en un directorio padre, cambios sin commitear, worktree y HEAD desacoplado. Comprueba también que `api` y `API` dan el mismo color.

## Pendiente: despliegue por proyecto en un repo del equipo

El equipo es solo Windows. La idea es usar la config del proyecto en lugar de la de usuario:

1. Copiar el script a `.claude/statusline.sh` del repo del equipo.
2. Añadir `statusLine` a `.claude/settings.json` del proyecto **sin sobrescribir** las claves que ya tenga:
   ```json
   "statusLine": { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/statusline.sh\"" }
   ```
3. **Sin verificar:** la documentación solo describe `$CLAUDE_PROJECT_DIR` para hooks, no para `statusLine`. Probar con `claude --debug`. Alternativas si no se expande: ruta relativa, o leer `workspace.project_dir` del JSON de entrada.

Datos confirmados en la documentación oficial:
- `CLAUDE.md` es contexto para el modelo, no configuración: `statusLine` no se puede definir ahí.
- La config del proyecto pisa a la de usuario (`settings.local.json` > `settings.json` del proyecto > `~/.claude/settings.json`). `statusLine` es un objeto único y se reemplaza.
- Hasta aceptar el diálogo de confianza del workspace, la barra sale en blanco (`claude --debug` muestra "Status line command skipped: workspace trust not accepted"). Hay que avisar al equipo.
- `.claude-tag` es personal: no se commitea. En este repo está en el `.gitignore`; en otros proyectos no se añade al `.gitignore` sin preguntar.
