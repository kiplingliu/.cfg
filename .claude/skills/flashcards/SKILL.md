---
name: flashcards
description: Propose hashcards flashcards (Q/A, no cloze) from the preceding conversation, get the user's approval, then write them to a file. Use when the user asks for flashcards from the conversation.
---

# Flashcards from the conversation

## Format

Hashcards Q/A cards only — never cloze (`C:`). Separate cards with a horizontal
rule (`---` on its own line, blank lines around it). Questions and answers may
span multiple lines; the question runs until the `A:` line, the answer until
the next `---`.

```
Q: What does the rank–nullity theorem say for $T: V \to W$?

A: $\dim V = \dim \ker T + \dim \operatorname{im} T$.

---

Q: Proof strategy for "every finite-dimensional inner product space has an
orthonormal basis"?

A: Take any basis and run Gram–Schmidt. Induct: each new vector has its
projection onto the span of the previous ones removed, then is normalized.
Linear independence guarantees it is never zero.
```

Math goes in `$...$` / `$$...$$`.

## Card guidelines

- Draw only from what the conversation actually covered, especially points the
  user got wrong or found hard.
- For proofs, card the strategy and key move, not the full write-up.
- The question must be answerable without seeing the conversation.

## Steps

1. Draft the cards and show them to the user in the exact file format, with the
   proposed file path (default: `flashcards/<topic-slug>.md` in the working
   directory; append if the file exists).
2. Ask for approval. Apply any edits, additions, or removals the user requests
   and re-show changed cards if the changes were substantial.
3. Once approved, write the file. If appending, separate the new cards from the
   existing ones with `---`.
