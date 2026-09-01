#import "@local/cyber-cv-letter:0.1.0": cv

#show: cv.with(
  author: (
    name: "Sarah Connor",
    tagline: "AI Security Engineer · Adversarial ML & Red Teaming",
    email: "sarah@sconnor.dev",
    location: "Fremont, CA",
    phone: "+1 415 555 0142",
    links: ("github.com/sconnor", "linkedin.com/in/sarahconnor", "sconnor.dev"),
  ),
  accent: sys.inputs.at("accent", default: "red"),
  accent-scope: sys.inputs.at("accent-scope", default: "full"),
  variant: sys.inputs.at("variant", default: "themed"),
  paper: sys.inputs.at("paper", default: "a4"),
  show-logos: sys.inputs.at("show-logos", default: "false") == "true",
  show-icons: sys.inputs.at("show-icons", default: "false") == "true",
  show-footer: sys.inputs.at("show-footer", default: "false") == "true",
  show-notes: sys.inputs.at("show-notes", default: "false") == "true",
)

= SUMMARY

AI security engineer with six years spanning applied machine learning, security engineering, and detection engineering. Builds defenses against adversarial and prompt-injection attacks on production ML systems, and leads red-team exercises against internal LLM deployments.

= EXPERIENCE

== Senior AI Security Engineer | 2023 -- Present

_#box(image("logos/cyberdyne.png", alt: "Cyberdyne Systems logo")) Cyberdyne Systems | Fremont, CA_

Leads detection engineering for production ML systems serving over ten million inference requests a day.

- Built an adversarial-example detector that cut false negatives by 40% against a red-team benchmark suite.
  #quote(block: true)[Runs as a sidecar service in front of the inference API, scoring every request before it reaches the model.]
- Led quarterly red-team exercises against internal LLM deployments, uncovering prompt-injection paths later closed with input sanitization.
- Introduced model-serving anomaly scoring, reducing mean incident detection time from six hours to twenty minutes.

`PyTorch · vLLM · LangChain · Ray`

== Security Engineer | 2021 -- 2023

_Skynet Analytics | Remote_

Owned security for the model-serving platform supporting the company's recommendation and fraud-detection products.

- Built anomaly-detection pipelines for model-serving infrastructure, catching two supply-chain compromises in third-party model artifacts.
- Automated red-team tooling for LLM jailbreak testing, cutting manual review time by 70%.
- Partnered with platform engineering to add authenticated model-artifact signing across the deployment pipeline.

`Terraform · AWS · Python`

== Machine Learning Engineer | 2019 -- 2021

_Tyrell Applied ML | Ljubljana, Slovenia_

Built and shipped machine learning models powering fraud detection and demand forecasting for a fast-growing fintech product.

- Built and shipped fraud-detection models into production, reducing false-positive rates by 25% across the company's core payments pipeline.
- Designed the team's first automated retraining pipeline, cutting model refresh time from weeks to days.
- Mentored two junior engineers on feature engineering and model evaluation practices.

`TensorFlow · scikit-learn · Airflow · Docker`

= SKILLS

/ Security: Burp Suite, Nmap, Metasploit, OSCP methodology, threat modeling
/ ML/AI: PyTorch, vLLM, adversarial robustness, prompt-injection defense
/ Infra: Kubernetes, Terraform, AWS, CI/CD pipeline hardening
/ Practice: Incident response, secure SDLC, red-team exercise design

= EDUCATION

== M.S. Computer Security | 2021

_#box(image("logos/stanford.svg", alt: "Stanford University logo")) Stanford University | Stanford, CA_

== B.S. Computer Science | 2019

_University of Ljubljana | Ljubljana, Slovenia (EU)_

= PROJECTS

== promptfirewall | 2023

_github.com/sconnor/promptfirewall_

= CERTIFICATIONS, AWARDS & PUBLICATIONS

== AI Village CTF -- 1st Place | 2024

_DEF CON_

== Detecting Prompt Injection at Scale | 2024

_arXiv preprint | arxiv.org/abs/2403.09217_

== OSCP -- Offensive Security Certified Professional | 2019

_Offensive Security_
