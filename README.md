# Kaidev Laravel Boilerplate

Base de la empresa para arrancar proyectos Laravel con las mismas herramientas
de calidad desde el primer commit: workflows de GitHub Actions, Duster para PHP
y vite-plus (`vp`) para el front.

Este repositorio **no es una aplicación**: es el punto de partida y el sitio
donde se mantienen y versionan esas piezas comunes. Cuando subimos la versión de
Laravel, de Duster o de vite-plus, se actualiza aquí primero, y los proyectos
nuevos salen ya con la versión buena.

## Stack de referencia

| Pieza | Versión |
| --- | --- |
| Laravel | 13.39 |
| PHP (local y CI) | 8.5 |
| Node (CI) | 22 |
| Inertia / Svelte | Inertia 3 / Svelte 5 |
| Tailwind CSS | 4 |
| vite-plus (`vp`) | 1.4 |
| Duster | 3.4 |
| Pest | 5.3 |
| Larastan | 3.13 |

Base: `laravel new` con el starter de Svelte e Inertia.

## Qué aporta este repo

1. **`workflows/`** — las plantillas de `.github/workflows/`. Aquí son ficheros
   inertes: GitHub solo ejecuta lo que está en `.github/workflows/`, así que
   nada de esto corre en este repositorio. Se copian al proyecto destino (abajo).
2. **Tabs a 2 en el front** — `vite.config.ts` fija `fmt.tabWidth: 2`. El valor
   por defecto del starter es **4**, así que todo el front (`resources/js`,
   `resources/css`, `*.ts`, `*.svelte`) se reformateó a 2 y ahí está la mayor
   parte del diff del primer commit.
3. **Duster** — añadido a `require-dev` y ejecutado. `pint.json` está en preset
   `laravel`.
4. **Scripts de npm alineados** con lo que ejecutan los workflows: `npm run
   check` (`vp check` = formato + lint) y `npm run types:check` (`svelte-check`).

## Qué NO aporta

