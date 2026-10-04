# Assignment Planner

A simple tracker for assignments, courses, due dates, descriptions, estimated
time, links, and completion status. This checkpoint contains the persistent
Jac server, web interface, and CLI. The mobile app will be added next.

## Run the web app and server

Prerequisite: [install Jac](https://www.jac-lang.org/quick-guide/install/).
This project has been tested with Jac **0.37.23** on macOS.

From the project folder:

```sh
jac --version
jac install --npm
jac run
```

Run `jac install --npm` once after downloading the project to install the web
dependencies. Jac supplies its own package manager. Internet access is needed
for this step.

Open **http://127.0.0.1:8000** in your browser. Leave the terminal running;
use a second terminal for the API examples below. Press **Ctrl+C** to stop it.
If the old server is still running, stop it before starting this version.

In development, Jac starts the web interface on port 8000 and the backend on
port 8001. The web server forwards API requests to the backend, so the examples
below still use port 8000. To choose a different pair of ports, use
`jac run --port 8010` (web 8010, backend 8011).

Jac manages the local database automatically. The first use may download its
embedded PostgreSQL runtime, so allow internet access during initial setup.
Restarting the server from the same project folder preserves assignments.
The database is associated with the project's absolute path; a fresh checkout
in another folder has its own data.

## Use the web interface

- Enter a title, course, and due date, then click **Add assignment**.
- Optionally include a description, estimated minutes, and links (one complete
  `http://` or `https://` URL per line).
- Assignments appear earliest due first. Click **Edit** to fill the form with
  an existing assignment, then **Save changes** or **Cancel**. Clear an optional
  field to remove its saved value.
- Click **Mark complete** or **Reopen** to change completion status.
- Click **Refresh** to load changes made by another client.

## Use the CLI

Keep `jac run` running in one terminal. In a second terminal, from the same
project folder:

```sh
jac run cli list
jac run cli add "Homework 3" "DATASCI 449" 2026-10-12
jac run cli complete 1
jac run cli reopen 1
```

Use the assignment ID printed by `add` or `list` in place of `1`. The list
includes completed assignments, descriptions, estimates, and links.

The add command also accepts the optional fields:

```sh
jac run cli add "Read chapter 4" "DATASCI 449" 2026-10-13 \
  --description "Take notes on the examples" --minutes 45 \
  --link "https://canvas.umich.edu/"
```

Repeat `--link` to include multiple URLs. The CLI calls the running server;
click **Refresh** on the web page to see CLI changes.

For a different server port, place `--server` before the command:

```sh
jac run cli --server http://127.0.0.1:8010 list
```

For help, use `jac run cli -- --help` or `jac run cli -- add --help`.
The extra `--` prevents Jac 0.37.23 from intercepting the CLI's help flag.

## Try the API

All four actions accept JSON through POST requests. Use the app-specific
URLs below: in Jac 0.37.23, the shorter `/function/...` routes mishandle
omitted `None` defaults. The app-specific routes preserve them correctly.

Add an assignment (description, estimated minutes, and links are optional):

```sh
curl -X POST http://127.0.0.1:8000/api/assignment-planner/function/add_assignment \
  -H 'Content-Type: application/json' \
  -d '{"title":"Homework 3","course":"DATASCI 449","due_date":"2026-10-12","estimated_minutes":90}'
```

List assignments, earliest due first:

```sh
curl -X POST http://127.0.0.1:8000/api/assignment-planner/function/list_assignments \
  -H 'Content-Type: application/json' -d '{}'
```

Edit assignment 1 (use the ID returned when adding your assignment):

```sh
curl -X POST http://127.0.0.1:8000/api/assignment-planner/function/edit_assignment \
  -H 'Content-Type: application/json' \
  -d '{"assignment_id":1,"due_date":"2026-10-15","estimated_minutes":120}'
```

Mark it complete:

```sh
curl -X POST http://127.0.0.1:8000/api/assignment-planner/function/set_completed \
  -H 'Content-Type: application/json' \
  -d '{"assignment_id":1,"completed":true}'
```

To reopen it, send the same request with `"completed":false`.

Successful responses contain `"ok":true`, with the returned assignment or list
under `data.result`. Failed requests contain `"ok":false` and an explanation
under `error.message`.

Dates use `YYYY-MM-DD`. In edits, omitted fields or `null` leave a field unchanged;
`"description":""` clears the description and `"links":[]` clears links.
An existing time estimate can be replaced with another positive number;
`"clear_estimate":true` removes it.

## How it works

- `main.jac` holds the `Assignment` node, the add/list/edit/completion functions,
  and the `app` web component. Jac compiles the component for the browser and
  turns its calls to server functions into HTTP requests.
- `root ++> assignment` connects a new assignment to Jac's saved graph.
  Updating connected nodes persists their changes.
- `def:pub` exposes those functions as API endpoints. This is a single shared
  personal planner with no application login. The server is bound to this
  computer by default.
- `styles.css` provides the page styling and stacks the form above the list
  on narrow screens.
- `cli.jac` uses Jac with Python's standard-library `argparse` and `urllib`
  to parse terminal commands and call the same server endpoints. It keeps no
  separate assignment database and needs no extra packages.
- `jac.toml` declares a default web app and a CLI app, following the named-app
  structure of the `jac create --awesome` example. `jac run` launches the web
  interface and backend together; `jac run cli` selects the CLI.

The UI follows [Part 4 of the Day Planner guide](https://docs.jaseci.org/tutorials/first-app/build-ai-day-planner/#part-4-a-reactive-frontend):
a `JsxElement` component, reactive `has` fields, a `can with entry` load hook,
`await` calls to server functions, and an imported CSS stylesheet. Colors and
layout are customized for this assignment tracker. The guide bundled with
Jac 0.37.23 uses inferred client placement, so this project uses plain
`def:pub app` and `import "./styles.css"` without the older `cl` prefix.

Check the code with `jac check main.jac`. Jac 0.37.23 currently emits warnings
for generated component setters and some JSX names; compilation succeeds.
API behavior and persistence after a server restart were verified using an
isolated copy of the project. The compiled web component was checked against
an isolated server for adding, editing, clearing optional fields, completing,
reopening, link validation, due-date ordering, and reloading saved assignments.
Browser layout and click behavior still need a manual check.
The CLI was verified against a separate test server for listing, adding,
completing, reopening, invalid IDs/estimates, and connection failures. Changes
made by the CLI were also verified through the web-facing API.
