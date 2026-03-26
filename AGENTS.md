# AGENTS.md

## Language

- Think and reason in English internally.
- All responses and outputs to the user must be in Japanese.

## Azure Infrastructure

- All Azure infrastructure must be defined using **Bicep** templates.
- Do not use ARM JSON templates, Terraform, or Pulumi for infrastructure definitions.
- Place Bicep files under the `infra/` directory following the `azd` convention.
- Use Bicep modules to keep templates modular and reusable.

## Deployment

- All infrastructure must be deployable via **Azure Developer CLI (`azd`)**.
- Maintain a valid `azure.yaml` at the repository root that conforms to the `azd` schema.
- Ensure `azd up`, `azd provision`, and `azd deploy` work correctly.
- Use `azd` environment variables and parameters for configuration rather than hard-coding values.
