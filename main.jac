import "./styles.css";

# A node can be saved in Jac's persistent graph.
node Assignment {
    # Required
    has title: str;
    has course: str;
    has due_date: str;

    # Optional
    has description: str = "";
    has estimated_minutes: int | None = None;
    has links: list[str] = [];
    has completed: bool = False;

    # Filled in by add_assignment so we can identify this assignment later.
    has id: int = 0;
}

# Public functions become endpoints that the web, mobile app, and CLI can call.
def:pub add_assignment(
    title: str,
    course: str,
    due_date: str,
    description: str = "",
    estimated_minutes: int | None = None,
    links: list[str] | None = None
) -> Assignment {
    if not title.strip() or not course.strip() or not due_date.strip() {
        raise ValueError("Title, course, and due date are required.");
    }
    if estimated_minutes is not None and estimated_minutes <= 0 {
        raise ValueError("Estimated time must be greater than zero minutes.");
    }

    assignment = Assignment(
        title=title.strip(),
        course=course.strip(),
        due_date=due_date.strip(),
        description=description,
        estimated_minutes=estimated_minutes,
        links=links.copy() if links is not None else [],
        id=len([root-->][?:Assignment]) + 1
    );

    # Connecting to root makes Jac save the assignment between server runs.
    root ++> assignment;
    return assignment;
}

def:pub list_assignments -> list[Assignment] {
    assignments = [root-->][?:Assignment];
    # YYYY-MM-DD dates sort in chronological order as text.
    return sorted(assignments, key=lambda (item: Assignment) -> str { item.due_date; });
}

def:pub edit_assignment(
    assignment_id: int,
    title: str | None = None,
    course: str | None = None,
    due_date: str | None = None,
    description: str | None = None,
    estimated_minutes: int | None = None,
    links: list[str] | None = None,
    clear_estimate: bool = False
) -> Assignment {
    # None means leave that field unchanged.
    for assignment in [root-->][?:Assignment] {
        if assignment.id == assignment_id {
            updated_title = title.strip() if title is not None else assignment.title;
            updated_course = course.strip() if course is not None else assignment.course;
            updated_due_date = due_date.strip() if due_date is not None else assignment.due_date;

            # Check everything before changing the stored assignment.
            if not updated_title or not updated_course or not updated_due_date {
                raise ValueError("Title, course, and due date are required.");
            }
            if estimated_minutes is not None and estimated_minutes <= 0 {
                raise ValueError("Estimated time must be greater than zero minutes.");
            }

            assignment.title = updated_title;
            assignment.course = updated_course;
            assignment.due_date = updated_due_date;
            if description is not None {
                assignment.description = description;
            }
            if estimated_minutes is not None or clear_estimate {
                assignment.estimated_minutes = None if clear_estimate else estimated_minutes;
            }
            if links is not None {
                assignment.links = links.copy();
            }
            return assignment;
        }
    }
    raise ValueError(f"Assignment #{assignment_id} was not found.");
}

def:pub set_completed(assignment_id: int, completed: bool) -> Assignment {
    # True marks it complete; False reopens it.
    for assignment in [root-->][?:Assignment] {
        if assignment.id == assignment_id {
            assignment.completed = completed;
            return assignment;
        }
    }
    raise ValueError(f"Assignment #{assignment_id} was not found.");
}

