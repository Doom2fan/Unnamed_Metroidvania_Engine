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

module actorDef;

import dsfml.graphics;
import gameDefs;
public import actors.actorFlags;
public import player : PlayerPawn;
public import particleSys : Particle, SpriteParticle;
public import actors.projectileObj;
public import actors.armorObj;

GameObject [] ActorList;
PlayerPawn [] PlayerList;

/++ The class for actor states ++/
struct ActorState {
    void function (void* []) action; /// The action to be executed when the state is entered
    void* [] actionArgs;             /// The action's args
    Sprite spr;                      /// The state's sprite
    int length;                      /// The state's length
    uint next;                       /// The next state to go to

    void runAction () {
        if (action !is null)
            action (actionArgs);
    }
}

interface IGameObject {
    // Properties
    @property accum X    (); @property void X    (accum val);
    @property accum Y    (); @property void Y    (accum val);
    @property accum XVel (); @property void XVel (accum val);
    @property accum YVel (); @property void YVel (accum val);
    // Functions
    void tick ();
}

interface IDestructibleObj : IGameObject {
    // Properties
    @property int Health (); @property void Health (int val);
    @property int SpawnHealth (); @property void SpawnHealth (int val);
    // Functions
    void damage (IGameObject source, int dmg);
    void die (IGameObject killer);
}

/++ The base class all actor types derive from ++/
class GameObject : IGameObject {
    // Physics and movement
    protected accum x,    y;    /// The actor's X-Y coordinates. These are at the center of the collision rectangle
    protected accum xVel, yVel; /// The actor's X-Y velocities

    this () {
        x = 0; y = 0;
        xVel = 0; yVel = 0;
    }

    @property accum X    () { return this.x;    } @property void X    (accum val) { this.x    = val; }
    @property accum Y    () { return this.y;    } @property void Y    (accum val) { this.y    = val; }
    @property accum XVel () { return this.xVel; } @property void XVel (accum val) { this.xVel = val; }
    @property accum YVel () { return this.yVel; } @property void YVel (accum val) { this.yVel = val; }

    /// Ticks/updates the actor
    void tick () {
        if (xVel != 0)
            x += xVel;
        if (yVel != 0)
            y += yVel;
    }
}

/++ The main actor class ++/
class Actor : GameObject, IDestructibleObj {
    // Physics and movement
    accum prevX, prevY;                 /// Previous X and Y coordinates
    int width, height;                  /// The actor's collision rectangle size
    int speed;                          /// The actor's speed
    accum acceleration;                 /// How fast the actor should accelerate to top speed. 0 means instantly
    protected accum gravity;            /// The actor's base gravity
    // Health and damage
    protected int health, spawnHealth;  /// The actor's health and default health
    // Graphics
    Sprite spr;                         /// The actor's sprite
    // State stuff
    protected int state;                /// The actor's current state
    protected int stTime;               /// Tics left until next state
    protected ActorState [] states;     /// The actor's states
    protected int [string] stateLabels; /// The actor's state labels
    // Flags
    ObjFlags flags;                     /// The actor's flags
    // Pointers
    IGameObject* ptr_killer;            /// Pointer to the actor's killer (if any)
    IGameObject* ptr_target;            /// The actor's target
    IArmorObj* ptr_armor;               /// Pointer to the actor's armour (if any)

    @property const (int [string]) getStateLabels () {
        return cast (const (int [string])) stateLabels;
    }

    @property int Health () { return this.health; }
    @property void Health (int val) { this.health = val; }
    @property int SpawnHealth () { return this.spawnHealth; }
    @property void SpawnHealth (int val) { this.spawnHealth = val; }
    @property accum Gravity () { return this.gravity; }
    @property void Gravity (int val) {
        if (val < 0f)
            throw new RangeError ("Actor gravity cannot be negative.");
        gravity = val;
    }

    this (int w = 1, int h = 1) {
        width = w;
        height = h;
        speed = 0;
        gravity = 1f;
        spawnHealth = 1000;
        health = spawnHealth;
        stateLabels ["Spawn"] = 0;
    }

    override void tick () {
        doMovement ();

        if (gravity > 0f && y > 0f)
            yVel -= (flags & ObjFlags.NOINTERACTION) ? getLocalGravity () : getGravity ();

        //if (y < 0f) y = 0f;
        if (y <= 0f && yVel < 0f) yVel = 0f;

        doCollisionDetection ();

        prevX = x; prevY = y;

        stTime--;
        if (!stTime) {
            changeState (states [state].next);

            while (!stTime)
                changeState (states [state].next);
        }
    }

    void doMovement () {
        x += xVel;
        if (xVel != 0f && isColliding ()) {
            accum quarterWidth = this.width / 4.0f;
            accum xUndo = (abs (prevX - x) <= quarterWidth * 2 ? 1f : quarterWidth) * (xVel > 0f ? 1.0f : -1.0f);
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

    accum getGravity () { return gravity * baseGravity; } // Right now these are the exact same, but will be different when level geometry is added
    accum getLocalGravity () { return gravity * baseGravity; }

    /// Deals damage to the actor
    void damage (IGameObject source, int dmg) {
        if (flags & ObjFlags.INVULNERABLE || flags & ObjFlags.KILLED)
            return;

        health -= dmg;
        if (health == 0)
            die (source);
    }

    void die (IGameObject killer) {
        ptr_killer = &killer;
    }

    static bool overlaps (Actor A, Actor B) {
        if (abs (A.x - B.x) < (A.width  / 2 + B.width  / 2) &&
            abs (A.y - B.y) < (A.height / 2 + B.height / 2))
            return true;
        else
            return false;
    }

    bool isColliding () {
        if (this.width == 0 || this.height == 0 || this.flags & ObjFlags.NOINTERACTION || !(this.flags & ObjFlags.SOLID))
            return false;

        foreach (obj; ActorList) {
            if (!obj)
                continue;

            Actor actor = cast (Actor) obj;
            if (!actor || (actor.flags & ObjFlags.NOINTERACTION) || !(actor.flags & ObjFlags.SOLID) || actor.width == 0 || actor.height == 0 || actor == this)
                continue;

            if (overlaps (this, actor))
                return true;
        }

        return false;
    }

    void doCollisionDetection () {
        
    }

    void changeState (int stNum) {
        state = stNum;
        spr = states [state].spr;
        stTime = states [state].length;
        states [state].runAction ();
    }

    void changeStateList (ActorState [] newStates, int [string] newStateLabels) {
        states = newStates;
        stateLabels = newStateLabels;

        if ("Spawn" in stateLabels)
            changeState (stateLabels ["Spawn"]);
    }
}

class CameraActor : GameObject {
    View viewport;            /// The camera's view
    accum viewXVel, viewYVel; /// The view's x-y velocities

    this (View vport = new View (FloatRect (0, 0, 800, 600))) {
        viewport = vport;
        viewXVel = 0; viewYVel = 0;
    }

    override void tick () {
        super.tick ();
        viewport.center = Vector2f (x, -y);
    }
}