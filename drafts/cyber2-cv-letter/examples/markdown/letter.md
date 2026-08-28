---
name: Sarah Connor
tagline: AI Security Engineer · Adversarial ML & Red Teaming
email: sarah.connor@ena.one
phone: +1 555 0142
location: Austin, TX
links: [ena.one, github.com/sconnor, linkedin.com/in/sarahconnor]
date: 28 August 2026
paper: a4
font-chrome: IBM Plex Mono
font-body: IBM Plex Sans
---

Dear Hiring Manager,

Cortex Labs' recent engineering post on the automated red-teaming pipeline
behind your assistant launch is the reason I'm writing today rather than
just bookmarking your careers page. Adversarial robustness for
production LLM systems is the specific problem I've spent the last three
years on, and it is rare to see a team publish the actual mutation
strategy behind their fuzzing harness instead of a marketing summary of
"safety testing."

At Cyberdyne Systems I built and ran exactly that kind of system: an
automated prompt-injection fuzzing harness driven by a custom mutation
engine over a 12,000-seed corpus, wired directly into the release-gate CI
job rather than run as a separate, easily-skipped audit step. The harder
problem wasn't finding jailbreaks — the harness surfaced 40+ high-severity
ones across six production features in its first quarter — it was
building a triage process the app-sec team could sustain weekly without
burning out on false positives, which meant investing as much in the
scoring and deduplication logic as in the mutations themselves.

Your team's public work on constrained decoding for tool-call outputs
tackles the same class of problem from the model side rather than the
harness side, and I'd like to compare notes on where the two approaches
overlap. The scoped-tool-permission pattern in your last release notes
also mirrors a mitigation I shipped after a red-team engagement uncovered
a similar data-exfiltration path in an internal chatbot.

I'd welcome the chance to talk through how this experience could plug
into Cortex Labs' red-teaming roadmap. I'm available for a call any
weekday and can share the fuzzing harness's design doc on request.

Best regards, \
Sarah Connor
