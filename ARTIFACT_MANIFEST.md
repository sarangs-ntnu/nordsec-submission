# Artifact Manifest

This document lists the artifacts included in the anonymous review repository.

## 1. System Model

### data/01_system_model/components.csv

Contains the 34 autonomous-vessel components used in the case study.

Expected distribution:

- Layer 1: 22 components
- Layer 2: 8 components
- Layer 3: 4 components

### data/01_system_model/component_classes.csv

Contains the primary and secondary ThreatSpider class assignments for the 34 components.

### data/01_system_model/system_graph_relations.csv

Contains 40 directed relations between components in the autonomous-vessel system graph.

## 2. CTI and Threat Mappings

### data/02_cti_mappings/component_attack_mapping.csv

Contains 85 component-to-attack mappings.

### data/02_cti_mappings/attack_mitre_mapping.csv

Contains 46 candidate mappings to:

- MITRE ATT&CK
- MITRE ATT&CK for ICS
- MITRE ATLAS

### data/02_cti_mappings/component_vulnerability_mapping.csv

Contains 63 component-to-vulnerability or weakness mappings.

## 3. Mitigations

### data/03_mitigations/existing_mitigations.csv

Contains 34 initial component-level mitigation records.

Component-specific ThreatSpider mitigation-effectiveness records will be added separately.

## 4. Risk Inputs

### data/04_risk_inputs/consequence_mapping.csv

Contains 66 mappings between component-level threats or vulnerabilities and their potential consequences.

Additional ThreatSpider risk inputs will be added separately, including:

- component criticality values
- threat likelihood values
- vulnerability likelihood values
- mitigation effectiveness values

## 5. Risk Outputs

### data/05_risk_outputs/

Reserved for final ThreatSpider risk-assessment results.

## 6. Summary Data

### data/06_summary/base_artifact_counts.csv

Contains the validated record counts for the base artifact package.

## 7. Source Workbook

### data/autonomous_vessel_case_study_tables.xlsx

An anonymized workbook containing the human-readable versions of the system-modeling and mapping tables.

## 8. Validation Scripts

### scripts/export_workbook.ps1

Exports the worksheets of the anonymized workbook into UTF-8 CSV files.

### scripts/clean_component_classes.ps1

Removes section headings and non-component rows from the component-class assignment export.

### scripts/clean_mapping_files.ps1

Removes section headings and repeated headers from the mapping CSV files.

### scripts/validate_base_artifact.ps1

Validates record counts, layer distribution, component references, and system-graph consistency.

## 9. Excluded Material

The anonymous review repository does not include:

- author identities
- institutional affiliations
- acknowledgements or funding information
- credentials or access tokens
- raw database backups
- Docker images
- personal or institutional communication
- the submitted manuscript
- the complete ThreatSpider source code

<!-- CANONICAL-COUNTS-START -->
## Canonical Dataset Counts

| File | Records |
|---|---:|
| `data/01_system_model/components.csv` | 34 |
| `data/01_system_model/component_classes.csv` | 34 |
| `data/01_system_model/system_graph_relations.csv` | 41 |
| `data/02_cti_mappings/component_attack_mapping.csv` | 85 |
| `data/02_cti_mappings/attack_mitre_mapping.csv` | 46 |
| `data/02_cti_mappings/component_vulnerability_mapping.csv` | 63 |
| `data/03_mitigations/existing_mitigations.csv` | 34 |
| `data/03_mitigations/component_specific_mitigations.csv` | 212 |
| `data/04_risk_inputs/consequence_mapping.csv` | 66 |
| `data/04_risk_inputs/component_criticality.csv` | 34 |
| `data/04_risk_inputs/failure_mode_metric_mapping.csv` | 201 |
| `data/05_risk_outputs/risk_records.csv` | 1513 |
| `data/05_risk_outputs/risk_formula_audit.csv` | 1513 |

Supporting summaries:

- `data/06_summary/base_artifact_counts.csv`
- `data/06_summary/risk_output_summary.csv`
- `data/06_summary/risk_formula_audit_summary.csv`
- `data/06_summary/implementation_mismatch_by_consequence.csv`

The canonical system graph contains 41 relations. The mitigation dataset
contains 212 component-specific records covering all 34 modeled components.
<!-- CANONICAL-COUNTS-END -->

