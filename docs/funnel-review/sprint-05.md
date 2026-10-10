# sprint-05 — funnel review

commit: 01045b660fc31fa6cb4f063fc0c5a2f1aa04db7c
collection: docs/funnel-review/collected/sprint-05.tsv
cap: 2 findings, the ceiling and not a quota

FUNNEL-REVIEW-RAN

The surfaces were read and this report is the analysis of what came back. Every figure below
carries its sample size and its consent ceiling. A figure that arrived without a sample size would
be listed as unusable rather than printed as a figure; none did.

**Scope of the read.** GA4 for tadeumendonca.io, window 2026-09-25..2026-10-09, plus the LinkedIn
own-activity list. X was not read. One piece was published in the window: the bilingual article from
tadeumendonca-io #687, PT `/pt/blog/a-ia-responde-em-segundos-voce-nao-precisa` and EN
`/en/blog/ai-answers-in-seconds-you-dont-have-to`, with one LinkedIn post. That post was the only post
in the window. No comment count was visible for it, so this report contains no comment figure.

**No baseline.** `collected/sprint-04.tsv` declares `collected: no`, so every "against the prior
period" question has no answer this period. "Not measured in sprint-04" in each line below means
exactly that. It does not mean flat.

Produced by `bash scripts/funnel-review.sh sprint-05`. The figures section is that script's output,
unedited.

## Figures

- ga4 · sessions_total = 28 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · engaged_sessions_total = 11 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · active_users_total = 8 · n=8 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · sessions_linkedin = 16 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · engaged_sessions_linkedin = 8 · n=16 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · sessions_instagram = 6 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · engaged_sessions_instagram = 1 · n=6 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · sessions_direct = 5 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · sessions_organic_social = 1 · n=28 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_total = 53 · n=8 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_article_ai-answers_pt = 20 · n=2 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_article_ai-answers_en = 6 · n=1 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_article_ai-answers_neutral = 3 · n=1 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_landing_root = 4 · n=4 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · pageviews_article_my-commitment_en = 4 · n=1 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · events_article_progress = 25 · n=4 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · events_article_end_reached = 3 · n=3 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · events_share_complete = 1 · n=1 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · events_nav_click = 2 · n=2 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- ga4 · events_first_visit = 4 · n=4 · not measured in sprint-04 · consent-ceiling: consenting sessions only — the consent banner gates analytics on this site, so a reader who declined is invisible by design
- linkedin · impressions_post_ai-answers = 171 · n=171 · not measured in sprint-04 · consent-ceiling: does not apply to linkedin — this figure is platform-reported, the consent banner gates nothing there, and the platform's own sampling is unstated and unverifiable from here
- linkedin · reactions_post_ai-answers = 1 · n=171 · not measured in sprint-04 · consent-ceiling: does not apply to linkedin — this figure is platform-reported, the consent banner gates nothing there, and the platform's own sampling is unstated and unverifiable from here

## Findings

### Finding 1 — Per-language consumption of the period's article cannot be read this period

**What the numbers show.** By pageviews the PT edition leads: 20 against 6 for EN and 3 for the
neutral share path. But the users behind those pageviews are 2, 1 and 1. With users that few, a
language comparison is a comparison between individual people. It says nothing about the audience of
either edition.

**The figures.**

```
figure: ga4 pageviews_article_ai-answers_pt 20 2
figure: ga4 pageviews_article_ai-answers_en 6 1
figure: ga4 pageviews_article_ai-answers_neutral 3 1
```

**A bound on the PT figure, stated as a hypothesis and not as a fact.** The collection step reported
about 29 minutes of average engagement on the PT page. That was a console reading and is not a
`figure:` line, so this report cannot cite it. The same window included the owner reviewing held
previews of that page, and as far as anyone has checked, owner and self traffic is not filtered in
this GA4 property. If the owner's own sessions are in those 2 users, the PT edition's figure from
outside readers could be anything from 20 pageviews down to almost none. Nothing in this collection
tells those cases apart. **Read the PT lead as unproven, and do not read it as PT outperforming EN.**

**The read-depth step cannot be split by language either.** `events_article_progress` (25, n=4) and
`events_article_end_reached` (3, n=3) are collected for the whole site, not per article and not per
locale. Whether readers of either edition reached the depth layer is not answerable from this period's
file.

**What it costs.** The owner measures article consumption per language. This period gives that
question no answer. The one bilingual piece published produced no usable per-language reading.

**The change proposed.** Before the next period, exclude the owner's own traffic from the property:
an internal-traffic or developer-traffic exclusion, or another mechanism of the measurement owner's
choosing. Also collect the read-depth events per article and per locale. Both are measurement design,
so this report names them and hands them to `tech-lead` rather than specifying them. **The price of
leaving it:** every bilingual piece published while the owner reviews held previews of it will carry
the same unknown, and the PT/EN comparison he wants will stay unreadable.

No candidate rule. Nothing here is evidence about the voice; it is evidence about the instrument.

### Finding 2 — The LinkedIn post is the site's largest inbound source, but this period's figures cannot attribute it to the article

**What the numbers show.** LinkedIn is the largest referrer in the window: 16 of 28 sessions, and 8 of
those 16 were engaged. On the platform side, the period's only post reached 171 impressions and drew 1
reaction. No comment count was visible.

**The figures.**

```
figure: ga4 sessions_linkedin 16 28
figure: ga4 engaged_sessions_linkedin 8 16
figure: linkedin impressions_post_ai-answers 171 171
figure: linkedin reactions_post_ai-answers 1 171
```

**Where the chain breaks.** `sessions_linkedin` counts every LinkedIn referral to the site. That
includes the owner's profile and any older post, not only this post, and the collection does not
split it by landing page. So the step from 171 impressions to a visit to an article read has no
measured link in it. The figures in the file are consistent with the post driving most of those 16
sessions, and equally consistent with it driving few. The same owner-traffic bound from Finding 1
applies to these sessions too.

**What it costs.** The one distribution channel the period actually used cannot be evaluated: not its
click-through and not which language edition its visitors landed on. The post linked to `/en/`, per
the standing convention, so a PT reader arriving from it would have had to switch editions. Whether
any did cannot be read from this file.

**The change proposed.** Collect LinkedIn sessions by landing page next period. That takes no new
instrumentation, only a second GA4 dimension in the collection step. With that, impressions to visits
for the post's own target URL can be read directly, per edition. **The price of leaving it:** the
post-to-read step stays an inference, and any later rule about how posts are written will rest on it.

**No candidate rule, deliberately.** The figures above could be quoted as evidence, but one post with
one reaction and no baseline gives no variation for a rule about the post's wording to explain. A
candidate drawn from them would be a story about n=1 posts. If a later period has two or more posts to
compare, those figures can carry one.

## What I would leave alone

- **Instagram (6 sessions, 1 engaged).** No Instagram post was collected for the window, so there is
  nothing to attribute these sessions to. Six sessions are too few to act on.
- **`events_share_complete` (1, n=1).** A single share event from a single user, in a window that
  includes the owner's own review sessions. It cannot be told apart from the owner testing the share
  control.
- **`pageviews_article_my-commitment_en` (4, n=1).** This is an earlier piece read by one user. It does
  not belong to this period's publication and says nothing about it.
- **Totals (28 sessions, 8 users, 53 pageviews).** With no baseline, these describe the period and
  cannot show a trend.

---

This rite returns no verdict and gates nothing. It produces observations for the owner and
nothing else — the same constraint `/sprint-review` carries, for the same reason: marketing
judgement has no ruler, and a gate with no ruler grades taste.
Nothing here files an Issue. Only the owner opens work.
