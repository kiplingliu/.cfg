---
name: add-flashcards
description: Append question/answer flashcards to a Markdown deck in hashcards Q/A format, either from an explicit question and answer or from a high-level description like "problems I struggled with" or "difficult concepts from this session". Supports short fact cards and long-form problem/solution cards.
argument-hint: "[file.md] [card, or a description of what to make cards for]"
---

# Add hashcards Q/A flashcards

Append cards to a Markdown deck using the
[hashcards](https://github.com/eudoxia0/hashcards) Q/A format.

## Inputs

- **Target file**: the `.md` file to append to. If the user didn't name one,
  use the deck already being discussed; otherwise ask. Create the file if it
  doesn't exist.
- **What to make cards for**, one of:
  - **An explicit card**: a question and answer given directly. Keep the
    user's wording; fix only obvious typos.
  - **A high-level description**, e.g. "problems I struggled with", "difficult
    concepts", "the proofs from today". Work out the content yourself (see
    below).

## Choosing cards from a high-level description

1. Gather source material from the current conversation first (problems the
   user worked through, mistakes they made, things they asked to have
   re-explained, concepts they found confusing), then from any files they point
   to (notes, problem sets, solutions).
2. Pick items that match the description. Signs the user struggled: several
   attempts, wrong first answers, corrections, "I don't get…", requests for
   hints, or long back-and-forth on one point.
3. Choose a card type for each item:
   - **Concept card** (short): one fact, definition or idea per card. Split a
     big concept into several small cards rather than one sprawling one.
   - **Problem card** (long-form): a full problem with its worked solution.
     Use it for problems the user had to solve, where the method matters.
4. Before writing, read the target deck and skip anything that is already
   covered.
5. Write the cards, then list them for the user (one line each) so they can
   ask for changes.

## Card format

Every card is the `Q:` section, a blank line, the `A:` section, a blank line,
then a horizontal rule:

```markdown
Q: What is the question?

A: The answer.

---
```

### Long-form problem/solution cards

Put the complete problem statement in `Q:` and the worked solution in `A:`.
Both may span many lines and use Markdown: paragraphs, lists, code blocks and
math.

```markdown
Q: **Problem:** Alice and Bob use textbook RSA with $n = 3233$ and $e = 17$.
Eve intercepts $c = 2790$. Given that $n = 61 \cdot 53$, recover the
plaintext $m$.

A: **Solution:**

1. Compute $\varphi(n) = (61 - 1)(53 - 1) = 3120$.
2. Find $d = e^{-1} \bmod \varphi(n)$ with the extended Euclidean
   algorithm: $d = 2753$.
3. Decrypt: $m = c^d \bmod n = 2790^{2753} \bmod 3233 = 65$.

**Key idea:** knowing the factorization of $n$ gives $\varphi(n)$, and
from that the private exponent.

---
```

Guidelines for long-form cards:

- Make the problem self-contained: include every given value and the exact
  thing to find, so it makes sense without the original context.
- In the solution, show the steps rather than just the final result, and end
  with a short **Key idea** naming the trick or insight, especially the one the
  user missed.
- Use blank lines inside a section freely; only the `---` rule ends a card.

### Rules for all cards

- Always put one blank line between the `Q:` section and the `A:` section.
- Always end each card with a blank line followed by `---`.
- Inside a card, never use a horizontal rule (`---`, `***`, `___`); use a
  blank line or a bold label to break up sections. Never start a line with
  `Q:`, `A:` or `C:` except for the card's own markers.

## Appending

1. Read the end of the target file (if it exists).
2. Make sure the existing content ends with a newline, then add one blank line
   before the first new card. Don't add the blank line if the file is empty.
3. Append the cards in order, with one blank line after each `---`. The file
   should end with `---` and a trailing newline.
4. Never modify or reorder existing cards.

Report the file path and the cards that were added.