Skills y guidelines de agentes. Son texto que lee un agente, no parte del build,
y mantener una copia aquí garantiza que una de las dos se quede vieja. Viven en
[KaidevLabs/Skills](https://github.com/KaidevLabs/Skills), repo aparte y agnóstico
de framework, y se instalan en cada proyecto (paso 5 de la instalación).

Lo que sí está en `.gitignore` es lo que genera Boost: `AGENTS.md`, `.agents/`,
`boost.json` y `opencode.json`. Los regenera `php artisan boost:install`.

## Instalar en un proyecto nuevo

### 1. Copiar los workflows

```bash
BOILERPLATE=/ruta/a/kaidev-laravel-boilerplate
PROYECTO=/ruta/al/proyecto-nuevo

mkdir -p "$PROYECTO/.github/workflows"
cp "$BOILERPLATE"/workflows/*.yml "$PROYECTO/.github/workflows/"

# El starter de Laravel trae su propio CI (`tests.yml`) que duplica estos
# checks: `duster-lint`, `pest` y `front-lint` ya cubren lo mismo, con un check
# por cosa y en paralelo. Si se queda, cada PR corre todo dos veces y un mismo
# fallo aparece como dos checks rojos.
rm -f "$PROYECTO/.github/workflows/tests.yml"
```

### 2. Instalar los requisitos que el starter no trae

**Duster** (PHP):

```bash
composer require --dev tightenco/duster
```

**vite-plus** (front): el starter actual de Svelte ya lo incluye (`vp` en
`package.json` y `vite.config.ts`). Un Laravel clásico, en cambio, trae `vite` +
`eslint` + `prettier` y hay que migrarlo:

```bash
npm install -D vite-plus
npx vite-plus migrate
```

Ojo: `vp migrate` genera un `vite.config.ts` nuevo con los valores por defecto
del starter, o sea `tabWidth: 4`. **Después de migrar hay que volver a poner
`fmt.tabWidth: 2`.** El comando también escribe ficheros de editor, de agentes y
hooks de git; si no los quieres, pasa `--no-agent --no-editor --no-hooks`.

### 3. Primera pasada (una sola vez por proyecto)

```bash
composer install
vendor/bin/duster fix      # aplica el estándar de PHP
vendor/bin/duster lint     # comprueba que queda limpio

npm install
npm run check:fix          # aplica tabs a 2 + arregla lint en todo el front
npm run types:check
```

En un proyecto recién creado esta primera pasada toca poco, pero es un diff
grande porque es mecánico:

- **PHP**: Duster borra los docblocks redundantes de las migrations
  (`/** Run the migrations. */` encima de `up()` / `down()`).
- **Front**: `check:fix` reformatea a 2 espacios todo lo que el starter generó a
  4.

Conviene commitear esta pasada sola, antes de empezar a escribir código, para no
mezclarla con el primer trabajo real.

### 4. Comprobar en local lo mismo que va a correr el CI

```bash
composer lint:check        # pint --test
npm run check              # formato + lint
npm run types:check        # svelte-check
vendor/bin/pest            # tests
```

### 5. Skills de agentes (opcional)

Las skills de la empresa viven en
[KaidevLabs/Skills](https://github.com/KaidevLabs/Skills), repo aparte y agnóstico
de framework. Boost las instala en el proyecto con un comando.

**Orden obligatorio la primera vez**: `boost:install` antes. `boost:add-skill`
acaba llamando a `boost:update`, y ese comando aborta con *"Please set up Boost
with [php artisan boost:install] first"* si `boost.json` no existe todavía.

```bash
php artisan boost:install --no-interaction

php artisan boost:add-skill KaidevLabs/Skills --list                      # ver qué hay
php artisan boost:add-skill KaidevLabs/Skills --all                       # todas
php artisan boost:add-skill KaidevLabs/Skills --skill=tdd --skill=plans   # un subconjunto
php artisan boost:add-skill KaidevLabs/Skills --all --force               # actualizar
```

`--force` no es opcional al actualizar: sin él, en modo no interactivo, Boost se
salta las skills que ya existen y no refresca ninguna.

Qué hace por dentro:

- Descarga a **`.ai/skills/<skill>/`**, que se commitea (`.ai` no está en
  `.gitignore`), y ejecuta `boost:update`, que materializa cada skill en el
  directorio del agente (`.agents/skills/…` en opencode, `.claude/skills/…` en
  Claude, etc.), que sí está gitignored.
- Audita la seguridad de lo descargado antes de escribirlo (`--skip-audit` para
  saltar la auditoría).

Para quitarlas no hay comando: se borran los directorios y se regenera.

```bash
rm -rf .ai/skills/<skill> .agents/skills/<skill>
php artisan boost:update
```

Consecuencia: las skills se copian dentro de cada proyecto y se versionan allí.
Actualizarlas no se propaga solo; hay que relanzar el comando con `--force` en
cada repo. Es el precio de tenerlas revisables en el PR en lugar de en una
dependencia.

`boost:add-skill` solo instala skills. Las guidelines del repo son copia manual a
`.ai/guidelines/`, que Boost compone en `AGENTS.md` al ejecutar `boost:update`:

```bash
git clone --depth 1 https://github.com/KaidevLabs/Skills.git /tmp/kaidev-skills
mkdir -p .ai/guidelines
cp -r /tmp/kaidev-skills/guidelines/* .ai/guidelines/
rm -rf /tmp/kaidev-skills
php artisan boost:update
```

`.ai/guidelines/` se commitea; `AGENTS.md` no, lo regenera Boost en cada máquina.

Si prefieres que lo haga el agente del proyecto, pégale esto:

```text
Instala las skills de empresa de este proyecto con Laravel Boost.

Pasos, en este orden:
1. `composer show laravel/boost`; si no está: `composer require --dev laravel/boost`.
2. `php artisan boost:install --no-interaction`
3. `php artisan boost:add-skill KaidevLabs/Skills --list --no-interaction`
   Hoy devuelve 7: code-review, eureka, plans, resource-first-controllers,
   security-review, sequential-implementation-orchestration, tdd.
   Si lo que sale no cuadra con esa lista, para y repórtalo antes de instalar.
4. `php artisan boost:add-skill KaidevLabs/Skills --all --no-interaction`

Verifica y repórtame: `ls .ai/skills/` con un directorio por skill y su
`SKILL.md` dentro, el directorio del agente poblado, `git check-ignore -v .agents`
(ignorado) y `.ai/skills` (no ignorado), y `git status --short`.

Restricciones: no commitees nada, no añadas `.ai` al `.gitignore`, no toques
`composer.json`, `package.json` ni ficheros de aplicación. Si aparece un 404, el
repo pasó a privado: párate y avísame. Si aparece un 403 por rate limit, añade
`'github' => ['token' => env('GITHUB_TOKEN')]` a `config/services.php` y
`GITHUB_TOKEN` en `.env`.
```

## Los workflows

GitHub muestra cada check como `workflow / job`. Éstos son los nombres exactos,
que son los que hay que declarar como requeridos en los rulesets:

| Fichero | Check en GitHub | Se dispara en |
| --- | --- | --- |
| `front-lint.yml` | `Front Lint / quality` | PR a `dev` / `main` |
| `pest.yml` | `Pest Tests / Pest Tests` | PR a `dev` / `main` |
| `duster-lint.yml` | `Duster Lint / duster` | PR a `dev` / `main` |
| `auto-merge.yml` | `Auto Merge / auto-merge` | PR, reviews, comentarios, manual |

Los tres primeros se disparan con `opened`, `reopened`, `synchronize` y
`ready_for_review`, y los tres admiten `workflow_dispatch` para relanzarlos a
mano.

### `front-lint.yml`

Corre el front de punta a punta:

- `npm run check` → `vp check`: formato (oxfmt) y lint (oxlint). El
  `vite.config.ts` fija `denyWarnings: true`, así que **un warning rompe el
  build**, igual que un error.
- `npm run types:check` → `svelte-check`. Va aparte a propósito: `vp check` no
  type-checkea ficheros `.svelte`.

Necesita PHP aunque sea un workflow de front, porque genera antes las rutas de
Wayfinder (`php artisan wayfinder:generate`) — `resources/js/actions` y
`resources/js/routes` están en `.gitignore` y `svelte-check` las importa.

`resources/js/components/ui/*` queda fuera del formato y del lint: son
componentes de shadcn-svelte, se regeneran y no se tocan a mano.

### `pest.yml`

Tests con `--parallel`, límite de 60s por test y `--fail-on-risky`. No necesita
base de datos ni Redis: `phpunit.xml` usa SQLite en memoria. Antes de los tests
construye los assets con `npm run build`, porque los tests renderizan vistas con
`@vite`. Si falla, sube `storage/logs/laravel.log` como artefacto.

### `duster-lint.yml`

`tighten/duster-action` con `args: lint` (solo comprueba, no arregla). El action
instala PHP y las dependencias de Composer por su cuenta, por eso el workflow no
tiene un step de `setup-php`. El checkout es plano a propósito: el workflow se
puede lanzar a mano y no escribe en la rama.

### `auto-merge.yml`

Arma el auto-merge nativo de GitHub en cualquier PR no-draft que apunte a `dev` o
`main`. El **ruleset de la rama es la única fuente de verdad** del gating
(aprobaciones, checks requeridos, hilos resueltos): este workflow no los
reimplementa, solo arma el merge y GitHub mergea en cuanto el ruleset se cumple.

- `dev` → squash. `main` → merge commit.
- Actualiza la rama si está *behind*; avisa con un comentario si hay conflictos.
- Ignora PRs de forks (seguridad de cadena de suministro) salvo force-merge.
- Comandos por comentario: `/merge` rearma (admin o maintainer), `/merge-force`
  mergea ya, saltándose el ruleset (solo admin).
- `workflow_dispatch` acepta un `pr_number` para relanzarlo a mano.

## Configuración del repositorio (una vez por repo)

Ninguno de estos workflows funciona del todo sin esto:

1. **Settings → General → Pull Requests → Allow auto-merge.** Sin esto no se
   puede armar ningún auto-merge; el workflow lo detecta y lo avisa en el PR.
2. **Rulesets en `dev` y `main`** con los checks requeridos, usando los nombres
   exactos de la tabla de arriba. Ojo: si renombras un workflow o un job, el
   check cambia de nombre y el ruleset deja de reconocerlo.
3. **Opcional: secreto `ADMIN_TOKEN`.** Solo hace falta si quieres que
   `/merge-force` pueda saltarse la protección de rama; sin él se usa el
   `GITHUB_TOKEN` normal.

## Notas y trampas

- **El CI corre solo en PR.** Con `tests.yml` borrado, no hay verificación en
  `push` a `dev` o `main`: lo que entra ya pasó por su PR. Es la consecuencia
  asumida de tener un check por cosa en lugar de un CI monolítico.
- **Las actions van por tag** (`@v6`, `@v4`, `@v3`), no por SHA. El starter sí
  las pinea por SHA; aquí priorizamos legibilidad y que Dependabot las mueva. Si
  un repo concreto necesita hardening de supply chain, que lo pinee allí.
- **`npm ci` no ejecuta scripts**: `.npmrc` tiene `ignore-scripts=true`. Por eso
  los binarios nativos (`@rollup/rollup-linux-x64-gnu`,
  `@tailwindcss/oxide-linux-x64-gnu`, `lightningcss-linux-x64-gnu`) están como
  `optionalDependencies` con la plataforma explícita. No los quites al regenerar
  el lockfile o el build de CI se rompe.
- **`npm ci` necesita `package-lock.json` commiteado.**
- **`front-lint.yml` no fija la versión de Node**: usa la que trae la imagen del
  runner, mientras que `pest.yml` fija la 22. Deuda conocida: alinear los dos,
  porque una subida de la imagen de `ubuntu-latest` puede cambiar el resultado
  del job de front sin que nadie toque el código.

## Mantenimiento de este boilerplate

Cada subida de versión se hace aquí y se propaga a los proyectos nuevos; a los
existentes, a mano.

Piezas que se suben:

| Qué | Dónde |
| --- | --- |
| Laravel, Pest, Larastan, Duster | `composer.json` |
| vite-plus, Svelte, Tailwind, Inertia | `package.json` |
| Versión de PHP de los workflows | `workflows/*.yml` (`php-version`) |
| Versión de Node de los workflows | `workflows/pest.yml` (`node-version`); `front-lint.yml` aún no la fija |
| Versión de los `uses:` | `workflows/*.yml` |

Checklist al subir algo:

```bash
composer update
npm update
vendor/bin/duster fix
npm run check:fix
composer lint:check && npm run check && npm run types:check && vendor/bin/pest
```

Y después, si cambia alguna versión de la tabla de arriba, actualizar este
README.
