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

module renderer;

import std.array;
import std.conv : to;
import std.format;
import std.stdio;
import dsfml.system;
import dsfml.graphics;
import dsfml.window;
import chr_tools.stack;
import gameDefs;
import actorDef;
import particleSys;
import playSim;

RenderWindow mainWindow;
Font primaryFont;
bool drawBoundingBoxes = true;
private Clock renderTimeClock;
private Clock fpsClock;
private View screenspaceView;
private RenderTexture worldRender;
private RenderTexture screenspaceRender;
private Sprite renderWorldTex;
private Sprite renderScreenTex;

/++ Initializes the video ++/
void videoInit () {
    // Initialize the video here. Load shaders, initialize classes, etc.
    // Any workarounds for weird/broken/shitty GPUs should be started/checked for here

    // Initialize the clocks
    renderTimeClock = new Clock ();
    fpsClock = new Clock ();
    // Initialize the views and rendertargets
    worldRender = new RenderTexture ();
    worldRender.create (800, 600);
    renderWorldTex = new Sprite ();
    renderWorldTex.setTexture (worldRender.getTexture ());

    screenspaceView = new View (FloatRect (0, 0, 800, 600));
    screenspaceRender = new RenderTexture ();
    screenspaceRender.create (800, 600);
    renderScreenTex = new Sprite ();
    renderScreenTex.setTexture (screenspaceRender.getTexture ());

    // The particle system
    particleSystem = new ParticleSystem ();
    // Construct misc stuff
    primaryFont = new Font ();
    nullPointParticles [] = null;
    nullSpriteParticles [] = null;

    writeln ("Loading fonts");
    if (!primaryFont.loadFromFile ("resources/courier_new.ttf")) {
        writeln ("Could not load font courier_new.ttf. Loading agency_fb.ttf instead.");

        if (!primaryFont.loadFromFile ("resources/agency_fb.ttf"))
            writeln ("Could not load font agency_fb.ttf EITHER. What the FUCK did you do? :v");
    }

    writeln ("Loading shaders");
    /*if (!plasmaBG.loadFromFile ("resources/plasmaBG.vert", "resources/plasmaBG.frag")) {
        // error...
    }*/
    

    writeln ("Initializing video");
}

/++ Renders the game to the screen ++/
void renderGame (Duration ticTime, Duration elapsedTime) {
    renderTimeClock.restart ();
    // Clear the window with black color
    mainWindow.clear (Color.Black);

    if (fpsClock.getElapsedTime ().total!"seconds" >= 1) {
        int avgRT = cast (int) (avgRenderTime.total!"msecs" / framesPerSec);
        mainWindow.setTitle (format ("Gryphon Butts FPS:%s\n%s", framesPerSec, framesPerSec > 0 ? to!string (avgRT) : "???"));

        avgRenderTime = Duration.zero;
        framesPerSec = 0;
        fpsClock.restart ();
    }
    
    renderWorld (worldRender, localPlayer.camera.viewport); // Render the world stuff
    renderScreenspace (screenspaceRender, screenspaceView); // Render the screenspace stuff
    mainWindow.draw (renderWorldTex);
    mainWindow.draw (renderScreenTex);
    
    // End the current frame
    mainWindow.display ();
    avgRenderTime += renderTimeClock.restart ();
    framesPerSec++;
}

void resizeWindow (uint w, uint h) {
    mainWindow.size (Vector2u (w, h));
    
    worldRender.create (w, h);
    renderWorldTex.setTexture (worldRender.getTexture ());

    screenspaceRender.create (w, h);
    renderScreenTex.setTexture (screenspaceRender.getTexture ());
}

private void renderWorld (RenderTexture target, View view) {
    // Set the view and clear the target
    target.view = view;
    target.clear (Color.Black);

    target.draw ([ Vertex (Vector2f (-1024f, 0f)), Vertex (Vector2f (1024f, 0f)) ], PrimitiveType.Lines);
    drawSprites (target); // Render the sprites
    target.draw (particleSystem); // Render the particles system

    target.display (); // Finish rendering
}

private void renderScreenspace (RenderTexture target, View view) {
    // Set the view and clear the target
    target.view = view;
    target.clear (Color.Transparent);

    target.display (); // Finish rendering
}

private void drawSprites (RenderTexture target) {
    Stack!(Sprite *) [const (Texture)] sprListArr;
    foreach (obj; ActorList) {
        if (!obj)
            continue;

        if (cast (Actor) obj) {
            Actor actor = cast (Actor) obj;
            if (!actor.spr || !actor.spr.getTexture ()) {
                writefln ("Error: actor %X has no sprite!", &actor);
                continue;
            }

            RenderStates sprStates = RenderStates ();
            sprStates.transform.translate (cast (float) (actor.X - actor.width / 2.0f), cast (float) -(actor.Y + actor.height));
            target.draw (actor.spr, sprStates);
            if (drawBoundingBoxes && actor.width > 0 && actor.height > 0) {
                RectangleShape boundRect = new RectangleShape (Vector2f ((cast (float) actor.width) - 2.0f, (cast (float) actor.height) - 2.0f));
                boundRect.fillColor = Color.Transparent;
                boundRect.outlineColor = Color.Red;
                boundRect.outlineThickness = 1.0f;
                sprStates.transform.translate (cast (float) -(actor.width / 2.0f + 1.0f), 0.0f);
                target.draw (boundRect, sprStates);
            }
        }
    }
}