# Risk Formula Audit

## Purpose

This audit evaluates whether the stored Batch 12 risk results can be
reproduced from the evaluated ThreatSpider implementation and examines
the effect of two implementation observations:

1. I2CF and I2MF are populated using OOI-derived values.
2. Confidentiality, Integrity, and Availability contributions are loaded
   but omitted from the implemented Impact sum.

## Implemented Calculation Chain

Threat likelihood:

- Threat records use the stored CVSS exploitability metric.
- Vulnerability records use EPSS normalized to the CVSS exploitability
  scale.

Impact in the evaluated implementation:

`Impact = Operational + Safety + Information + Financial + Staging +
Environmental + Reputation`

Each term is the consequence-specific component metric multiplied by its
configured impact factor.

Detectability:

`Detectability = 1 - maximum applicable mitigation efficiency`

Risk:

`Unmitigated Risk = Likelihood × Impact`

`Residual Risk = Likelihood × Impact × Detectability`

A residual risk at or below 6.37 is classified as tolerable.

## Reproduction Result

All 1513 stored Impact values are reproduced within an absolute
tolerance of 0.00001.

- Average absolute difference: 0.0000029132
- Maximum absolute difference: 0.0000048
- Substantive implementation mismatches: 0

The small differences are consistent with numeric rounding or database
serialization.

## I2CF and I2MF Observation

I2CF is used by 51 risk records. I2MF is not used by any Batch 12 risk
record.

Because the evaluated build stores I2CF equal to OOI for all 34
components, the affected records cannot be recalculated using an
independently derived I2CF value from the available snapshot.

## CIA-Restored Sensitivity Analysis

The evaluated implementation loads the following configured factors:

- Confidentiality: 0.7
- Integrity: 1.0
- Availability: 1.0

These contributions are not included in the implemented Impact sum.

Adding these contributions while preserving all other stored values
produces:

- 866 records with a non-zero additional CIA contribution
- 62 non-tolerable records instead of 29
- 33 changed tolerability classifications

This is reported as a sensitivity analysis rather than a corrected
ground-truth result because the I2CF assignment issue remains unresolved.

## Artifact Files

Inputs:

- `data/04_risk_inputs/component_criticality.csv`
- `data/04_risk_inputs/failure_mode_metric_mapping.csv`
- `data/04_risk_inputs/impact_factors.csv`
- `data/04_risk_inputs/risk_thresholds.csv`
- `data/04_risk_inputs/fmmt_metric_ambiguities.csv`
- `data/04_risk_inputs/fmmt_consequence_ambiguities.csv`

Outputs:

- `data/05_risk_outputs/risk_records.csv`
- `data/05_risk_outputs/risk_formula_audit.csv`
- `data/05_risk_outputs/risk_formula_affected_records.csv`
- `data/06_summary/risk_formula_audit_summary.csv`
- `data/06_summary/implementation_mismatch_by_consequence.csv`
