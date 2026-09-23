# Build Prompt: Finding Naresh — Bessi and the 5 Roses

## Your role

Act as a senior indie game developer, gameplay designer, technical designer, and QA engineer. Build a complete, polished, locally playable concept demo from the specification below.

Do not merely produce a design document, isolated scripts, mock screenshots, or a menu-only prototype. Create the actual runnable project, connect every required system, test the complete gameplay loop, and leave clear instructions for launching and controlling the game.

If an implementation detail is unspecified, choose the simplest reliable solution that preserves the intended player experience. Do not expand the scope with unrelated mechanics. Prioritize a stable, enjoyable 30-minute vertical slice over technical ambition.

## Project summary

**Title:** Finding Naresh: Bessi and the 5 Roses  
**Genre:** Two-player cooperative road-trip adventure, vehicle survival, navigation, environmental puzzles, and light psychological mystery  
**Engine:** Godot 4.x  
**Scripting:** GDScript  
**Target platform:** Windows PC  
**Players:** Exactly two local players  
**Input:** One keyboard and mouse plus one game controller, with remappable controls where practical  
**Camera:** First-person for both players  
**Display:** Local split-screen  
**Visual direction:** Colorful, readable cartoon styling with an increasingly unsettling atmosphere  
**Demo duration:** Approximately 30 minutes on a first playthrough  
**Combat:** None; players survive by escaping, hiding, navigating, repairing, and cooperating  
**Dialogue:** Text only; do not use voice-over  

The game follows two friends sent to recover Naresh, who disappeared while travelling toward a legendary destination named **Bessi and the 5 Roses**. Naresh told his parents that he was travelling with a friend. The eventual twist is that there was never another traveller: Naresh imagined the friend. Keep this ambiguous and unsettling rather than explaining it clinically. Evidence should make players question whether the friend was imaginary or whether something at the destination became real.

The players share a battered camper van. Half of the experience is driving, route planning, and moderately realistic vehicle management. The other half is on-foot exploration, cooperative puzzles, navigation by landmarks, resource recovery, and physics-based chaos. After Naresh is found near the middle-to-late portion of the demo, he joins the return journey and genuinely tries to help, but his confident mistakes create funny and frustrating recovery situations.

## Experience goals

The demo must make both players regularly speak and coordinate. Each player should have useful things to do while driving, exploring, repairing, solving puzzles, hiding, and recovering a downed partner.

The emotional progression should be:

1. Cozy and funny road-trip energy.
2. Beautiful exploration and satisfying navigation.
3. Increasing uncertainty that something is wrong.
4. Tense discovery and escape.
5. Funny frustration caused by Naresh during the return trip.
6. An ambiguous final sting that makes players want the full game.

Do not make the tone relentlessly frightening. Warm scenery, comedy, mystery, danger, and physics chaos should coexist.

## Non-negotiable scope rules

- Build one polished vertical slice, not four separate levels.
- Use one handcrafted, compact world with memorable landmarks and branching paths.
- Limited randomization is allowed for movable supplies, weather, blocked minor roads, and optional roadside events.
- Do not procedurally regenerate the main road network, major landmarks, or required puzzle solutions. Remembering routes must be rewarding.
- Do not add online multiplayer to this demo.
- Do not add combat, weapons, hunger, thirst, crafting trees, base building, skill trees, or a large inventory system.
- Do not rely on paid or copyrighted assets. Use original, generated, public-domain, or clearly licensed assets. Record third-party licenses in a credits file.
- Placeholder art is acceptable only when it is visually coherent and the complete game loop remains understandable.
- Avoid creating a huge empty terrain. Every playable area should support navigation, storytelling, puzzles, resources, or atmosphere.

## Core gameplay loop

1. Inspect the physical map and plan a route.
2. Drive the camper while monitoring its condition.
3. Encounter a breakdown, obstruction, resource shortage, or navigation problem.
4. Park and explore the surrounding area on foot.
5. Solve a cooperative environmental or physics puzzle.
6. Recover vehicle supplies, a story clue, a Memory Fragment, or a route shortcut.
7. Repair or resupply the camper and continue toward the objective.

Stopping the vehicle must lead to gameplay. Never require players to stare at an engine-cooling timer with nothing useful to do.

## Two-player implementation

Implement true local split-screen with two independent first-person cameras and viewports.

