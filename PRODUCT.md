# Product

## Register

product

## Users

Screenshot Inbox is for everyday iPhone and Android users who use screenshots
as a quick way to save something for later and eventually accumulate hundreds
or thousands of them. It is deliberately not positioned only for power users or
productivity enthusiasts.

People capture events, products, restaurants and places, conversations, coupons,
orders, and information they want to remember. Their real problem is not merely
having too many screenshots; it is: “I took this screenshot for a reason and
then forgot about it.”

## Product Purpose

Screenshot Inbox turns an existing behavior into a reliable local-first loop:

```text
capture → understand → act → handled → cleanup
```

The product discovers screenshots, interprets them on-device, surfaces a small
number of useful actions, records what the user handled, and later offers
explicit cleanup suggestions. Success means users recover the intention behind
a screenshot without having to organize a visual archive manually.

The Home experience answers “What needs my attention?” rather than “Here are all
your screenshots.” Screenshots and durable saved objects are separate concepts:
a source image can eventually be deleted while a user-confirmed place, product,
or other saved object remains.

## Brand Personality

- **Calm and simple.** The app can manage thousands of items without feeling
  overwhelming. It presents clear hierarchy, generous space, and few decisions
  at once.
- **Trustworthy.** It handles personal information and proposes consequential
  actions. It is conservative, explicit, predictable, and honest about low
  confidence.
- **Action-oriented.** It gently moves users toward completing the reason behind
  a screenshot: add, copy, open, remind, save, keep, or explicitly delete.

Behavioral references are Apple Reminders for inbox clarity, Apple Photos for
familiar treatment of visual content, and Things 3 for hierarchy, spacing, and
low-noise handling of many items. These are references for behavior and clarity,
not templates to copy literally.

## Anti-references

- Mobile SaaS dashboards with decorative metrics.
- Interfaces dominated by cards, badges, gradients, or visual chrome.
- Generic “AI app” aesthetics with purple or neon treatments.
- Gamification, streaks, and excessive celebrations.
- Flat chronological lists that imply every screenshot has equal importance.
- Aggressive cleaner apps that pressure the user to delete thousands of photos.
- Any interaction that hides uncertainty or deletes content silently.

## Design Principles

1. **Attention over inventory.** Rank by urgency, actionability, confidence, and
   relevance instead of presenting a chronological photo library.
2. **Confidence must be visible.** Never pretend an interpretation is certain;
   low-confidence results invite review and correction.
3. **Consequential actions stay explicit.** Request permissions only in context,
   explain cleanup reasons in human language, and require native/user
   confirmation for deletion.
4. **Progressive usefulness.** Show recent results as soon as they are ready and
   continue bounded processing without blocking the user on a large library.
5. **Content is the visual anchor.** Thumbnails and meaningful structured data
   carry the interface; chrome, decoration, and competing controls recede.
6. **Preserve user intent.** User-confirmed corrections and saved objects outlive
   reprocessing and, where appropriate, the source screenshot itself.

## Accessibility & Inclusion

WCAG AA is the baseline, adapted to native iOS and Android conventions. The app
supports scalable text, VoiceOver, TalkBack, semantic labels, logical focus
order, reduced motion, sufficiently large touch targets, accessible loading and
error states, and layouts that remain usable at large text sizes.

Meaning is never communicated by color alone. Expiring, handled, low-confidence,
and cleanup-candidate states always include clear text or semantic information.
Contrast must meet AA and descriptive action labels take precedence over compact
but ambiguous icon-only controls.

The visual direction is predominantly white, black, and gray. Color is reserved
for meaning: green for completion and restrained red or orange for urgency and
expiration. Thumbnails are content, not decoration. Iconography stays simple,
chrome stays minimal, and shadows, gradients, and ornamental effects are avoided.
