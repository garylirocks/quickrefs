Regular Expression cheatsheet
===============

## BRE & ERE & PCRE

Regular expression on Linux/Mac command line/Vim has different flavors, be aware of it when using.

1. **BRE**, basic regular expression

    `+ ? | ( ) { }` are literals, don't have special meaning by default, need to be escaped to be special

    usage: `grep`, `sed`, *vim search*

2. **ERE**, extended regular expression

    `+ ? | ( ) { }` are metacharacters by default

    usage: `grep -E`, `egrep`, `sed -r` (Linux), `sed -E` (Mac), `awk`

3. **PCRE**: Perl compatible regular expression, looks like not working on Mac;

    `\d`, `\w`, etc are supported

    usage: `grep -P`, *vim search with `\v`*
