#import "/lib.typ": cv-letter

// One-flag variant surface — see cv.typ.
#let input(key, default) = sys.inputs.at(key, default: default)

#show: cv-letter.with(
  author: (
    name: "Sarah Connor",
    tagline: "AI Security Engineer · Adversarial ML & Detection",
    email: "sarah@example.com",
    location: "Los Angeles, CA",
    links: ("example.com", "github.com/sconnor"),
  ),
  date: "28 August 2026",
  accent: input("accent", "green"),
  accent-scope: input("accent-scope", "full"),
  variant: input("variant", "themed"),
  paper-size: input("paper-size", "a4"),
  show-footer: input("show-footer", "false") == "true",
)

I have spent the last three years building detection systems that assume the adversary
reads the same papers I do. Vantage Security's recent work on prompt-injection
taxonomies is the first public research I've seen that treats this as an adversarial
classification problem rather than a filtering problem, and I would like to help build it.

At Cyberdyne Systems, I led the migration of our model-serving detection pipeline from
a nightly batch job to a streaming architecture — a decision that looked obvious in
retrospect and was not obvious at the time. The batch job had grown 40% slower every
quarter as traffic scaled, and the team's first instinct was to throw more compute at
it. I spent two weeks profiling instead, found the actual bottleneck was a synchronous
feature-store round-trip on the critical path, and rebuilt around an async prefetch
queue. p99 alert latency dropped from 4.2 seconds to 380 milliseconds with no
additional hardware, and the on-call rotation stopped paging on transient batch
backlog within the first week of the change shipping.

Vantage's engineering blog post on evaluating red-team coverage with class-balanced
sampling matches a problem I hit directly: our own eval suite was systematically blind
to a whole family of prompt-injection attacks because our sampling was
frequency-weighted rather than class-weighted. I would bring that same lesson, already
paid for once, to your evaluation harness from day one.

I would welcome the chance to talk about where your detection roadmap is headed and
where I could contribute first. I'm happy to walk through either project in more
depth, or to bring a short write-up of the red-team harness to a first conversation.
