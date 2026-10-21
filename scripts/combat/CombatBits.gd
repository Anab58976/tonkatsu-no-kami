class_name CombatBits
extends RefCounted
## Small combat helpers live in their own files (Telegraph, Projectile, Pickup,
## PoisonCloud). This file only documents the collision layers used:
##   1  world          2  player body      4  enemy hurtboxes
##   8  player hitbox  16 enemy hitbox     32 interactables