# The client component runs in the browser. Its has fields update the page.
def:pub app -> JsxElement {
    has items: list[Assignment] = [];
    has editing_id: int = 0;
    has title: str = "";
    has course: str = "";
    has due_date: str = "";
    has description: str = "";
    has estimate_text: str = "";
    has links_text: str = "";
    has loading: bool = True;
    has busy: bool = False;
    has error: str = "";

    async can with entry {
        await refresh();
    }

    async def refresh {
        loading = True;
        error = "";
        try {
            items = await list_assignments();
        } except Exception as e {
            error = f"Could not load assignments: {e}";
        } finally {
            loading = False;
        }
    }

    def reset_form {
        editing_id = 0;
        title = "";
        course = "";
        due_date = "";
        description = "";
        estimate_text = "";
        links_text = "";
    }

    def begin_edit(item: Assignment) {
        editing_id = item.id;
        title = item.title;
        course = item.course;
        due_date = item.due_date;
        description = item.description;
        estimate_text = str(item.estimated_minutes) if item.estimated_minutes is not None else "";
        links_text = "\n".join(item.links);
        error = "";
        window.scrollTo(0, 0);
    }

    async def save(e: FormEvent) -> None {
        e.preventDefault();
        error = "";
        links = [line.strip() for line in links_text.split("\n") if line.strip()];
        for link in links {
            if not (link.startswith("https://") or link.startswith("http://")) {
                error = "Each link must start with https:// or http://.";
                return;
            }
        }
        minutes = int(estimate_text) if estimate_text.strip() else None;
        busy = True;
        try {
            if editing_id {
                await edit_assignment(
                    editing_id, title, course, due_date, description,
                    minutes, links, minutes is None
                );
            } else {
                await add_assignment(title, course, due_date, description, minutes, links);
            }
            reset_form();
            await refresh();
        } except Exception as e {
            error = f"Could not save assignment: {e}";
        } finally {
            busy = False;
        }
    }

    async def toggle(item: Assignment) {
        busy = True;
        error = "";
        try {
            await set_completed(item.id, not item.completed);
            await refresh();
        } except Exception as e {
            error = f"Could not update assignment: {e}";
        } finally {
            busy = False;
        }
    }

    return <main class="planner">
        <header class="page-header">
            <h1>Assignment Planner</h1>
            <p>Keep your coursework in one place.</p>
        </header>

        {<p class="error" role="alert">{error}</p> if error else None}

        <div class="layout">
            <section class="panel" aria-labelledby="form-heading">
                <h2 id="form-heading">{"Edit assignment" if editing_id else "Add assignment"}</h2>
                <p class="muted">Title, course, and due date are required.</p>
                <form onSubmit={save}>
                    <fieldset disabled={busy}>
                        <label htmlFor="title">Title</label>
                        <input id="title" required value={title} placeholder="Homework 3"
                            onChange={lambda (e: ChangeEvent) { title = e.target.value; }} />

                        <label htmlFor="course">Course</label>
                        <input id="course" required value={course} placeholder="DATASCI 449"
                            onChange={lambda (e: ChangeEvent) { course = e.target.value; }} />

                        <div class="form-row">
                            <div>
                                <label htmlFor="due-date">Due date</label>
                                <input id="due-date" type="date" required value={due_date}
                                    onChange={lambda (e: ChangeEvent) { due_date = e.target.value; }} />
                            </div>
                            <div>
                                <label htmlFor="estimate">Estimated minutes</label>
                                <input id="estimate" type="number" min="1" step="1" value={estimate_text}
                                    placeholder="Optional"
                                    onChange={lambda (e: ChangeEvent) { estimate_text = e.target.value; }} />
                            </div>
                        </div>

                        <label htmlFor="description">Description <span class="optional">(optional)</span></label>
                        <textarea id="description" rows={3} value={description}
                            placeholder="What needs to be done?"
                            onChange={lambda (e: ChangeEvent) { description = e.target.value; }} />

                        <label htmlFor="links">Links <span class="optional">(optional)</span></label>
                        <textarea id="links" rows={2} value={links_text} placeholder="https://canvas.umich.edu/..."
                            aria-describedby="links-help"
                            onChange={lambda (e: ChangeEvent) { links_text = e.target.value; }} />
                        <small id="links-help" class="muted">One http:// or https:// link per line.</small>

                        <div class="actions form-actions">
                            <button type="submit" class="primary">
                                {"Saving..." if busy else ("Save changes" if editing_id else "Add assignment")}
                            </button>
                            {<button type="button" onClick={reset_form}>Cancel</button> if editing_id else None}
                        </div>
                    </fieldset>
                </form>
            </section>

            <section class="assignment-list" aria-labelledby="list-heading">
                <div class="list-heading">
                    <div>
                        <h2 id="list-heading">Your assignments <span class="count">{len(items)}</span></h2>
                        <p class="muted">Earliest due first</p>
                    </div>
                    <button type="button" disabled={busy or loading} onClick={refresh}>Refresh</button>
                </div>

                {<p class="panel muted" role="status">Loading assignments...</p> if loading else None}
                {<div class="panel empty">
                    <h3>No assignments yet</h3>
                    <p class="muted">Add your first assignment using the form.</p>
                </div> if not loading and not error and len(items) == 0 else None}

                {[
                    <article class="panel assignment" key={item.id}>
                        <div class="assignment-top">
                            <span class="course-tag">{item.course}</span>
                            <span class={"status done" if item.completed else "status"}>
                                {"Completed" if item.completed else "Open"}
                            </span>
                        </div>
                        <h3 class={"completed-title" if item.completed else ""}>{item.title}</h3>
                        <p class="metadata">
                            <span>Due <time dateTime={item.due_date}>{item.due_date}</time></span>
                            {<span>{item.estimated_minutes} min estimated</span> if item.estimated_minutes is not None else None}
                        </p>
                        {<p class="description">{item.description}</p> if item.description else None}
                        <ul class="links">
                            {[
                                <li key={index}>
                                    {<a href={link} target="_blank" rel="noopener noreferrer">{link}</a>
                                        if link.startswith("https://") or link.startswith("http://")
                                        else <span>{link}</span>}
                                </li> for (index, link) in enumerate(item.links)
                            ]}
                        </ul>
                        <div class="actions">
                            <button type="button" disabled={busy or loading}
                                onClick={lambda { toggle(item); }}>
                                {"Reopen" if item.completed else "Mark complete"}
                            </button>
                            <button type="button" disabled={busy or loading}
                                onClick={lambda { begin_edit(item); }}>Edit</button>
                        </div>
                    </article> for item in items
                ]}
            </section>
        </div>
    </main>;
}
