# Godot NavigationAgent CharacterBody Controller Example
A controller for a CharacterBody3D that uses a NavigationAgent3D.

This character controller utilizes a NagivationRegion3D to constrain where the player can walk.
- The player can not walk off ledges, but jump off them.
- The player can climb stairs without any RayCast3D setup.
- The player uses velocity for movement, taking advantage of physics.
- The player will reset to the last valid movement position upon reaching the Y kill axis.
- Not tested, but the player likely can be pushed off ledges.
