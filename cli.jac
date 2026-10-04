import argparse;
import json;
import sys;
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError, URLError }

# Use the running server so the CLI and web page share assignments.
def call_server(server: str, action: str, fields: dict[str, any]) -> any {
    request = Request(
        server.rstrip("/") + "/api/assignment-planner/function/" + action,
        data=json.dumps(fields).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST"
    );
    try {
        with urlopen(request, timeout=10) as response {
            result = json.load(response);
        }
    } except HTTPError as e {
        result = json.loads(e.read());
    }
    if not result["ok"] {
        raise ValueError(result["error"]["message"]);
    }
    return result["data"]["result"];
}

def main {
    parser = argparse.ArgumentParser(
        prog="jac run cli",
        description="Manage assignments using the running planner server."
    );
    parser.add_argument("--server", `default="http://127.0.0.1:8000",
        help="Planner URL (default: http://127.0.0.1:8000)");
    commands = parser.add_subparsers(dest="command", required=True);
    commands.add_parser("list", help="View assignments, earliest due first");

    add = commands.add_parser("add", help="Add an assignment");
    add.add_argument("title");
    add.add_argument("course");
    add.add_argument("due_date", help="Due date in YYYY-MM-DD format");
    add.add_argument("--description", `default="");
    add.add_argument("--minutes", `type=int, help="Estimated time in minutes");
    add.add_argument("--link", action="append", `default=[],
        help="An assignment URL; repeat this option for multiple links");

    for command in ["complete", "reopen"] {
        action = commands.add_parser(command, help=command.capitalize() + " an assignment");
        action.add_argument("id", `type=int, help="Assignment ID from the list command");
    }
    args = parser.parse_args();

    try {
        if args.command == "list" {
            assignments = call_server(args.server, "list_assignments", {});
            if not assignments {
                print("No assignments yet.");
            }
            for item in assignments {
                status = "Completed" if item["completed"] else "Open";
                print(f"#{item['id']} | {item['due_date']} | {status} | {item['course']} | {item['title']}");
                if item["estimated_minutes"] is not None {
                    print(f"  Estimated: {item['estimated_minutes']} minutes");
                }
                if item["description"] {
                    print("  " + item["description"]);
                }
                for link in item["links"] {
                    print("  " + link);
                }
            }
        } elif args.command == "add" {
            item = call_server(args.server, "add_assignment", {
                "title": args.title, "course": args.course,
                "due_date": args.due_date, "description": args.description,
                "estimated_minutes": args.minutes, "links": args.link
            });
            print(f"Added #{item['id']}: {item['title']}");
        } else {
            item = call_server(args.server, "set_completed", {
                "assignment_id": args.id, "completed": args.command == "complete"
            });
            status = "Completed" if item["completed"] else "Reopened";
            print(f"{status} #{item['id']}: {item['title']}");
        }
    } except URLError as e {
        print(f"Cannot reach {args.server}: {e.reason}. Start the planner with `jac run`.", file=sys.stderr);
        sys.`exit(1);
    } except (ValueError, OSError) as e {
        print(f"Error: {e}", file=sys.stderr);
        sys.`exit(1);
    }
}

with entry {
    main();
}
