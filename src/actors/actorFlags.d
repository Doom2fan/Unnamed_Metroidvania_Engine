/*
**  ??? - A DSFML game
**  Copyright (C) 2016  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

module actors.actorFlags;

enum ObjFlags : uint {
    SOLID               = 1,      /// The actor is solid (Not having this does not mean not doing collision detection)
    INVULNERABLE        = 1 << 2, /// The actor is invulnerable
    MONSTER             = 1 << 3, /// The actor is a monster (Used for both friend and enemy CPU-controlled actors)
    KILLED              = 1 << 4, /// The actor is dead (internal flag)
    SHOOTABLE           = 1 << 5, /// The actor is shootable (This is only useful if the SOLID flag is not set. It allows attacks to hit an actor even if it isn't solid)
    NOINTERACTION       = 1 << 6, /// The actor does not perform collision detection and is ignored by all other actors
    MISSILE             = 1 << 7, /// The actor is a projectile (internal flag)
}

enum ProjFlags : uint {
    RIPPER              = 1,      /// The projectile rips through enemies (Deals damage every tic)
    SETTARGET           = 1 << 2, /// The projectile gets its target pointer set to the enemy it hits
}