- Player 1 defaults to keyboard and mouse.
- Player 2 defaults to a connected controller.
- Clearly show an input-assignment screen before starting.
- Both players must be able to walk, look, sprint, crouch, jump over small obstacles, interact, carry objects, use a flashlight, inspect the paper map, enter or exit the camper, and revive the other player.
- Use contextual interaction prompts appropriate to each player’s input device.
- Prevent one player’s mouse or controller input from moving the other player.
- Include pause, sensitivity, master volume, effects volume, music volume, and subtitle/text-speed controls.
- When both players are inside the same moving camper, retain split-screen because they have different responsibilities and viewpoints.

Players may choose either seat, but the two useful roles are:

- **Driver:** steers, accelerates, brakes, watches the road, manages ignition, headlights, and driving-related gauges.
- **Navigator/passenger:** studies maps, reads signs, watches secondary gauges, operates selected dashboard controls, looks for landmarks, and can lean or look around independently.

Allow both players to swap roles whenever the camper is safely stopped.

## First-person interaction

Use a simple physics interaction system with clear highlighting and a center-screen prompt. Players should be able to pick up, carry, place, and drop appropriate objects. Heavy objects such as full fuel cans, boards, and mechanical components should feel weighty without becoming uncontrollable.

Physics comedy should come from understandable forces, awkward teamwork, shifting cargo, slopes, ropes, doors, and movable objects—not from constant random glitches.

Each player carries:

- A flashlight with a visible beam.
- Access to the shared paper map.
- A small contextual inventory for key items only.

Do not create a complex grid inventory. Large objects should be carried physically or stored in designated camper slots.

## Navigation and maps

Navigation is a primary mechanic, not a decorative interface.

### Camper dashboard map

- Mount a small digital navigation display physically inside the camper.
- It shows major roads, discovered road closures, and the broad destination direction.
- It does not reveal every trail, resource, or puzzle.
- It requires camper battery power.
- It may briefly lose signal near Bessi and the 5 Roses.
- Prefer an in-world display; a clean UI enlargement may appear when the passenger focuses on it.

### Physical paper map

- Both players can raise a paper map in their hands while on foot or inside a stationary vehicle.
- The physical map must not show a live player-location marker.
- It should depict terrain, roads, water, major structures, and recognizable landmarks.
- Players navigate by comparing the map with mountains, towers, rivers, unusual trees, buildings, rose monuments, road signs, and local information boards.
- Information boards reveal or clarify nearby map sections.
- Allow players to place a small set of shared stamps: fuel, danger, puzzle, shortcut, and unexplored.
- The map state must persist through manual saves.

Design the terrain so an attentive player can genuinely learn the route after travelling through it once.

## Camper-van systems

The camper should feel moderately realistic but game-readable. Implement these interconnected systems:

### Fuel

- Fuel decreases with distance, idling, cargo weight, and inefficient driving.
- Fuel cans can be found, carried, stored in designated slots, and poured into the correct inlet.
- Running completely dry disables the engine but must leave at least one recoverable solution in the demo world.

### Engine temperature

- Temperature rises during steep climbs, prolonged high throttle, low coolant, or component trouble.
- Overheating reduces performance and eventually disables or damages the engine.
- Parking and turning off the engine cools it slowly.
- Players can speed recovery through an exploration objective, such as restoring a water pump or finding coolant.

### Tire pressure and damage

- At least one scripted tire-pressure problem must occur.
- Low pressure should visibly affect steering and efficiency.
- Players can use a portable pump or replace a wheel through a short cooperative interaction.
- Do not simulate four tires with excessive precision if a simplified axle or overall system is more reliable.

### Battery

- The battery powers ignition, dashboard navigation, interior lights, headlights, and selected equipment.
- Leaving electrical systems running while the engine is off drains the battery.
- Provide a recoverable jump-start or replacement-battery scenario.

### Cargo

- Provide physical storage positions for fuel, a spare tire, puzzle items, and recovered supplies.
- Unsecured heavy cargo may slide and influence handling slightly.
- Never let critical story items disappear permanently because of physics.

Show these systems through physical dashboard gauges plus minimal readable UI. Warning lamps, sound, smoke, steering behaviour, and engine performance should communicate problems without forcing players to read numbers constantly.

## Cooperative puzzles

Include at least three distinct cooperative puzzles. Every required puzzle must involve both players meaningfully and be resettable if an object falls or becomes inaccessible.

Suggested required puzzles:

1. **Cooling-station puzzle:** One player redirects water through old pipes while the other operates a noisy pump and watches pressure. Completing it supplies coolant and one Memory Fragment.
2. **Broken crossing:** Players position boards and operate the camper winch. One guides from outside using hand movement or text pings while the other carefully drives. The result opens a shortcut that matters during the return journey.
3. **Five Roses mechanism:** At the abandoned destination, players use the physical map and visible landmarks to align or activate five rose-shaped monuments in the correct spatial order. The solution should depend on observation, not a random code.

