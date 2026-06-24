# xano-community templates

All templates live in the **xano-community** GitHub org:
https://github.com/orgs/xano-community/repositories

Don't hardcode this list — it grows. List the org live to see everything:

```sh
gh repo list xano-community --limit 100
# or:
gh api "orgs/xano-community/repos?per_page=100" \
  --jq '.[] | "\(.name) — \(.description // "")"'
```

Always read the chosen repo's README before importing — its **Install** section
names the directory to push and any required configuration.

## Two layouts

### Full apps

A complete backend, usually with a frontend and a multidoc bundle:

```
<repo>/
├── backend/        # the pushable XanoScript (push THIS dir)
│   ├── api/  function/  table/  workflow_test/  workspace/
├── frontend/
│   └── index.html  # single-file UI; set API_BASE near the top
└── multidoc/
    └── <repo>.xs   # the whole backend as one ---joined bundle
```

Push with: `xano workspace push -d ./backend -w <id>`

Examples: `todo-app`, `support-ticketing`, `client-intake`, `purchase-approvals`,
`asset-tracking`, `reconciliation-workbench`.

### Integrations

A bundle of functions (and often tables) that wrap a third-party API. Code sits
at the repo root, and there are environment variables to set:

```
<repo>/
├── functions/      # e.g. stripe_create_customer.xs
├── tables/         # provisioned tables (if any)
└── .env.example    # the env vars the integration expects
```

Push with: `xano workspace push -d . -w <id>`, then set the env vars from
`.env.example` in the Xano workspace (dashboard → environment variables). These
templates are called from your own functions/APIs via `function.run "<name>"`.

Examples: `integration-stripe-payments`, `integration-resend-email`,
`integration-openai-ai`, `integration-hubspot-crm`, `integration-twilio-sms`,
`integration-slack-messaging`, plus many more (`integration-*`).

## Matching a user's goal to a template

- "todo / task board" → `todo-app`
- "support desk / tickets" → `support-ticketing`
- "client / customer intake form" → `client-intake`
- "purchase approvals / requisitions" → `purchase-approvals`
- "IT asset tracking" → `asset-tracking`
- "accept payments" → `integration-stripe-payments` / `integration-square-payments`
  / `integration-paypal-payments` / `integration-adyen-payments`
- "send email" → `integration-resend-email` / `integration-mailchimp-email`
- "send SMS / WhatsApp" → `integration-twilio-sms`
- "Slack / Discord messages" → `integration-slack-messaging` /
  `integration-discord-messaging`
- "CRM" → `integration-hubspot-crm` / `integration-salesforce-crm`
- "AI / LLM calls" → `integration-openai-ai` / `integration-gemini-ai` /
  `integration-xai-ai`

When unsure, list the org and confirm the pick with the user before importing.
