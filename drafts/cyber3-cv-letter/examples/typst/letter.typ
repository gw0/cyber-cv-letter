#import "@local/cyber-cv-letter:0.1.0": letter

#show: letter.with(
  author: (
    name: "Sarah Connor",
    tagline: "AI Security Engineer · Adversarial ML & Red Teaming",
    email: "sarah@sconnor.dev",
    location: "Fremont, CA",
    links: ("github.com/sconnor", "linkedin.com/in/sarahconnor"),
  ),
  accent: sys.inputs.at("accent", default: "red"),
  accent-scope: sys.inputs.at("accent-scope", default: "full"),
  variant: sys.inputs.at("variant", default: "themed"),
  paper: sys.inputs.at("paper", default: "a4"),
  show-footer: sys.inputs.at("show-footer", default: "false") == "true",
  show-icons: sys.inputs.at("show-icons", default: "false") == "true",
  date: "1 September 2026",
)

I am writing to apply for the Staff AI Security Engineer role on your detection team. Over the past six years I have moved from applied machine learning into security engineering and, most recently, detection engineering for production ML systems — a path that gives me both a builder's instincts and an operator's sense of what actually holds up in production.

At Cyberdyne Systems I built an adversarial-example detector that cut false negatives by 40% and now runs in front of every inference request our platform serves. At Skynet Analytics I caught two supply-chain compromises in third-party model artifacts before they reached production. In both roles I led the red-team exercises that found the gaps our defenses were built to close.

Your team's recent work on prompt-injection detection is exactly the kind of problem I have spent the last two years working on, and I would welcome the chance to bring that experience to your organization.

Thank you for your consideration.
