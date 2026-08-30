#import "/lib.typ": cv-resume

// One-flag variant surface (spec §9.3): `typst compile --input accent=red
// --input variant=plain ...` flips these without touching a single line of
// content below — see the Makefile targets and README. Defaults match the
// shipped, safest configuration (decision 13): show-logos off, themed green.
#let input(key, default) = sys.inputs.at(key, default: default)

#show: cv-resume.with(
  author: (
    name: "Sarah Connor",
    tagline: "AI Security Engineer · Adversarial ML & Detection",
    email: "sarah@example.com",
    location: "Los Angeles, CA",
    links: ("example.com", "github.com/sconnor", "linkedin.com/in/sconnor"),
  ),
  accent: input("accent", "green"),
  accent-scope: input("accent-scope", "full"),
  variant: input("variant", "themed"),
  paper-size: input("paper-size", "a4"),
  show-logos: input("show-logos", "false") == "true",
  show-icons: input("show-icons", "false") == "true",
  show-footer: input("show-footer", "false") == "true",
)

= Summary

AI security engineer specializing in adversarial ML detection and red-teaming for
production LLM systems. Shipped detection infrastructure handling 50k+ req/s with
sub-second alert latency.

= Experience

== Senior AI Security Engineer | Jun 2023 – Present

// Root-relative path (not "logos/cyberdyne.png"): when show-logos is on,
// markup.typ rebuilds this image() call with alt text attached (§5), and a
// path relative to *this* file would fail to resolve from there.
_[#image("/examples/typst/logos/cyberdyne.png")] Cyberdyne Systems | Los Angeles, CA_

Cut adversarial-example detection latency 4x by rewriting the [batch, heads, seq, seq]
scoring path to run inline with inference rather than as a post-hoc batch job.

- Built a red-team harness that found 12 prompt-injection classes missed by the prior
  eval suite, raising the pre-release catch rate from 61% to 94%.
- Led migration of the model-serving detection pipeline to a streaming architecture,
  cutting p99 alert latency from 4.2s to 380ms.
- Mentored two junior engineers on adversarial evaluation methodology; both now own
  detection surfaces independently.

`PyTorch · vLLM · Triton · Kubernetes`

== AI Security Engineer | Jan 2021 – May 2023

_Widget Robotics | Remote_

Owned anomaly scoring for a fleet-telemetry pipeline processing 50k events/s.

- Shipped an anomaly scoring service that cut false-positive alert volume 70% by
  replacing static thresholds with a learned per-device baseline.
- Built the eval harness now used across three teams to benchmark detection recall
  against a held-out attack corpus before every model release.

`Python · scikit-learn · Kafka · Terraform`

== Machine Learning Engineer | Aug 2019 – Dec 2020

_Nova Systems Analytics | San Diego, CA_

- Trained and deployed a fraud-scoring model that reduced chargeback losses 18%
  in its first quarter in production.
- Instrumented model-serving latency tracing, cutting p99 debugging time from days
  to hours for the on-call rotation.

= Skills

/ Detection: Adversarial example detection, Anomaly scoring, Red-teaming, Eval design
/ Adversarial ML: Prompt injection, Model extraction, Data poisoning
/ Infra: Kubernetes, Terraform, Triton, CUDA, Kafka

= Education

== MS Computer Science | 2019

_University of California, San Diego_

= Certifications

== OSCP | 2022

_Offensive Security Certified Professional_
