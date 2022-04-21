Don't Repeat Yourself Scripting Library - Commonly needed scripts
======================================

The _SIDRA Scripting Library_ (abbrev. 'SIDRA' in source code) is a collection of useful scripts in the form of functions and scripts (or "recipes", as in Chef lingo, although this library does not relate to Chef at all). Several subjects are covered relating but not limited to file manipulation, tech ops, text processing etc.

Key advantages of using it in your project / environment:

* Convention over configuration e.g. all files in "$ZDRA_HOME/functions/" are sourced during 'zdraload' (the entry point of this library, sourced in your shell profile).
* chmod automagic: all scripts in recipes\*/ or scripts\*/ directories are marked executable (chmod +x) during profile sourcing (how many times in your life did you have to chmod before calling a script? not anymore...).
* Plugability i.e. modularized: Easy plugin installation & maintenance mechanism.

Currently the ___Bash___ and ___Zsh___ shells are supported.

Some features of this project replicate GNU tools features and those were intentional as to have this possibilities in a non-GNU environment. (Perhaps you are on IBM AIX where policies or sysadmins do not allow for the 'GNU toolbox for AIX' to be installed etc.)

Help
----

The zdrahelp function is the help system entry point. It will output something like this:

```
zdrahelp - display this help messsage
zdrainfo - display environment information
zdralistfunctions - list SIDRA Scripting Library's functions
zdralistscripts - list SIDRA Scripting Library's scripts
zdraversion - display the version of this SIDRA Scripting Library instance
```

__Important__

___Soon the zdrahelp command will accept the name of a function or script as an argument and will display its corresponding help and/or usage message.___

Installation
------------

### Automatic

Copy & paste the following command into your shell session in a terminal:

```bash
bash -c "$(curl -LSf "https://raw.githubusercontent.com/stroparo/sidra/master/setup.sh" \
  || curl -LSf "https://bitbucket.org/stroparo/sidra/raw/master/setup.sh")"
type zdraload >/dev/null 2>&1 && zdraload || . ~/.zdra/zdra.sh
```

ERROR curl not found: If you do not have curl, substitute the 'curl [options]' call for ```wget -O -```.

If behind a proxy try disabling SSL by adding curl's -k option to the installation command above.

### Manual

You might want to install SIDRA manually when there is a network restriction such as no Internet access for the host etc.

Execute:

1. Create the directory to house the final install which the official ZDRA_HOME variable will point to.
2. Place the files in that ZDRA_HOME directory.
3. Source **zdra.sh** in your shell profile i.e.

* .bashrc
* .zshrc
* .profile
* Etcera

The default ZDRA_HOME is $HOME/.zdra (~/.zdra) so if you install in there, just source zdra.sh:

```bash
source ~/.zdra/zdra.sh
```

Otherwise, specify the directory (after sourcing it will be pointed to by the $ZDRA_HOME environment variable) both as zdra.sh's dirname as well as the last argument:

```bash
source {dir}/zdra.sh {dir}
```

Plugins - Make your Shell Scripts pluggable with no fuss!
---------------------------------------------------------

Nowadays lots of software are modular and allow for plugability via Git repositories etc. In this same spirit, the plugin mechanism for SIDRA aims to be as straightforward as it gets by just cloning a repository and copying it over on top of $ZDRA_HOME, this library's root installation directory.

The script that performs this is ```zdraplugin.sh```.

It expects ```user/repo``` as the argument. It will pull that user's repo from ___github.com___ by the default. To use another domain just prepend it with a slash like in ```domain/user/repo``` (exactly as in an HTTPS clone URL).

### Examples

```bash
# This will pull github.com/stroparo/ds-stroparo
zdraplugin stroparo/ds-stroparo

# This will pull bitbucket.org/stroparo/ds-stroparo
zdraplugin bitbucket.org/stroparo/ds-stroparo
```

Usage & Examples
----------------

### Aggregate a file

```bash
getmax fieldsep field files...
```

```bash
getmin fieldsep field files...
```

```bash
getsum fieldsep field files...
```

### Append a string to a file only once

```bash
appendunique string file1 file2 ...
```

### End of line: windows to linux

```bash
dos2unix file1 file2 ...
```

### Grep context emulation (GNU grep's -A, -B & -C options)

```bash
grepc [-a afterlines] [-b beforelines] [-c contextlines]
```

Use -a, -b and -c to emulate GNU grep's -A, -B and -C options, respectively.

Default behavior is ```-c 10```.

### Grepping a process

```bash
pgr ExtendedREGEX
```

### INI file section extraction

```bash
getsection sectionpattern filename
```

File ab.txt:

```
[a]
b=1
c=2

[d]
e=3
f=4
```

```bash
getsection a ab.txt
```

Will output:

```
b=1
c=2
```

### Looping commands

```bash
loop command [arguments ...]
```

### Path munging

```bash
pathmunge [-v varname] [-x] {path} [path2 [path3 ...]]
```

* ```-v varname``` causes the ```varname``` variable to be munged instead of the default (```PATH```)
* ```-x``` causes the variable to be exported

### Printing fields with awk

```bash
printawk [-F fieldsep] fieldno1 [fieldno2 ...]
```

* ```-F fieldsep``` works (as in awk) e.g. ```printawk -F, 1 2 ...```

Example:

```bash
printawk 1 3 5
```

Prints fields 1, 3 and 5

### Rename files in a tidy fashion

```bash
rentidy {dir}
```

Renames files and directories recursively at {dir}.

Underscores, camel case instances and other special characters are substituted by a hyphen separator.

### User confirmation and input

```bash
userconfirm message
```

```bash
userinput message
```

Input will be stored in the ```userinput``` variable

```bash
validinput {message} {ere-extended-regex}
```

Input will be stored in the ```userinput``` variable; prompts user for the input repeatedly until it matches the regular expression

