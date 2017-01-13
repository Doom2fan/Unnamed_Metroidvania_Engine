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

module particleSys;

import std.algorithm.searching : count;
import std.conv : to;
import std.math;
import std.exception : enforce;
import dsfml.graphics;
import actorDef;
import gameDefs;

/++ A simpler actor type for simple particles ++/
class Particle : GameObject {
    int speed; /// The particle's speed
    Color color; /// The particle's color
    int lifetime; /// How long the particle stays for before fading
    int spawnLifetime; /// The particle's lifetime on spawn

    override void tick () {
        if (xVel != 0)
            x += xVel;
        if (yVel != 0)
            y += yVel;
    }

    this (int spd = 5, Color col = Color.White, uint lt = 5) {
        enforce (lt, "Particle lifetime must be greater than 0");

        speed = spd;
        lifetime = lt; spawnLifetime = lt;
        color = col;
    }

    this (accum [2] vel, int spd = 5, Color col = Color.White, int lt = 5) {
        this (spd, col, lt);

        xVel = vel [0];
        yVel = vel [1];
    }

    this (Particle p) {
        xVel = p.xVel;
        yVel = p.yVel;
        speed = p.speed;
        color = p.color;
        lifetime = p.lifetime;
        spawnLifetime = p.spawnLifetime;
    }
}

/++ A particle that uses a sprite instead of a solid color ++/
class SpriteParticle : Particle {
    Sprite sprite;

    this (SpriteParticle p) {
        super (cast (Particle) p);
        sprite = p.sprite;
    }
}

class ParticleSystem : Drawable, Transformable {
    mixin NormalTransformable;

    protected {
        Particle [] pointParticles;
        SpriteParticle [] [Sprite] spriteParticles;
        Mt19937 rng;
    }

    this () {
        pointParticles.length  = 20000;  pointParticles [] = null;
        rng = Mt19937 (unpredictableSeed);
    }

    void addParticles (Particle [] pList) {
        foreach (p; pList) {
            if (cast (SpriteParticle) p) {
                SpriteParticle sPart = cast (SpriteParticle) p;
                spriteParticles [sPart.sprite] ~= sPart;
            } else
                pointParticles ~= p;
        }
    }

    /// Adds particles to the particle system
    void addParticles (SpriteParticle [] pList) {
        foreach (p; pList) {
            if (p)
                spriteParticles [p.sprite] ~= pList;
        }
    }

    /++ Creates and spawns default particles. (White size 1 particles)
    +++ Params:
    +++     amount          = The amount of particles to spawn.
    +++
    +++     loc             = The xy coordinates to spawn the particles at.
    +++
    +++     dir             = The direction range the particles should be spawned in.
    +++
    +++     lt              = The lifetime of the particles.
    ++/
    void spawnParticles (int amount, Vector2f loc, Vector2f dir, int lt, int speed) {
        spawnParticles!(Particle) (pointParticles, new Particle (speed, Color.White, lt), amount, loc, dir);
    }
    /++ Creates and spawns particles based on base.
    +++ Params:
    +++     base            = The particle to base the spawned particles on.
    +++
    +++     amount          = The amount of particles to spawn.
    +++
    +++     loc             = The xy coordinates to spawn the particles at.
    +++
    +++     dir             = The direction range the particles should be spawned in.
    ++/
    void spawnParticles (Particle base, int amount, Vector2f loc, Vector2f dir) {
        if (cast (SpriteParticle) base) {
            SpriteParticle spBase = cast (SpriteParticle) base;
            spawnParticles!(SpriteParticle) (spriteParticles [spBase.sprite], spBase, amount, loc, dir);
        } else {
            spawnParticles!(Particle) (pointParticles, base, amount, loc, dir);
        }
    }

    protected void spawnParticles (T) (ref T [] endPoint, T base, int amount, Vector2f loc, Vector2f dir) {
        T [] pList;

        pList.length = amount;

        for (int i = 0; i < amount; i++) {
            float ang = uniform (dir.x, dir.y, rng);

            pList [i] = new T (base);
            pList [i].X = cast (accum) (loc.x - uniform (-1.0f, 1.0f, rng));
            pList [i].Y = cast (accum) (loc.y - uniform (-1.0f, 1.0f, rng));
            pList [i].XVel = cast (accum) (base.speed * cos (ang * (PI / 180)));
            pList [i].YVel = cast (accum) (base.speed * sin (ang * (PI / 180)));
        }

        int j = 0;
        for (int i = 0; i < pList.length; i++) {
            if (!pList [i])
                continue;

        replaceNulls:
            for (; j < endPoint.length; j++) {
                if (!endPoint [j])
                    break;
            }

            if (j >= endPoint.length && i < pList.length) {
                static if (is (T == SpriteParticle)) endPoint ~= nullSpriteParticles;
                else endPoint ~= nullPointParticles;
                goto replaceNulls;
            }

            endPoint [j] = pList [i];
        }
    }

    void tick () {
        tickInternal!(Particle) (pointParticles);
        foreach (pList; spriteParticles) {
            tickInternal!(SpriteParticle) (pList);
        }
    }

    protected void tickInternal (T) (ref T [] particleList) {
        for (uint i = 0; i < particleList.length; i++) {
            // If the index is null, skip it
            if (!particleList [i])
                continue;

            if (particleList [i].lifetime <= 0) // If the particle's lifetime is over, remove it
                particleList [i] = null;
            else // If not, update the particle's lifetime
                particleList [i].lifetime--;
        }

        foreach (p; particleList) {
            // If p is null, skip it
            if (!p)
                continue;

            // Tick the particle
            p.tick ();

            // Update the alpha of the particle according to its lifetime
            float ratio = (cast (float) (p.lifetime * 1.5f) / p.spawnLifetime) * 255.0f;
            p.color.a = to!ubyte (ratio > 255 ? 255 : ratio);
        }
    }

    override void draw (RenderTarget target, RenderStates states) {
        // Apply the transform
        states.transform *= getTransform ();

        /+ Point particles +/
        states.texture = null;
        VertexArray ppVertices = new VertexArray (PrimitiveType.Points, count!("!(a is null)") (pointParticles));
        size_t index = 0;

        foreach (p; pointParticles) {
            if (!p)
                continue;

            ppVertices [index].position = Vector2f (cast (float) p.X, cast (float) p.Y);
            ppVertices [index].color = p.color;
            index++;
        }

        // Draw the vertex array
        target.draw (ppVertices, states);
    }
}

static ParticleSystem particleSystem;
// These are so we don't have to create them every time we want to add null particles to an array
static Particle [1500] nullPointParticles;
static SpriteParticle [500] nullSpriteParticles;