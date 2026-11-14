# AneePay Docs

Documentation site for **AneePay** — a non-custodial crypto payment gateway on
Polygon that accepts USDT, USDC, and DAI with a flat 0.5% on-chain fee.

Built with [MkDocs](https://www.mkdocs.org/) and
[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

- **Live site:** <https://aneepay.github.io/aneepay-docs/>
- **LLM-friendly index:** [`docs/llms.txt`](docs/llms.txt)

## Contents

The docs cover the full integration surface:

- Getting started, merchant onboarding, and payment lifecycle
- Payments, hosted checkout, split payments, reconciliation
- Webhooks: payload, signatures, retries, testing
- API reference, errors, sandbox, and security best practices
- CMS plugins for WooCommerce, OpenCart, and PrestaShop
- x402 machine payments and smart contract reference
- Partner program, merchant dashboard, and legal pages

## Local development

Requires Python 3.9+.

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

mkdocs serve          # http://127.0.0.1:8000
mkdocs build --strict # production build into site/
```

## Contributing

1. Edit or add Markdown files under `docs/`.
2. Register new pages in the `nav` section of [`mkdocs.yml`](mkdocs.yml).
3. Update [`docs/llms.txt`](docs/llms.txt) if you add top-level content.
4. Run the same checks as CI before opening a PR:

```bash
mkdocs build --strict
markdownlint-cli2 "docs/**/*.md"
lychee --config lychee.toml "docs/**/*.md"
```

CI runs on every pull request (Markdown lint, link check, strict build), and
pushes to `main` deploy the site to GitHub Pages.

## License

Content is released under [CC0 1.0 Universal](LICENSE).
