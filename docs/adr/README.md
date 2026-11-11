# Architecture Decision Records

Each record explains one design decision: the context, what was decided and its consequences. Code comments stay short and point here when a decision needs more explanation.

Records are numbered in order and never deleted. A decision that changes gets a new record that supersedes the old one.

| # | Decision | Status |
|---|---|---|
| [0001](0001-player-state-machine.md) | Player states as a hierarchical state machine | Accepted |
| [0002](0002-shared-weapon-states.md) | One set of states for every weapon | Accepted |
| [0003](0003-lighting.md) | Lighting: a lightmap of visibility polygons | Accepted |
| [0004](0004-zombie-navigation.md) | Zombie navigation: a shared flow field and a straight walk when the way is clear | Accepted |
| [0005](0005-melee-states.md) | Melee as a substate of whatever is held | Accepted |
| [0006](0006-audio.md) | Audio: sounds by name, tied to animation frames | Accepted |
