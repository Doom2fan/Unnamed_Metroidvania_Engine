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

module actors.projectileObj;

import actorDef;

class Projectile : Actor {
    int damage;
    ProjFlags prFlags;
    IGameObject* ptr_shooter;

    this () {
        flags |= ObjFlags.MISSILE;
        flags &= ~ObjFlags.SOLID;
    }

    override void tick () {
        if (xVel != 0)
            x += xVel;
        if (yVel != 0)
            y += yVel;

        doCollisionDetection ();

        stTime--;
        if (!stTime) {
            changeState (states [state].next);

            while (!stTime)
                changeState (states [state].next);
        }
    }

    override void doCollisionDetection () {
        if (this.width == 0 || this.height == 0)
            return;

        foreach (obj; ActorList) {
            if (!obj || !(cast (Actor) obj))
                continue;

            Actor actor = cast (Actor) obj;
            if (actor == this || actor.width == 0 || actor.height == 0)
                continue;

            if (overlaps (this, actor)) {
                actor.damage (this, this.damage);
                die (actor);
            }
        }
    }

    override void die (IGameObject killer) {
        if (flags & ObjFlags.KILLED)
            return;

        flags |= ObjFlags.KILLED;
        if (prFlags & ProjFlags.SETTARGET)
            ptr_shooter = &killer;

        changeState (stateLabels ["Death"]);
    }
}
