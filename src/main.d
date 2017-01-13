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

module main;

import dsfml.system;
import dsfml.window;
import dsfml.graphics;
import gameDefs;
import playSim;
import renderer;
import particleSys;

public void main () {
    Clock updClock = new Clock (); // Create the game update clock
    Clock renderClock = new Clock (); // Create the game update clock
    Duration ticTime; // The time since the last tic

    gameInit ();
    videoInit ();

    writeln ("Creating SFML window");
    auto contextSet = cast (const (ContextSettings)) ContextSettings (24, 8, 0, 3, 0);
    mainWindow = new RenderWindow (VideoMode (800, 600), "Gryphon butts"d, Window.Style.DefaultStyle, contextSet); // Create the window
    Joystick.update ();
    for (int i = 0; i < 8; i++) {
        write (i, ": ", Joystick.isConnected (i));
    }
    // Run the game loop
    while (mainWindow.isOpen ()) {
        // If enough time has passed since the last tic
        if (updClock.getElapsedTime ().total!"hnsecs" () >= ticLength) {
            ticTime = updClock.restart (); // Restart the game update clock and store the time in ticTime
            updateGame (ticTime); // Update the game
        }

        // Check all the window's events that were triggered since the last iteration of the loop
        Event event;
        while (mainWindow.pollEvent (event)) {
            // "Close requested" event: we close the window
            switch (event.type) {
            case Event.EventType.Closed:
                mainWindow.close ();
            break;

            case Event.EventType.LostFocus:
                GameInfo.focused = false;
            break;

            case Event.EventType.GainedFocus:
                GameInfo.focused = true;
            break;

            case Event.EventType.KeyPressed: // Code custom key bindings later
            break;

            default: break;
            }
        }

        // If enough time has passed since the last render or the tic 
        if (GameInfo.focused && ticTime < ticThresholdDuration && (renderLength <= 0 || renderClock.getElapsedTime ().total!"hnsecs" >= renderLength)) {
            renderGame (ticTime, renderClock.restart ()); // Restart the render clock and render the game
        }
    }
}
