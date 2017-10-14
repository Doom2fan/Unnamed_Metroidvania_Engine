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

module console.main;

import std.format : format;
import std.array : Appender, appender;
import std.traits : Parameters, Unqual;

enum CVarFlags : int {
    Archive  = 1,
    ReadOnly = 1 << 1,
    User     = 1 << 2,
}

class CVar (T, string cvarName)
    if (!is (Unqual!T == typeof (CVar))) {
    private string _name = cvarName;
    private T val;
    private CVarFlags flags;

    public {
        @property pure nothrow T toType () { return val; }
        alias toType this;

        public this () { this (T.init, CVarFlags.Archive); }
        public this (CVarFlags newFlags) { this (T.init, newFlags); }
        public this (T newVal) { this (newVal, CVarFlags.Archive); }
        public this (T newVal, CVarFlags newFlags) {
            flags = newFlags;
            val = newVal;
        }

        @property T value () { return val; }
        @property void value (T newVal) { val = newVal; }
        @property CVarFlags cvarFlags () { return flags; }
        @property string name () { return _name; }

        void setFlags (CVarFlags newFlags) { flags = newFlags; }
        void addFlags (CVarFlags newFlags) { flags |= newFlags; }
        void removeFlags (CVarFlags flagsToRemove) { flags &= ~flagsToRemove; }

        void opAssign (U : T) (U newVal)
            if (isImplicitlyConvertible (T, U)) {
            val = cast (U) newVal;
        }
        U opCast (U : T) ()
            if (isImplicitlyConvertible (T, U)) {
            return cast (U) val;
        }
    }
}

class CCMD (void function () funcPtr, string ccmdName) {
    string name;
    void function (Parameters!(funcPtr)) fp = funcPtr;

    void run (Parameters!(funcPtr)) {
        fp ();
    }
}

static class Console {
    private {
        string commandLine = "";
        string [] commandBuffer;
        string [] outBuffer;
    }

    public {
        static class Debug {
            public {
                auto debugging = new CVar!(bool, "con_debugInfo") (true, CVarFlags.Archive);
                /++
                Writes its arguments in text format to the console.
                Throws: $(D Exception) on an error writing to the console
                +/
                void write (S...) (lazy S args) {
                    if (debugging)
                        Console.write (args);
                    
                }
                /++
                Writes its arguments in text format to the console, followed by a newline.
                Throws: $(D Exception) on an error writing to the console
                +/
                void writeln (S...) (lazy S args) {
                    if (debugging)
                        Console.writeln (args);
                }
                /++
                Writes its arguments in text format to the console, according to the format in the first argument.
                Throws: $(D Exception) on an error writing to the console
                        $(FormatException) on an error formatting the string
                +/
                void writef (Char, S...) (lazy Char[] fmt, lazy S args) {
                    if (debugging)
                        Console.writef (fmt, args);
                }
                /++
                Writes its arguments in text format to the console, according to the format in the first argument, followed by a newline.
                Throws: $(D Exception) on an error writing to the console
                        $(FormatException) on an error formatting the string
                +/
                void writefln (Char, S...) (lazy Char[] fmt, lazy S args) {
                    if (debugging)
                        Console.writefln (fmt, args);
                }
            }
        }

        void write (S...) (S args) {

        }
        void writeln (S...) (S args) {

        }

        void writef (Char, S...) (in Char[] fmt, S args) {
            Console.write (format (fmt, args));
        }
        void writefln (Char, S...) (in Char[] fmt, S args) {

        }

        void parseCommandLine (string line) {

        }

        /*void addCVar (T : CVar) (T var) {

        }

        void addCCMD (T : CCMD) (T cmd) {

        }*/
    }
}