Optional small puzzles may award supplies, clues, map stamps, or additional Memory Fragments.

Puzzle feedback must be visual and audible. Avoid unexplained instant failure. Incorrect solutions should normally reset the local mechanism or create a recoverable inconvenience rather than kill the players.

## Memory Fragment manual-save system

There are no automatic checkpoints and no automatic progression saves during active play.

- Optional or secondary environmental puzzles award **Memory Fragments**.
- Three Memory Fragments combine automatically or through a simple interaction into one **Memory Rose**.
- Players may save only while the camper is fully stopped and parked.
- Saving is performed through the travel journal inside the camper.
- Each manual save consumes one Memory Rose.
- Make fragments limited enough to create a decision but common enough that careful players can save several times during the demo.
- Communicate the cost before confirming the save.
- Include at least three manual save slots and a clear load menu.

A save must restore:

- Both players’ positions and health state.
- Camper position, orientation, fuel, temperature, battery, tire state, and stored cargo.
- Shared key items and Memory Fragment count.
- Completed puzzles and opened routes.
- Map discoveries and stamps.
- Story progression and whether Naresh has joined.
- Relevant randomized-event state.

Do not secretly create a checkpoint after finding Naresh. If both players die, offer to load a manual save or return to the title screen.

## Danger, hiding, death, and revival

There is no combat. Threats should be environmental or only partially seen.

Possible dangers include:

- Falls, unstable structures, deep water, electrical equipment, or vehicle crashes.
- A storm that reduces visibility and makes certain roads unsafe.
- An unidentified presence near the Five Roses that reacts to light or noise.
- Brief pursuit sequences in which players hide in vegetation, structures, or the camper.

Do not build a complex enemy ecosystem. One simple, reliable threat behaviour is sufficient for the demo. Preserve ambiguity by using silhouettes, movement, sound, environmental reactions, and interrupted text rather than clearly explaining the threat.

When one player loses all health:

- They enter a downed state rather than dying immediately.
- The partner can revive them by maintaining an interaction for a short duration.
- The downed player may crawl slowly and ping danger but cannot complete normal interactions.
- Taking further damage or waiting too long causes that player to die for the current attempt.
- If one player survives, provide a difficult but possible recovery or revival opportunity.
- If both players die, return to the manual-load screen.

Tune danger to feel tense and consequential without repeatedly erasing the entire session before players have learned how saving works.

## Naresh

Naresh is an NPC recovered at Bessi and the 5 Roses. He is enthusiastic, confident, well-meaning, and consistently unreliable.

After joining, players can assign him a small set of contextual jobs:

- Carry a fuel can.
- Store a fuel can in the camper.
- Refuel the camper.
- Hold a lever or door.
- Carry the spare tire.
- Wait at a marked location.
- Follow the players.

Use a small finite-state behaviour system. Do not attempt unrestricted natural-language commands.

Naresh should usually complete tasks correctly, but the scripted return-trip sequence must include one clear mistake. Recommended scenario:

1. Players hand Naresh a full fuel can and instruct him to refuel or store it.
2. He confidently confirms completion through text.
3. Later, the camper fails to start or runs dry.
4. Players discover that Naresh stored an empty can, misplaced the full can, used the wrong inlet, or otherwise created a recoverable fuel problem.
5. The mistake triggers a short search or repair challenge under worsening weather and threat pressure.

His failures must never be purely arbitrary or permanently soft-lock progress. Leave a clue that lets observant players notice the mistake early. The humour comes from his confidence and the consequences, not from deleting progress without warning.

Example text:

- **Naresh:** “Done. I even checked it twice.”
- **Player:** “Why is the full can still here?”
- **Naresh:** “Then imagine how much fuel I put in.”
- **Naresh:** “My friend says this road is faster.”
- **Player:** “Naresh, there is nobody there.”
- **Naresh:** “He says you always do this.”

## Narrative delivery and imaginary-friend twist

Use no recorded dialogue or generated speech. Present story through concise text boxes, character-name labels, readable notes, phone messages, road signs, receipts, map annotations, and environmental clues.

Plant clues progressively:

- Naresh told his parents he was travelling with a friend they never met.
- His early messages alternate oddly between “I” and “we.”
- A guestbook records only Naresh.
- A campsite contains one used sleeping place despite references to two travellers.
- Photographs or receipts fail to confirm the second person.
- Some objects appear arranged for two people, preserving uncertainty.
- After the rescue, Naresh occasionally responds to an empty seat or reports advice from his friend.

