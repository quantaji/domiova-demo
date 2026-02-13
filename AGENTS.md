# AGENTS.md

## 1. Project summary

This project is a single educational “showcase level” that teaches the biological logic of the menstrual cycle, with a focus on how one follicle becomes the dominant follicle. The level uses a near field vs far field metaphor.

1. The near field is the ovary arena where follicles compete.
2. The far field is the pituitary side that outputs hormone waves and receives feedback.
3. Time is shown as a 1D rotating compass in the bottom right. It represents cycle progression and allows time scaling by stage.

The core learning thread is one causal chain.

1. An early FSH window recruits a cohort.
2. Estradiol (E2) and inhibin B reduce overall FSH, so weaker follicles lose support and undergo atresia.
3. The dominant follicle gains LH responsiveness, survives low FSH, and then sustains high E2 long enough to flip feedback and trigger the LH surge.

## 2. Level structure by stages

### Stage 1. Recruitment and awakening (simplified)

Goal: introduce the idea of rhythmic endocrine signals and cohort recruitment.

1. Time runs fast.
2. A hormone “wave” arrives from the far field.
3. Player performs a simple timing input to “wake” follicles.
4. This stage is a metaphor. It is not meant to be physiologically exact for primordial activation.
5. Visual note: the wave can be rainbow colored to represent many hormones at once.

Output: 10 to 20 follicles are awake and enter competition.

### Stage 2. Competition among a cohort (main gameplay)

Goal: embody follicle level competition under changing FSH and emerging LH relevance.

1. Time slows to about one in game second per one in game hour.
2. Player becomes one follicle in the arena.
3. FSH and LH arrive as waves from the far field.
4. Waves manifest as pellets or bubbles in the near field.
5. Player moves left and right to collect pellets.
6. Energy increases from collecting pellets.
7. Higher energy increases mobility.
8. NPC follicles also collect pellets and maintain their own energy.
9. NPC follicles die off when they cannot maintain energy. This is atresia as “resource starvation.”

Color convention:

1. FSH pellets are pink.
2. LH pellets are yellow.

#### Stage 2.1. LH receptor unlock on granulosa cells

Goal: show the developmental transition that supports survival when FSH falls.

1. When the player energy reaches two segments, granulosa LH receptors unlock.
2. After unlock, LH pellets can contribute to the player energy.
3. This represents reduced dependence on high FSH during late follicular development.

Presentation:

1. Show a receptor ring or icon state change.
2. Keep it readable. Use a clear HUD indicator.

#### Stage 2.2. Quiet phase and sustained E2 plateau

Goal: teach that the positive feedback switch needs sustained high E2.

1. When all NPC follicles are gone, the arena becomes quiet.
2. Player action is focused on producing E2 to raise E2 concentration.
3. The system requires E2 to stay above a threshold for a continuous duration.
4. If E2 drops, the hold timer resets or decays.
5. When the hold completes, the far field flips from negative feedback to positive feedback.

Design note:

1. Do not model this as “hit a number once.”
2. Model it as “maintain high E2 for long enough.”

### Stage 3. LH surge and finale

Goal: show the system level phase transition.

1. After the feedback flip, LH surges.
2. LH waves become high amplitude and high density.
3. The level ends as a surge sequence or short victory cut.

## 3. Player abilities and their biological mapping

### Ability 1. Release E2

Gameplay mapping:

1. Buff to the player’s FSH sensitivity.
2. Energy gain per FSH pellet increases for a duration.

System mapping:

1. E2 contributes to global negative feedback on FSH during Stage 2.
2. E2 is the main driver for the sustained plateau in Stage 2.2.

Messaging note:

1. E2 does not “directly kill” other follicles.
2. The competitive effect is mediated by reduced global FSH.

### Ability 2. Release inhibin B

Gameplay mapping:

1. A wave or signal that reaches the far field.
2. It causes a marked reduction in global FSH for a limited duration.

System mapping:

1. Add a delay to the far field effect.
2. Add a duration and recovery curve.
3. This skill should have a self cost since lower FSH also reduces the player’s resource inflow unless LH responsiveness is already strong.

### Ability 3. Gain LH responsiveness

Final mapping used in this design:

1. It is a granulosa cell LH receptor unlock, not a theca receptor upgrade.
2. It is tied to maturation. It triggers at energy two segments.

## 4. Near field and far field representation

Near field:

1. A 2D arena that contains player and NPC follicles.
2. Pellets as physical objects with collision pickup.
3. Simple movement and steering.

Far field:

1. A pituitary panel that displays wave intensity for FSH and LH.
2. A feedback mode indicator. Negative vs positive.
3. A threshold hold timer for Stage 2.2.
4. A visual link between near field secretions and far field output changes.

Minimal animation approach:

1. Use density changes and HUD meters first.
2. Add wave transmission visuals later.

## 5. Required gameplay objects and systems

Core systems:

1. StageManager. A state machine for Stage 1, 2.0, 2.1, 2.2, 3.
2. EndocrineModel. Stores global variables and applies feedback rules.
3. HormoneField. Spawns pellets based on wave functions and global levels.
4. TimeController. Controls time scale and drives the time compass UI.
5. Config and DebugOverlay. Central tuning and real time observability.

Gameplay entities:

1. PlayerFollicle. Movement, energy, receptor state, skills.
2. NpcFollicle. Simple competing agents that seek pellets and starve.
3. HormonePellet. Area2D pickups for FSH and LH.
4. Skill emitters or direct calls to EndocrineModel.

UI:

1. HUD. Energy meter, time compass, ability indicators.
2. DebugOverlay. Live readouts and tuning hooks.

## 6. Quantification and tuning approach

