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

module playSim;

import dsfml.system;
import dsfml.audio;
import dsfml.graphics;
import dsfml.window;
import gameDefs;
import actorDef;
import particleSys;
static import core.stdc.stdlib;

Texture derp;
Sprite derp1; Sprite derp2; Sprite derp3;
ActorState [4] testStates;
int [string] testStateLabels;
static PlayerPawn localPlayer;

/++ Initializes the playsim ++/
void gameInit () {
    /*writeln ("Initializing static tables");
    FixedMath.generateTables ();*/
    writeln ("Initializing playsim");
    derp = new Texture ();
    if (!derp.loadFromFile ("resources/derp.png")) {
        writeln ("Error: Couldn't load resources/derp.png");
    }
    //derp.setSmooth (true);
    derp1 = new Sprite (); derp2 = new Sprite (); derp3 = new Sprite ();
    derp1.setTexture (derp); derp2.setTexture (derp); derp3.setTexture (derp);
    derp1.textureRect (IntRect (0, 0, 57, 20)); derp2.textureRect (IntRect (0, 21, 57, 20)); derp3.textureRect (IntRect (0, 42, 57, 20));

    testStates [0].spr = derp1; testStates [1].spr = derp2; testStates [2].spr = derp3; testStates [3].spr = derp2;
    testStates [0].length = testStates [1].length = testStates [2].length = testStates [3].length = 4;
    testStates [0].next = 1; testStates [1].next = 2; testStates [2].next = 3; testStates [3].next = 0;
    testStateLabels ["Spawn"] = 2;

    localPlayer = new PlayerPawn ();
    localPlayer.width = 57; localPlayer.height = 20;
    localPlayer.X = 0f; localPlayer.Y = 100f;
    localPlayer.pID = 0;
    localPlayer.changeStateList (testStates, testStateLabels);
    ActorList ~= localPlayer;
    PlayerList ~= localPlayer;

    Actor monstah = new Actor ();
    monstah.width = 57; monstah.height = 20;
    monstah.X = 320; monstah.Y = 200;
    monstah.changeStateList (testStates, testStateLabels);
    ActorList ~= monstah;
}

/++ Ticks/updates the playsim ++/
void updateGame (Duration elapsedTime) {
    particleSystem.tick ();

    // Get player input
    localPlayer.sidewaysInput = 0; localPlayer.forwardInput = 0;
    if (Joystick.isConnected (0)) {
        localPlayer.sidewaysInput =  Joystick.getAxisPosition (0, Joystick.Axis.X);
        localPlayer.forwardInput  = -Joystick.getAxisPosition (0, Joystick.Axis.Y);
    }

    if (Keyboard.isKeyPressed (Keyboard.Key.W) || Keyboard.isKeyPressed (Keyboard.Key.Up))
        localPlayer.forwardInput += 100;
    if (Keyboard.isKeyPressed (Keyboard.Key.S) || Keyboard.isKeyPressed (Keyboard.Key.Down))
        localPlayer.forwardInput += -100;

    if (Keyboard.isKeyPressed (Keyboard.Key.D) || Keyboard.isKeyPressed (Keyboard.Key.Right))
        localPlayer.sidewaysInput += 100;
    if (Keyboard.isKeyPressed (Keyboard.Key.A) || Keyboard.isKeyPressed (Keyboard.Key.Left))
        localPlayer.sidewaysInput += -100;

    if (Keyboard.isKeyPressed (Keyboard.Key.Escape))
        core.stdc.stdlib.exit (0);

    // Tick actors
    foreach (obj; ActorList) {
        if (!obj)
            continue;

        obj.tick ();
    }
}
