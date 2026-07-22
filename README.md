# Anonymous Artifact: CTI-Driven Threat Modeling for an Autonomous Vessel

This repository contains anonymized research artifacts prepared for a double-blind conference submission.

The artifact documents the translation of a layered and risk-centric threat model for a generalized autonomous vessel into a component-oriented and CTI-supported threat-modeling workflow.

## Current Artifact Contents

The current data package includes:

- 34 autonomous-vessel components across three architectural layers
- 34 ThreatSpider-oriented component class assignments
- 40 system-graph relations
- 85 component-to-attack mappings
- 46 candidate MITRE ATT&CK, ATT&CK ICS, and ATLAS mappings
- 63 component-to-vulnerability mappings
- 34 existing mitigation records
- 66 consequence mappings

## Repository Structure

data/
  autonomous_vessel_case_study_tables.xlsx
  01_system_model/
  02_cti_mappings/
  03_mitigations/
  04_risk_inputs/
  05_risk_outputs/
  06_summary/

scripts/
outputs/
evidence/
docs/

## Data Formats

The anonymized Excel workbook is included for convenient human review.

The individual CSV files provide machine-readable versions of the corresponding worksheets. The CSV files use UTF-8 encoding and comma-separated fields.

## Validation

From the repository root, run:

.\scripts\validate_base_artifact.ps1

A successful execution ends with:

BASE ARTIFACT VALIDATION PASSED

## Current Scope

The repository currently contains the system-modeling and mapping artifacts.

ThreatSpider-generated threat records, vulnerability likelihoods, component-specific mitigation effectiveness assessments, component criticality inputs, and final risk outputs will be added separately.

## Excluded Material

The repository does not contain:

- personal data
- author or institutional identifiers
- credentials or access tokens
- production-system data
- database backups
- Docker images
- the complete ThreatSpider source code
- the submitted manuscript

## Anonymity

This artifact is prepared for double-blind peer review.

Author names, affiliations, acknowledgements, local file paths, personal account information, and other identifying information are intentionally excluded.

<!-- ARTIFACT-SUMMARY-START -->
## Artifact at a Glance

The autonomous-vessel case-study artifact contains:

| Artifact element | Records |
|---|---:|
| Components | 34 |
| Layer 1 components | 22 |
| Layer 2 components | 8 |
| Layer 3 components | 4 |
| System graph relations | 41 |
| Component-to-attack mappings | 85 |
| Attack-to-MITRE mappings | 46 |
| Component-to-vulnerability mappings | 63 |
| Existing mitigation records | 34 |
| Component-specific mitigation records | 212 |
| Consequence mappings | 66 |
| Approved risk-assessment records | 1513 |

The 41 system graph relations were reconciled against the evaluated
ThreatSpider database snapshot. The component-specific mitigation dataset
contains 212 analyst-reviewed records across all 34 components.

The stored Batch 12 risk results contain 1513 records. Separate audit files
document the implemented risk formula, the I2CF/I2MF assignment observation,
and the Confidentiality, Integrity, and Availability sensitivity analysis.
<!-- ARTIFACT-SUMMARY-END -->

