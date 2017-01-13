/*
**  ??? - A DSFML game
**  Copyright (C) 2015  Chronos Ouroboros
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

module player;

import dsfml.graphics;
import actorDef;
import gameDefs;

enum PlayerControls : int {
    Attack = 1,
}

class PlayerPawn : Actor {
    CameraActor camera; /// The player's camera
    PlayerControls controls;
    accum forwardInput;
    accum sidewaysInput;
    bool canJump;

    uint pID; /// Player id/number

    this (int w = 1, int h = 1) {
        super (w, h);
        gravity = 1f;
        camera = new CameraActor ();
    }

    override void tick () {
        if (canJump && forwardInput > 0f) {
            canJump = false;
            yVel += 25f;
        }
        super.tick ();
        if (!canJump && y == 0)
            canJump = true;
        camera.X = this.x; camera.Y = this.y;
        camera.tick ();
    }

    override void doMovement () {
        accum xChange = xVel + (sidewaysInput / 100) * 15;
        x += xChange;
        if (xChange != 0f && isColliding ()) {
            accum quarterWidth = this.width / 4.0f;
            accum xUndo = (abs (prevX - x) <= quarterWidth * 2 ? 1f : quarterWidth) * (xChange > 0f ? 1.0f : -1.0f);
            while (isColliding ())
                x -= xUndo;
        }
        y += yVel;
        if (yVel != 0f && isColliding ()) {
            accum quarterHeight = this.height / 4.0f;
            accum yUndo = (abs (prevY - y) <= quarterHeight * 2 ? 1f : quarterHeight) * (yVel > 0f ? 1.0f : -1.0f);
            while (isColliding ())
                y -= yUndo;
        }
    }

    bool isControlPressed (PlayerControls ctrl) {
        return cast (bool) (cast (int) controls & ctrl);
    }
}