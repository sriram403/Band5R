---
name: project-memory
description: How to keep a project's notes so any new thread or any model (Claude, GPT/Codex, others) can continue instantly, and so lessons survive between projects - the hand-off file with a LIVE STATUS, the mistake log (assumed → reality → fix → habit), lessons written the moment they happen, AGENTS.md and CLAUDE.md kept in step, "update the md files", milestone check-ins, short threads, and promoting general lessons to the user's skills library. Use when starting or setting up any multi-session project, when the user says "update the md files", "hand over", "new thread", "write it down", "note this", or at a milestone. Always on for any task bigger than a quick question (the user's global rule), including new threads (in T3 Code the model launches the next thread itself and stops; elsewhere it suggests, 3-minute wait, twice per thread, then just works).
---

# Project memory: notes that let any model carry on

**Version: v9 (2026-11-08).** v9: `DECISIONS.md` scope record (kept/cut/why) in the files table. v8: in T3 Code the model moves itself to a new thread, no asking, then gives the picture view and stops (§4). v1 from a co-op game and a 3D likeness build, where the notes
were what let a new thread (or another model) continue with no loss. v2: always on for every
project. v3: new threads are suggested twice, then the model just works (§4); own folder per project. v4: every new-thread
suggestion ends with a copy-paste hand-off prompt using full paths (§4). v5: the hand-off prompt and HANDOFF.md name the skills in use, so a new
thread loads them without asking (§4). v6: start a real timer before saying "I'll wait 3 min";
no timer tool, no waiting claim (§4). v7: every suggestion tells the user to reply "moved" in the
old thread, or it keeps working alongside the new one; the new thread repeats that reminder in
its first reply (§4).

**You may ask the user questions at any point**, e.g. which notes they want for a small project. If
you're sure, go ahead. Keep messages to the user short and a bit fun, and say *(📓 project-memory)*
when a behaviour comes from this skill.

**When this applies:** every task bigger than a quick question or a single small change, in any
project, without asking first (the user's global rule). For small tasks, no files.

**Setting up a new project:** give it its own folder (in a workspace like `exp/`, make
`exp/racing-game/`); if the current folder already holds the project, work there. Ask once whether
everything (venvs, conda, downloads, caches) should stay inside that folder (recommend yes). Then
create `HANDOFF.md` (templates below).

**Saving comes first** (the user asked for this): new or existing project, if the files you'll work
on have no git (or other backup), ask before editing anything: *"No git here yet. Set one up first so
every change can be undone?"* Recommend yes: `git init`, a `.gitignore` for venvs, downloads, caches
and big generated files, then a first commit of the untouched files. Local only; no remote or push
without asking. If they say no, note it in `HANDOFF.md` and be extra careful (copy a file before a
risky edit).
**No git for general-knowledge Q&A** (the user, 2026-10-31): looking up facts, summarising a
document, answering "what is this / does it apply to me" is not a project. Don't ask about git,
don't stage or commit those notes, and don't offer to commit. A short notes file is fine. Git is for
things being built (apps, code, models, pipelines). If such a folder sits inside a git repo, leave it
untracked (add it to `.gitignore`).

## 1. Why

Models don't learn while they work and threads end without warning (compaction drops detail by
chance; a long thread gets slow and costly, since every message resends the whole conversation).
**The files are the memory.** At every moment they must let a brand-new thread, or another model,
continue: what was done, how (methods, commands), what was learned, and the exact next action.
Nothing important may live only in the chat.

## 2. The files (start small; add only what the project needs)

| File | What's in it | When it changes |
|---|---|---|
| `AGENTS.md` | Instructions for every model: how to work here, the read order, the user's rules for this project, the list of notes. Codex/GPT read this name. | When a rule changes |
| `CLAUDE.md` | `@AGENTS.md` plus anything Claude-only. Keep the two in step (or import, so there's one copy). | With AGENTS.md |
| `HANDOFF.md` (or `notes/MASTER_PROMPT.md`) | Read order + **LIVE STATUS**: where work stopped, the exact next action, commands to run | After every sub-step |
| `notes/TODO.md` or `PROGRESS.md` | Live checklist: a "Right now" line on top, `[~]` in progress, sub-steps ticked with results (pass/fail, numbers) | As each piece lands |
| `notes/LESSONS.md` / `LEARNINGS.md` | Sorted lessons: what happened, why, what to do instead; tool gotchas; environment facts | The moment you learn one |
| Mistake log (a section in the rough notes or lessons) | **assumed → reality → fix → habit** | The moment reality disagrees |
| `DECISIONS.md` | Scope record: the goal, what we build (core vs features), what we left out, and why (who decided, when). The user reads it when they forget what was or wasn't done | When a keep/cut decision is made |
| `notes/PRINCIPLES.md` / `PRO_WORKFLOW.md` | How work is done here, the method versions (v1, v2, ...) and a decision log (date, decision, on whose observation) | When the method changes |
| `notes/CHANGE_LEDGER.md` | Each change: what changed, what it could break, which tests cover it | As each change lands |
| `notes/POLISH.md` | Things agreed "for later"; remind the user at the end | When the user defers something |

Templates: [`templates/`](templates/) (AGENTS.md, HANDOFF.md, LESSONS.md).

## 3. Habits

- **Write at once, read first.** Lessons and mistakes go in the moment they happen, not at the end of
  a milestone. Before starting something similar, read the mistake log: writing is half, reading
  first is the other half.
- **"Update the md files"** means every note the change touches, without being told which. Keep that
  list in the project's `AGENTS.md` so any model can find it.
- **Before editing, look:** at the start of a thread, read the hand-off and run `git status`; the last
  thread may have left work half done.
- **Say where a thing lives:** which folder and branch hold a part. Nothing is "ready" until it's in
  the copy the user runs.
- **Commit small and often** (locally); push only per the project's rules or when the user asks.
- **Notes before the context fills:** if a thread is getting long, write everything worthwhile into
  the files before a compaction. New-thread moments: §4.
- **Reports** at a hand-off, in plain language: (a) what couldn't be tested, (b) what's done, (c) the
  next step.

## 4. New-thread moments: suggest twice, then just work

Short threads with good notes beat one long thread, but the user decides: they may not care about
tokens at all. So a new thread is a **suggestion, never a stop**.

**When:** a milestone is done; the next task doesn't need this chat's history; or you were just
compacted (you see a summary in place of the earlier conversation). You can't measure how full your
context is, so use these signals rather than guessing a percentage.

**In T3 Code: move yourself** (the user's rule, 2026-11-02; they used to do the hand-off by hand).
You can tell you're in T3 Code when you have the `t3_thread_launch` tool. Then don't suggest and don't
wait; do it:
1. **Judge it yourself:** this thread has done enough (a milestone, or you were compacted) and the
   next piece of work doesn't need this chat's history.
2. **Update every note** (HANDOFF LIVE STATUS with the exact next action, TODO, lessons).
3. **Say it in one line:** *"🧳 Moving to a new thread for <next work>: this one's full of <old work>."*
4. **Launch** the new thread with `t3_thread_launch`, in the **same project folder** (no worktree
   unless the project uses them), with the hand-off prompt below as its first message. Leave out the
   `FIRST:` "reply 'moved'" line: this thread parks itself, so there's no collision to warn about.
5. **Confirm it started** (the launch result shows the thread; `t3_thread_read` if unsure).
6. **Last message here:** *"✅ Moved → <thread link, verbatim>"* + the **picture view** of what this
   thread did (the one time it comes unasked; shape in the global rules), then **stop**: no more edits,
   no timers.
- Launch failed → say so in one line and keep working here.
- The user says "new thread after X" → finish X, then do steps 2–6.

**Anywhere else** (no thread tool), the user opens new threads by hand:

**Flow (per thread):**
1. **Update every note first** (HANDOFF LIVE STATUS with the exact next action, TODO, lessons), so a
   new thread could start this second.
2. **First milestone: suggest + wait 3 min. Timer first, message second** (the user asked for this
   after a model said "I'll wait 3 minutes" with no timer, so nothing ever woke it).
   - **Start the timer as a real tool call before you write the message.** Claude Code: the Bash
     tool with `run_in_background: true` and `sleep 180` (it wakes you when it ends; a foreground
     sleep is blocked). Other apps: whatever background task or scheduled wake-up they have.
   - Only once the timer is running, send the message and end your turn.
   - **No timer tool?** Never write "I'll wait". Use step 6 instead.
   - The user answers first → do what they say (stop the timer if you can; if it fires later,
     ignore it).
   - The timer fires with no answer → carry on with the next milestone here.
3. **Second milestone: same again, 3 min.** Still no answer → **stop suggesting.** From now on just
   work straight through like any agent: no pauses, no waits, notes still kept current.
4. **The user asks ahead of time** ("new thread after X") → finish X, update the notes, **stop**, and
   give them the hand-off prompt (below).
5. **A new thread starts the count fresh** (it follows steps 1–4 again).
6. Your app can't wake you after a timer? Don't wait at all: post the suggestion and keep working.
7. Your app can create the next-thread task itself (a "chip")? Create it in step 2/3 so switching is
   one click; still carry on if it isn't clicked.

**Message template, first time:**

> 🏁 **Milestone 1 done!** Notes are saved.
>
> 💡 **Fresh thread?** This chat is mostly old history now. Every reply drags it along: slower, pricier.
> - 🆕 **New thread:** open one, paste the prompt below 👇, then **reply "moved" here** so I stop
> - ▶️ **Stay:** reply "continue" (nothing breaks, just extra baggage)
>
> ⚠️ **Moving? Tell me here!** I can't see other threads. Without "moved", my timer goes off and I
> keep working here too: two threads editing the same files.
>
> ⏳ No reply in 3 min → I keep going here. *(📓 project-memory)*
>
> *(then the hand-off prompt, in a code block)*

**Second time:** same, but the last line becomes:

> ⏳ No reply in 3 min → I'll stop asking and just keep building. Say "new thread" any time.

**Why the ⚠️ line is a must** (the user asked for it): the old thread can't see that a new one
started. Opening a new thread doesn't stop the old one; its timer fires and it carries on, so both
threads edit the same files and notes and undo each other's work. Keep that line in every
suggestion, also in step 6 (no timer, keep working), where the old thread is already running.

**The user replies "moved"** (or "new thread", "stop", "I switched") → stop the timer if you can,
make no more edits, and reply in one line that this thread is parked. If the timer fires later,
ignore it.

**The hand-off prompt** (the user asked for this). Every time you suggest or start a new thread, end
the message with a ready-to-paste prompt in a fenced code block (one click to copy). If your app can
make a "chip" or next-thread task, put the same text in it. Rules:
- **Full absolute paths** for every file: `D:\work\exp\racing-game\HANDOFF.md`, never just
  `HANDOFF.md` (the new thread may open in a different folder).
- **Clear-cut, not chatty:** written as orders to the next model, so it can start without asking.
- **Self-contained:** it works even if the new model never saw this chat; HANDOFF.md holds the
  detail, the prompt points to it and repeats only what must not be missed.
- **Name the skills** (the user asked for this): a `SKILLS:` line with the full path of each
  `SKILL.md` in use (e.g. `research`, `testing-and-verification`), plus the library catalog. The new
  thread loads them at once, no "use it or go raw?" question, and knows the rest exist if the user
  says "research X" later.
- **The new thread reminds the user too** (the user asked for this): a `FIRST:` line tells the new
  model to open its first reply with a one-line reminder to reply "moved" in the old thread. The
  user may have missed the ⚠️ line there; this is the second chance before two threads collide.
  Then it carries on; it doesn't wait for an answer. Exception: `git status` or the files show edits
  that aren't in HANDOFF.md (the old thread may still be working) → ask before touching anything.

Shape (fill in, cut lines that don't apply, keep it to one screen):

```
FIRST: open your first reply with: "⚠️ Reply 'moved' in the old thread if you haven't, or it keeps
working on the same files." Then carry on. Edits on disk that HANDOFF.md doesn't mention → ask first.
TASK: You are continuing <project, one line>. Read <full path>\HANDOFF.md first and follow it
exactly: its read order (<full paths of the other notes, with the sections that matter>), then
resume from its LIVE STATUS.
SKILLS: load now: <full path>\skills\<name>\SKILL.md, ... (always project-memory). Other skills:
<library>\README.md; when I name one or its trigger ("research X"), load it without asking.
DONE: <milestones done, with the proof file, e.g. renders/sheet_G7.jpg>. Honest state: <what is
still not right>.
SCOPE: <user decisions that limit the work>.
NOW: stage <X>, as LIVE STATUS "Next action" says: (1) ... (2) ... (3) gate: <command>, record the
verdict, milestone check-in.
KEY RULES: <the 5-10 rules a new model is most likely to break: how to judge done, what to measure
first, tools allowed, where files go, loop limit, what must stay open/running and the exact command
to start it>. Update HANDOFF.md LIVE STATUS after each sub-step, the other notes at milestones.
CONTEXT: <2-4 lines: tools/engine/versions, what this thread changed and in which files>.
<Shared notes folder for parallel sessions, if any: full path.>
```

A project's own `AGENTS.md` can change any of this for that project; its rule wins there.

## 5. Promoting lessons to the skills library

Project notes keep project lessons. Lessons that would help a *different* project belong in the
user's skills library (its path is in the global rules).
- While working, mark such lessons as general (e.g. a "General" tag or a short list at the end of
  `LESSONS.md`).
- At a milestone or the end of the work, **ask the user**: "Is it okay to generalize these into your
  skills library?" with the lessons one line each.
- A general method or rule **the user** creates: add it to the right skill yourself (no need to ask),
  tell them, and suggest pushing the library (private on GitHub) as a backup.
- On a yes, follow that library's `AGENTS.md`: right skill, generalized wording, merged
  rather than appended, changelog line.
- **Building an app?** It also gets an **app skill** in the library (`apps/<app>/SKILL.md`): the full
  record of what it is, how it's built (PC and phone), tests and every lesson. Make it at the first
  milestone, refresh it at each later one, and name it in the project's `AGENTS.md`/`HANDOFF.md`.
  Starting a project? Check the table in the library's `apps/README.md` first: a match is your base.
  App skills are private: commit them in `apps/`'s own local git, never push unless the user asks.
