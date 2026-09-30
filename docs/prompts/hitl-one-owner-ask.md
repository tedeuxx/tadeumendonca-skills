# Portable prompt — one owner ask per activation, with only the countable half prevented

Use this prompt when a human decision surface can lose later questions, or when several owner actions
are being bundled into one message and the receiver pays the context cost separately for each.

## Behaviour to carry

Every activation or message to the owner carries **one ask only**. That applies to decisions and to
actions: one structured picker question, or one direct owner action. If more remain, preserve them and
raise each in its own later activation after the owner answers the first.

Keep the forms distinct:

- a decision presents the reduced choices, with each consequence in the option the owner reads;
- an action that only the owner can execute is one direct order plus its object or link, with no menu;
- an interview question draws out the owner's view and therefore carries no proposed options.

Never preserve a second ask by moving it into prose, a numbered list, or an option description beside
the first. That still presents several asks in one interruption and may also bypass the structured
surface whose transport behaviour motivated the rule.

## The control boundary

Prevent only what is syntactically certain: before a structured picker renders, count its real question
array and deny arrays with two or more members. Let zero, one, missing, null, non-array, malformed and
unparsed payloads fall through. The host may reject invalid payloads independently; this control makes no
claim about them.

Do not classify question text, option labels, verbs, links, or the difference between a decision and an
action. Those are semantic judgements held by review. A prior preventive control guessed that partition
from label spelling; its false positives suppressed genuine decisions before the owner could see them.
Invisible suppression is more damaging than the one-sentence failure it was trying to prevent.

The prose half therefore remains a review obligation: a direct message containing two owner actions has
no tool payload a pre-execution hook can count. Punctuation such as `!` is only a weak proxy; prose can
carry several asks with none, and ordinary prose can contain several without asking for anything.

## Evidence owed

Test the exact structured boundary with payloads carrying zero, one, two and four questions, plus null,
absent and unparsed input. Calibrate the deny assertion by raising the threshold so the two-question case
goes red, and calibrate the fall-through boundary by replacing it with a denial so its cases go red.
Assert the matcher and script registration too; a green script test over an unreachable hook proves no
runtime control.

Direct script tests do not prove host routing. Record the routing version that was read, and separately
collect the first benign pass and expected denial from the installed release before calling runtime
execution observed.
