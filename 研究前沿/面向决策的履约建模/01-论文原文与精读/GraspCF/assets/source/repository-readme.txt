<h1 align="center">GraspFC-CF</h1>
<p align="center"><b>Auditing grasp-feasibility predictors with planner-verified counterfactuals</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/benchmark-GraspNet--1B-1b75bb.svg">
  <img src="https://img.shields.io/badge/python-3.9%2B-3776ab.svg">
  <img src="https://img.shields.io/badge/license-MIT-green.svg">
  <img src="https://img.shields.io/badge/audit-no%20planner%20needed-444.svg">
</p>

<p align="center">
  <img src="assets/blind_vs_safe.gif" width="92%">
</p>
<p align="center"><sub>Same scene, same 20 candidate grasps, two predictors. Left: a pose-only pick
drives into the corridor obstacle, a planner-verified collision. Right: a scene-aware
pick reaches a clear grasp. Isaac Sim replay; robot poses are exact PyBullet forward
kinematics.</sub></p>

A grasp is feasible only if the arm can reach the pose **and** the path to it is
clear. On real point-cloud benchmarks, feasibility predictors already score close
to perfect — but that number doesn't tell us whether a model is reading the path,
or just the pose. We built a test for that: hold one grasp fixed, drop an obstacle
into its approach path, and ask a real motion planner for the new answer. The
obstacle is visible to the model and the correct answer changes. Across every
predictor we test, the score barely moves (CF-pair AUROC 0.47–0.504, chance is
0.5), even though natural-benchmark AUROC for the same models is 0.92–0.996.

The predictors don't all fail the same way, and the signal isn't unrecoverable: a
small model supervised on *clearance* instead of the raw pass/fail label, trained
on the same unmodified benchmark and never shown a counterfactual scene, reaches
CF-pair AUROC 0.983. That's the main finding: the information is there in the
input, standard training just never asks a model to use it.

This repo releases the **counterfactual benchmark**, the **three interventional
metrics**, the **relabeling pipeline**, and an **audit harness that scores
obstacle-awareness with no motion planner in the loop**.

<p align="center">
  <img src="assets/hero_cf_pair.png" width="74%">
</p>
<p align="center"><sub>One grasp on a real GraspNet-1B scene, scored twice. The only change is a box added
to the approach corridor (red). The planner flips feasible to infeasible; the
predictor returns the identical <i>p</i>(feasible).</sub></p>

## Audit your own model (no planner)

Wrap your model behind one `score()` method and run it on the released pairs:

```python
from graspfc_cf import CFBenchmark, audit, format_report
from graspfc_cf import SceneBlindBaseline, ClearanceReadout

bench = CFBenchmark.load("data/sample")          # or data/cf + --scenes-dir for the full set
print(format_report(audit(SceneBlindBaseline(), bench), "pose-only reference"))
print(format_report(audit(ClearanceReadout(), bench), "clearance reference"))
```

```
== pose-only reference ==  CF-pair AUROC 0.500   pick-clear 0.500   within-grasp 0.500
== clearance reference ==  CF-pair AUROC 1.000   pick-clear 1.000   within-grasp 1.000
```

A pose lookup scores the clear and obstacle-inserted variants identically, so it
lands at chance by construction; a geometric read of the same points separates
them. Scoring the 1,065-pair set takes under a minute, against roughly 45 minutes
of planner time. Plug in your network with
[`audit/example_predictor.py`](audit/example_predictor.py); the three metrics are
defined in [`docs/protocol.md`](docs/protocol.md).

| Metric | Question | Chance |
|---|---|---|
| CF-pair AUROC | Rank the clear variant above its obstacle-inserted twin at the same pose | 0.5 |
| Within-grasp AUROC | Inside one grasp, rank the feasible obstacle offsets above the infeasible ones | 0.5 |
| Pick-clear accuracy | Of two same-pose candidates, is the clear one scored higher | 0.5 |

## The gap shows up in every model we test

Natural AUROC ranks feasible above infeasible grasps on the unmodified benchmark;
CF-pair AUROC ranks the clear scene above the same grasp with an obstacle added at
the identical pose. Every predictor here is trained from scratch, re-implemented
under a shared protocol, or run from the authors' own released weights.

| Model | Input | Params | Regime | Natural | CF-pair |
|---|---|---:|:--:|---:|---:|
| GraspFC-NNet | pose + crop | 1.65M | R0 | 0.995 | 0.491 |
| GraspFC-Conv3D | pose + voxels | 9.7M | R0 | 0.976 | 0.497 |
| GraspFC-PTX | pose + cloud | 9.0M | R0 | 0.996 | 0.498 |
| SceneCollisionNet | voxels | 26M | R1+R2 | 0.964 | 0.470 |
| PIGINet | tokens | 31M | R1+R2 | 0.960 | 0.500 |
| NFC | depth | 22.8k | R1 | 0.965 | 0.504 |
| AGFP-Net | depth views | 33M | R1 | 0.920 | 0.498 |
| GRN | box + pose | 2.3M | R2 | 0.995 | 0.500\* |

<sub>R0 trained from scratch on our labels, R1 published representation re-implemented on our labels, R2 authors' released weights on their own data. \*GRN detects that an obstacle was inserted but does not resolve its shape below the bounding box — its entry is a same-bounding-box shape swap, not an insertion. Full per-model breakdown: <a href="docs/models.md">docs/models.md</a>.</sub>

Across all labeled grasps, collision decides 64.3% of infeasibility (49.0% blocked
transit, 15.3% blocked approach; the rest is reachability). Natural benchmarks
almost never place two grasps at the same pose on opposite sides of a collision
boundary, so a model can score well on them without ever being asked to read one.