Do not include a medical diagnosis or a long exposition dump. Let players infer the twist. The final moment should suggest that the imagined friend may understand the destination better than anyone else.

## World and demo sequence

Create a compact handcrafted route with loops and shortcuts rather than a straight corridor.

### Beat 1 — The parents’ request (2–3 minutes)

- Begin beside the camper at a bright roadside home or small garage.
- Teach movement, interaction, entering seats, vehicle startup, dashboard gauges, physical map, and flashlight.
- Deliver the rescue request through text messages or a written note.
- Mention that Naresh left with a friend, although the parents had never met the person.
- Give the players an initial route choice.

### Beat 2 — Cozy road trip (4–5 minutes)

- Introduce driving, navigation, landmarks, signs, and passenger responsibilities.
- Use sunny weather, music or radio-like instrumental ambience, wildlife, and playful loose cargo.
- Let a risky shortcut save time but consume more vehicle condition.

### Beat 3 — Overheat and exploration (5–6 minutes)

- Trigger an understandable overheating problem near an old water facility.
- Players park, consult the map, and complete the cooling-station co-op puzzle.
- Include one optional Memory Fragment puzzle nearby.
- Begin adding contradictory evidence about Naresh’s companion.

### Beat 4 — Broken crossing and worsening weather (4–5 minutes)

- Introduce rain, reduced traction, tire-pressure trouble, and a damaged crossing.
- Require the winch/board/driving cooperation puzzle.
- The opened shortcut will later make the escape route faster.

### Beat 5 — Bessi and the 5 Roses (6–7 minutes)

- Reach an abandoned, colorful hill resort or roadside attraction surrounded by five giant rose monuments.
- The location should remain visually beautiful but feel subtly wrong.
- Use the physical map and landmarks in the Five Roses puzzle.
- Introduce the hide-and-escape threat without fully showing or explaining it.
- Find Naresh in a surprising but non-graphic situation.
- Reveal through environmental evidence that no friend travelled with him.

### Beat 6 — Return with Naresh (5–6 minutes)

- The return route reuses known roads, rewarding route memory.
- Naresh is assigned a fuel-related task and makes the scripted mistake.
- The players must recover the situation while rain, darkness, or the unidentified presence creates pressure.
- Allow the earlier shortcut to provide a meaningful advantage.

### Beat 7 — Ending sting (1–2 minutes)

- Reach a temporary safe location rather than completing the entire journey home.
- Naresh refers through text to his friend sitting in an apparently empty part of the camper.
- End on an unexplained map mark, movement, sound, or changed destination label.
- Display a concise end-of-demo screen and return to the menu.

## Art direction

- Use colorful cartoon environments, simplified shapes, bold silhouettes, and readable material colours.
- Begin with warm greens, yellows, and blue skies.
- Transition toward cool rain, deeper shadows, saturated rose-red landmarks, and unusual lighting near the destination.
- Avoid photorealism and graphic gore.
- Make the camper visually distinctive and slightly improvised.
- Every critical interactive object must be easy to identify in split-screen.
- Use fog and darkness carefully; players must still navigate and solve puzzles.
- Keep performance suitable for two simultaneously rendered first-person viewports on a typical gaming PC.

## Audio direction

There is no voice-over, but the demo must not be silent. Implement layered sound hooks and use suitable legally usable sounds where available.

Required audio categories:

- Engine start, idle, acceleration, strain, overheating, sputtering, and shutdown.
- Tires on paved road, dirt, mud, and wet surfaces.
- Suspension, impacts, doors, storage compartments, tools, fuel pouring, pump machinery, and loose cargo.
- Distinct player footsteps on road, grass, wood, metal, and shallow water.
- Wind, sunny countryside ambience, birds, forest ambience, rain, thunder, and interior camper ambience.
- Flashlight, map, UI, puzzle success, puzzle failure, Memory Fragment, save, revive, and danger cues.
- Sparse non-vocal music or tonal ambience for cozy travel, mystery, and pursuit.

Use audio to signal off-screen danger and vehicle condition. Provide separate master, effects, music, and ambience sliders if practical. Do not use copyrighted commercial songs.

## UI and readability

- Keep HUD elements minimal and legible in each half of the split screen.
- Show player-specific interaction prompts.
- Clearly distinguish shared resources from individual state.
- Present important text independently for both players or pause safely when story text requires attention.
- Include an objective log with one current objective and optional hints.
- Use a hold-to-show hint system so difficult puzzles remain solvable without immediately revealing answers.
- Include a brief explanation of the no-checkpoint manual-save rule before the players leave the starting area.
- Warn players before quitting if progress has not been manually saved.