The level uses a minimal tunable model. It aims for stability and readability, not biochemical units.

Suggested minimal variables:

1. Global: C_e2, C_inhibin, A_fsh, A_lh, feedback_mode.
2. Player: energy E, FSH sensitivity S_fsh, LH responsiveness S_lh, unlock flag for LH receptors.
3. NPC: energy, move speed, perception radius, reaction delay.

Key tunable parameters:

1. Base spawn rates for FSH and LH.
2. Wave amplitude and period for FSH and LH.
3. Energy gain per pellet by hormone type.
4. Energy decay per second.
5. Feedback strengths from E2 and inhibin B to FSH.
6. Delay and duration for inhibin B effect.
7. Threshold and required hold duration for Stage 2.2 feedback flip.
8. NPC count and starvation thresholds.

A DebugOverlay is required for fast iteration.

1. Show A_fsh, A_lh, C_e2, C_inhibin, E, receptor unlock, current stage.
2. Support quick restart and time scale control.
3. Prefer hot reload or live editing of the config resource.

## 7. Godot project structure

The project is scene first. Scripts are attached to nodes. The recommended structure is below.

1. scenes
   1. main/Main.tscn
   2. level/OvaryArena.tscn
   3. ui/HUD.tscn
   4. ui/DebugOverlay.tscn
   5. entities/PlayerFollicle.tscn
   6. entities/NpcFollicle.tscn
   7. entities/HormonePellet.tscn

2. scripts
   1. core/StageManager.gd
   2. core/EndocrineModel.gd
   3. core/TimeController.gd
   4. core/EventBus.gd
   5. gameplay/HormoneField.gd
   6. gameplay/PlayerFollicle.gd
   7. gameplay/NpcFollicle.gd
   8. gameplay/Pellet.gd
   9. ui/HUD.gd
   10. ui/DebugOverlay.gd

3. data
   1. configs/GameConfig.tres
   2. tuning/presets/*.tres

Optional:

1. python_tools for offline parameter sweeps and wave plots.
2. addons for behavior trees if desired.

## 8. GDScript vs Python

GDScript feels similar to Python in syntax and iteration speed. The project structure differs.

1. The main unit is a Scene and a Node tree.
2. Scripts are attached to nodes.
3. Execution is driven by engine callbacks such as _ready and _process.
4. Communication often uses signals rather than direct function calls across modules.
5. Data is often stored as exported variables and resources, not only as code constants.

## 9. NPC AI in Godot and difficulty control

Godot provides navigation and pathfinding tools. Decision logic is usually custom.

For this level, NPC AI should be simple.

1. Periodically pick a target pellet within a perception radius.
2. Move toward it with turn inertia and small noise.
3. Include reaction delay.
4. Starve out when energy falls below a threshold.

Difficulty control should use parameter scaling, not clever algorithms.

1. Move speed multipliers.
2. Perception radius.
3. Reaction delay.
4. Energy decay.
5. Spawn density.

## 10. Web deployment target

The level can be published as a Web export on GitHub Pages at a github.io domain.

1. Export Godot Web build to static files.
2. Commit the export output to a GitHub repository.
3. Enable GitHub Pages for the branch and folder.
4. Prefer single thread Web export for broad compatibility.
5. Watch for file size limits and caching behavior.

## 11. Implementation notes

This section documents implementation decisions validated during early prototyping.

### Collision system

1. Use elastic collision with explosion push. Follicles exchange velocity along collision normal and receive a fixed outward impulse to guarantee separation.
2. Set min_explosion_speed to 150.0 to prevent sticking artifacts.
3. Apply collision response in a central CollisionManager after all movement.
4. Use move_and_collide instead of move_and_slide for direct velocity control.
5. Add collision cooldown of 0.3 seconds. AI control is suppressed after collision to prevent immediate re-approach.

### Configuration and file structure

1. Store all parameters in a single config.json file.
2. Access config via dot notation through ConfigManager.
3. Make missing keys cause fatal errors by design. This enforces completeness.
4. Use three script folders: core for managers, entities for gameplay, ui for presentation.

### NPC AI behavior

1. NPCs pick random target positions in the arena.
2. NPCs move toward target using normalized direction.
3. AI is suppressed during collision cooldown. This creates emergent avoidance behavior.

### Initial conditions

1. All follicles spawn with random velocity.
2. Direction is uniformly random from 0 to 2π.
3. Magnitude is random within configured range. Player 80 to 150, NPC 60 to 100.
4. Follicles bounce off arena edges using velocity reversal with damping.
   - Detection uses bounce_margin (default 5.0px) from edge plus follicle radius
   - Bounce applies bounce_damping (default 0.8) to preserve 80% of speed
   - Velocity component perpendicular to boundary is reversed and scaled
5. Position is clamped to valid boundary on bounce to prevent penetration.

### Far field hormone emission system

1. Far field represents the pituitary gland as a visual control center positioned above the ovary arena.
2. Hormone pellets (FSH and LH) are emitted in 360-degree circular waves from the pituitary boundary.
3. Pellet motion combines radial movement with perpendicular sine wave oscillation: `position = start + direction * speed * time + perpendicular * amplitude * sin(TAU * freq * time)`.
4. Object pooling with 400 pre-instantiated pellets prevents allocation overhead. Pool expands by 100 if depleted.
5. Dual timer system enables independent FSH and LH emission. Each hormone has separate emission_interval and emission_count parameters.
6. Z-index layering ensures visual hierarchy: arena background (0), pellets (5), follicles (10).
7. FSH pellets render at 12.0px radius, LH at 10.5px radius, reflecting biological size difference.
8. Collision signals are intentionally disabled. Future receptor system will control selective hormone absorption with per-follicle cooldown.