## But not for the same reason

The eight predictors resolve geometry down to very different resolutions, and stop
tracking the planner below that point. One aggregate number would hide five
distinct mechanisms:

| Predictor | Responds to | Stops below |
|---|---|---|
| GRN | obstacle presence, bounding box | shape inside the box |
| SceneCollisionNet | contact, coarsely | its 12.5 cm voxel |
| PIGINet | object tokens | corridor-level geometry |
| GraspFC-NNet | obstacle presence | whether it actually blocks |
| GraspFC-Conv3D | voxel grid | any obstacle |
| GraspFC-PTX | no measurable response | any obstacle |
| NFC | grasp pose only | its own neighbor channel |
| AGFP-Net | 5-view depth | any obstacle |

This also rules out the simplest theoretical explanation. A max-pooled point
encoder isn't required by construction to miss an inserted point — we measured it
directly: the obstacle raises 31.5 of 256 pooled channels and moves the feature
*more* than a plain average would. What's missing is direction, not magnitude —
the shift doesn't consistently point toward "infeasible" (mean cosine alignment to
the readable direction: +0.043). Training on the natural labels never required the
shift to point anywhere in particular.

## On released weights, in each model's own environment

The same pattern appears when published models run from their own released
weights on their own benchmarks, so it isn't a re-implementation artifact.

<p align="center">
  <img src="assets/grn_panda.gif" width="49%">
  <img src="assets/pr2_kitchen.gif" width="49%">
</p>
<p align="center"><sub>Real predictions in each model's own scene. Left: GRN's panda_3d_4 (scene_00003).
GRN drops pitch, so a pole leaning 40° into the corridor reads as an upright, clear
box and scores the grasp feasible (<b>p = 0.85</b>); the arm follows it into the
lean. Right: PIGINet's exact PR2 kitchen; replaying the authors' saved scene, it
calls a planner-blocked pick feasible <b>90% of the time</b> against a ground truth
of 0% (clear-vs-blocked AUROC 0.47).</sub></p>

More natural data doesn't close the gap (CF-pair stays at 0.498), and the deployed
model doesn't improve across five fine-tuning recipes. Training the same
architecture from scratch on counterfactual data does recover it (0.991) — but
only near the placements it was trained on; move the obstacle elsewhere and the
score falls back toward chance. A clearance-aware read of the same points, trained
only on the original benchmark, reaches 0.983 without ever seeing a counterfactual
scene. Clearance has to be supervised directly — recognition and reconstruction
objectives don't produce it as a byproduct.

## What is here

| | |
|---|---|
| **Benchmark** | Same-pose counterfactual pairs, graded obstacle-offset groups, and held-out shape / placement / size / standoff / resting / transit splits over public GraspNet-1B scenes, with planner-verified labels and a [datasheet](docs/datasheet.md). |
| **Metrics** | CF-pair AUROC, within-grasp AUROC, pick-clear accuracy, with bootstrap CIs. |
| **Audit harness** | Score any predictor on the released pairs with no planner. Pose-only and clearance references bracket the result. |
| **Relabeling pipeline** | The RRT-Connect Franka oracle that made the labels. Regenerate a new obstacle family from one geometry spec; the only step that calls a planner. Cross-checked against three other planners and a second arm (xArm6): the flip is not a property of one planner or robot. |

```
graspfc_cf/   audit package: schema, dataset, metrics, predictor, audit
audit/        run_audit.py CLI + example_predictor.py template
relabel/      planner-verified relabeling pipeline (oracle, obstacles, driver)
data/         sample/ smoke set + download.py + schema notes
docs/         datasheet, protocol, models, reproduce, leaderboard
```

## Setup and use

```bash
cd graspfc-cf
pip install -e .                                    # numpy, scipy, scikit-learn (CPU)
python audit/run_audit.py --bench data/sample       # references on the smoke sample

# audit your own model on the full set
python audit/run_audit.py --bench data/cf --scenes-dir data/graspnet_scenes \
    --predictor audit.example_predictor:load --split novel

# regenerate labels for a new obstacle family (needs pybullet; the only planner step)
python relabel/relabel.py --family corridor --out data/cf \
    --grasps-dir <valid_grasps> --clouds-dir <pcs_aligned> --rows rows.json
```

## Data

Annotations are light (grasp poses, obstacle specs, planner labels) and reference
GraspNet-1B scenes by identifier; the scenes stay under the GraspNet-1B license and
download separately. `data/sample/` is self-contained synthetic and runs with
nothing downloaded. Schema and steps: [data/README.md](data/README.md).

> **Status.** Code, harness, and pipeline are here. The annotations, trained
> checkpoints, and a public leaderboard are hosted separately; paste links into
> [`data/sources.json`](data/sources.json) and `python data/download.py` (`--models`
> for weights) fetches them. Until then the harness runs on the bundled sample.

## Scope

This is a diagnostic, not a certified safety check: every label comes from a
sampling-based planner in simulation for one robot arm (cross-checked against
three further planners and a second arm as a control), and the obstacles are
geometrically inserted, planner-verified primitives rather than physically settled
objects — although the same collapse also holds for a real GraspNet-1B object
placed next to the target. The clearance-supervised read that recovers the signal
is bound to the placements it was trained near; a representation that generalizes
across obstacle placement is an open problem.

## License

Released under the MIT License (see [LICENSE](LICENSE)); the benchmark derives from
GraspNet-1Billion, whose scenes remain under its license.
