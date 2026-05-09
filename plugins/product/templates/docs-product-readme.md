# docs/product/

Product artifacts produced by the `product` plugin. See the plugin's
`product-conventions` skill for format rules and `product-cycle` for the
methodology.

## Layout

```
docs/product/
├── README.md           ← this file
├── research/           ← market-scans (SCAN-NNNN)
├── discoveries/        ← hypotheses (HYP-NNNN)
├── prds/               ← Product Requirements Documents (PRD-NNNN)
├── specs/              ← implementation specs (SPEC-NNNN)
├── validations/        ← post-launch validations (VAL-NNNN)
└── backlog.md          ← rolling prioritization snapshot
```

## Artifact lifecycle

```
HYP-NNNN ──► PRD-NNNN ──► SPEC-NNNN ──► VAL-NNNN
   │            │            │             │
   draft     draft        draft         active (with verdict)
     │          │            │
   active    active       active
     │          │            │
   accepted  accepted    accepted
     │          │
   archived  archived
   superseded superseded
```

Status transitions are documented in `product-conventions/SKILL.md`.

## Cross-references

Product artifacts cross-link to architectural decisions in
`docs/architecture/decisions/` (from the `archforge` plugin) via the
`links_to` field in front-matter. The graph is what makes the marketplace
compound.

## Index

<!--
Auto-maintained by /product:status (eventually). For v0.1 maintain manually
or just let it be — running /product:status reads the directory directly.
-->
