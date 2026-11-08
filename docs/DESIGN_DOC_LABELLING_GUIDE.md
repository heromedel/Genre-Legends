# Design Doc Labelling Guide

How design docs label how firm each point is, how points are written and referenced, and how discussions are numbered.

(Note) Imported 2026-11-08 from the "Design Doc Labelling Guide" artifact (https://claude.ai/artifact/Kc7Yw88RfpDbi1yhyqB6Ah). That artifact is the source; if it changes, update this copy to match. Some examples come from other projects.

## 1. Tags: how firmly heromedel has agreed

Every point in the design docs carries one tag. The tag comes from how heromedel said it, and when in doubt the weaker tag wins: a tag never claims more than he said.

Strongest first.

| Tag | Meaning | Set by |
|---|---|---|
| **Hard Rule** | Work within it. Never plan around it or suggest changing it. | "This is a hard rule", "never do X" |
| **Decided** | Follow it. If a real problem turns up, raise it, but don't change it. | "We are going to go with X" |
| **Likely** | Follow it. A better option can be suggested, without nitpicking or arguing. | "We will likely go with X" |
| **Proposed** | heromedel's stated direction, details pending. Usable inside asked-for work when it fits cleanly. | "I was thinking we could do X, but let's worry about that later" |
| **Ai-Generated-Proposal** | Written by Claude, not agreed until heromedel reviews it. Used the same way as Proposed. | Anything Claude came up with itself |
| **Open** | Not discussed yet. Nothing is built on it. | Something named but not talked through |
| **Unlikely** | Kept on record, not expected to be added. Discuss adding it if there is good reason to. | "X is unlikely", "probably not" |
| **Rejected** | Turned down, with a line saying why. If you bring it back up you would need to have a very good explanation. Don't argue. | "No", "we're not doing X" |

## 2. How a tag is written

### In Markdown docs

Bold, at the start of the point, with the date it was given.

```
- **Decided (2026-10-21):** A run is lost when
  all scout ships are gone.
```

### In an HTML design doc

A coloured chip right after the point's letter, e.g. **F:** `[Decided]` A run is lost when all scout ships are gone.

- **The date moves with the tag.** When a point's tag changes, its date changes too, so old points can be spotted at a glance.
- **One point can hold several tags.** A point can be Decided as a whole while some rows of its table are Likely or Proposed, or open with a Likely line followed by an Ai-Generated-Proposal block.
- **A whole document can be tagged at the top**, e.g. "All of these are Proposed rules, not hard rules, unless a different document or heromedel says otherwise."
- **Copied facts carry their source's tag**, e.g. "(GDD 2K; Decided)". When the source point's tag changes, the copy's tag follows it.
- **(Note)** marks a remark that isn't a design point.

### Never in real code

Never tag anything Ai-Generated-Proposal, or credit the AI in any other way, inside real code. A comment cites the design point it follows, e.g. `GDD 6C: a jump costs 1.21 for the squad`. Where the docs are silent and a guess had to be made, the comment says `Not in the docs yet:` followed by the guess, so it reads as an open question.

## 3. How tags have been set in practice

| What heromedel said | Tag |
|---|---|
| "Tag it decided" | Decided |
| "Set it to decided" | Decided |
| Said plainly, without "we're going with" | Likely |
| "Could be", "might", "maybe" | Proposed |
| Claude's idea, but heromedel had said the same thing earlier | Proposed |
| Claude's own suggestion, not yet reviewed | Ai-Generated-Proposal |
| "Unlikely idea" | Unlikely |
| "Put it in the ideas doc as unlikely" | Unlikely |
| "Once we begin coding, FTL must not be mentioned" | Hard Rule |

- **Agreeing to use proposals isn't agreeing to what they say.** "Yes, use these for the next step" leaves them Ai-Generated-Proposal.
- **Work built on proposals is no firmer than they are.** It stays Ai-Generated-Proposal until reviewed, and so does any gap it filled in.
- **Reports open with the split** of what the work was based on:

```
Based on: 20 points. 1 agreed (Hard Rule, Decided, Likely), 16 proposals, 3 filled in as I went
(5% / 80% / 15%).
```

## 4. Referencing points

- **Section number plus letter:** `2R` is section 2, point R. Letters run A, B, C… within each section, so `7H` and `14D` can be named in any doc or chat.
- **A range:** `5F to 5L` or `15A–15C`.
- **When two sessions take the same letter**, the later one is relettered at merge time and its decision log row fixed to match. On 2026-10-26 Doc Brown's controller points became `14E` and `14F`, because `14D` was already Player Power Color.
- **The decision log** (GDD 16) gets one dated row per decision, naming the points it changed, kept in date order.

## 5. Labels in discussion

| Label | Used for | Example |
|---|---|---|
| `A, B, C` | Plans | Plan A: merge Ship Designs first |
| `1, 2, 3` | Steps in a plan, and discussion points, so they can be answered by number | "2. why won't you say…" |
| `Q1, Q2` | Questions that need heromedel's answer | "q1 2.0, q2 you'll see later" |
| `Name: Default > Other` | Settings, default first | `Multi Target Lasers: On > Off` |
| "Classic" | A setting that makes a feature play like FTL. It never names FTL. | `Terran Ship Conduits: On > Off`, where Off is the classic behaviour |

One major, high-level question at a time: if there would be more than about six separate questions, the discussion isn't at the right level yet.
