# SIDRA

Scripting Development and Runtime (Utils) Acceleration

## IMPORTANT: Under Construction

Currently [the Daily Shells project](https://github.com/stroparo/ds) should be used instead. That project is being refactored in preparation to become this one in a near future.

Key advantages of using it in your project / environment:

* Convention over configuration e.g. all files in "$DS_HOME/functions/" are sourced during 'dsload' (the entry point of this library, sourced in your shell profile).
* chmod automagic: all scripts in recipes\*/ or scripts\*/ directories are marked executable (chmod +x) during profile sourcing (how many times in your life did you have to chmod before calling a script? not anymore...).
* Plugability i.e. modularized: Easy plugin installation & maintenance mechanism.
