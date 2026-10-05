# Assignment Planner

Name: Sanjay Raman
UMID: 71952770

A simple planner for keeping track of coursework. Assignments have a title,
course, due date, and optional description, time estimate, and links. I can
edit assignments, mark them complete, and reopen them.

## Web app

With Jac installed, run from the repo root:

```sh
jac install --npm
jac run
```

Open http://127.0.0.1:8000 to add and manage assignments.

## Mobile app

Use Expo Go on an iPhone connected to the same Wi-Fi as your Mac. Sign into
the same Expo account on both devices. One-time setup:

```sh
jac setup mobile
jac x --node "$PWD/.jac/mobile-rn/node_modules/.bin/expo" login
```

Restart the web server with Wi-Fi access:

```sh
jac run --host 0.0.0.0
```

In a second terminal:

```sh
jac run --dev --port 8010 mobile
```

Scan the QR code with your phone. In the app, enter the web server's Network
URL ending in `:8000` and tap **Load / refresh assignments**. You can view
assignments, mark them complete, and reopen them.

## CLI

With the web server running, use another terminal:

```sh
jac run cli list
jac run cli add "Homework 3" "DATASCI 449" 2026-10-12
jac run cli complete 1
jac run cli reopen 1
```

Replace `1` with the assignment ID from the list.

## How it fits together

The server in `main.jac` saves assignments between sessions. The web UI in
that file, the mobile app in `mobile/main.jac`, and `cli.jac` all use the same
server. The web and mobile UIs use Jac's automatic server-call bridge.

The useful part is being able to add work from the web or terminal and check
it off on my phone. Refresh an interface to see changes made in another one.