## Recommended project architecture

Use small, modular systems with signals and resources rather than one enormous gameplay script. A reasonable structure includes:

- Game/session manager
- Input/device assignment manager
- Split-screen player controller
- Interaction component/interface
- Carryable physics object
- Camper controller
- Vehicle-condition resource/model
- Seat and enter/exit system
- Physical-map and map-stamp system
- Dashboard navigation display
- Puzzle base class and individual puzzle controllers
- Shared objective/story-state manager
- Inventory/key-item manager
- Memory Fragment and manual-save manager
- Health, downed-state, and revive component
- Simple threat state machine
- Naresh finite-state command controller
- Audio and ambience manager
- Settings and save-slot UI

Use data-driven values for fuel consumption, heat gain, cooling, pressure penalties, battery drain, revive time, threat speed, and save cost so they can be tuned without rewriting logic.

## Build order

Implement and verify in this order:

1. Project boot, main menu, device assignment, and two-player split-screen movement.
2. Interaction system, carryable objects, flashlight, physical map, and basic test room.
3. Camper driving, seats, entry/exit, dashboard, and vehicle systems.
4. Handcrafted route, landmarks, map alignment, and navigation UI.
5. Three cooperative puzzles and Memory Fragment rewards.
6. Manual save/load, including complete world and camper restoration.
7. Health, downed state, revival, environmental hazards, hiding, and threat.
8. Naresh’s contextual command system and scripted fuel mistake.
9. Story text, environmental clues, atmosphere progression, ending, and menus.
10. Audio integration, tuning, optimization, controller testing, save/load testing, and full playthrough QA.

Maintain a runnable project after every major stage. If time becomes limited, simplify art and secondary events before removing core co-op mechanics, save/load reliability, or the full beginning-to-ending playthrough.

## Required deliverables

Provide:

1. The complete Godot project with editable source files.
2. A runnable Windows build if the environment supports exporting it.
3. A README containing setup, launch, controls, known limitations, and the demo walkthrough.
4. A short architecture note explaining major scenes, scripts, and extension points.
5. A credits/licenses file for every non-original asset.
6. A QA checklist showing what was tested.

Do not claim a feature works unless it is connected and tested in the actual demo.

## Acceptance criteria

The demo is complete only when all of the following are true:

- Two players can join locally using keyboard/mouse and one controller.
- Both receive independent first-person views and correct control prompts.
- Both can enter and exit the camper, swap roles, and cooperate while driving.
- The camper can be driven through the complete route.
- Fuel, temperature, tire condition, battery, and cargo produce visible gameplay effects.
- The dashboard map and physical paper map serve different purposes.
- The paper map has no live-position marker and supports shared stamps.
- Major landmarks make the route learnable.
- At least three functional cooperative puzzles are present.
- Players can earn Memory Fragments and spend three to manually save at the parked camper.
- There are no automatic checkpoints.
- Loading restores players, vehicle state, cargo, puzzles, story state, and map discoveries correctly.
- One player can become downed and be revived by the other.
- A no-combat hiding or escape sequence works reliably.
- Naresh can receive limited contextual commands after rescue.
- Naresh’s fuel mistake creates a recoverable gameplay problem.
- The imaginary-friend twist is communicated without voice-over or exposition dumping.
- Vehicle, footstep, environment, weather, interaction, and danger sounds are present.
- The complete demo can be finished in roughly 30 minutes.
- Neither player is left without a meaningful role for extended periods.
- Critical objects and puzzles cannot permanently soft-lock the playthrough.
- The game can be paused, restarted, saved, loaded, and exited cleanly.

## Out of scope for this concept demo

Do not implement these unless every required feature is already complete and stable:

- Online networking or matchmaking
- Four-player support
- Infinite procedural terrain
- Multiple full levels or regions
- Combat or weapon systems
- Complex enemy AI
- Advanced vehicle customization
- Survival hunger/thirst/sleep simulation
- Crafting or base building
- Full character customization
- Voice acting
- Cinematic cutscenes
- Large branching dialogue trees
- A complete journey home after the demo ending

## Final instruction

Begin by inspecting the working environment and confirming that Godot 4 is available. Then create an implementation plan tied directly to the acceptance criteria and start building. Make reasonable technical decisions independently, document them, and keep the project playable throughout development.

The final result should feel like a small but real co-op game: funny when teamwork goes wrong, rewarding when players remember the road or solve something together, tense when saving resources are low, and unsettling whenever Naresh talks about the friend who was never there.
