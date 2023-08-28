
### Intro ###

Write a lexer and parser (using ANTLR) and a semantics analyzer for
simple Java-like language described in this file.

 - Each program starts with a keyword "project" and has static fields,
   static methods, inerfaces, and inner classes.
 - The main method in the language is always called entry().
 - There are:
   -- three types of constants: int, char, and boolean.
   -- several primitive types: int, boolean, char (ASCII only), enums.
   -- several kinds of variables: global (static), local, fields.
   -- reference types: arrays like in Java, interfaces and inner
      classes with fields and methods.
   -- static methods
 - There is also class inheritance and polymorphism.
 - Overloading is also available.
 - Three predefined procedure include: ord, chr, and len.
 - The "print" method prints values for all primitive types.
 - Control structures include "if" and "for".


### Syntax ###

Below, you can find "terminals" and terminals, as well as
Non-terminals.  We use alteration (|) and we show that some things can
repeat zero or more times between {and}.

Project = "project" ident {ConstDecl | VarDecl | ClassDecl| EnumDecl | InterfaceDecl} "{" {MethodDecl} "}".

ConstDecl = "const" Type ident "=" (numConst | charConst| booleanConst) {, ident "=" (numConst | charConst | booleanConst)} ";".

EnumDecl = "enum" ident "{" ident ["=" numConst] {"," ident ["=" numConst]} "}".

VarDecl = Type ident ["[" "]"] {"," ident ["[" "]"]} ";".

ClassDecl = "class" ident ["extends" Type] ["implements" Type {"," Type}]"{"  {VarDecl}["{"{MethodDecl} "}"]"}".

InterfaceDecl = "interface" ident "{"{InterfaceMethodDecl} "}".

InterfaceMethodDecl = (Type | "void") ident "(" [FormPars]")" ";".

MethodDecl = (Type | "void") ident "(" [FormPars]")" {VarDecl} "{" {Statement} "}".

FormPars = Type ident ["[" "]"] {"," Type ident ["[" "]"]}.

Type = ident.

Statement =  DesignatorStatement ";"
  | "if" "(" Condition ")" Statement ["else" Statement]
  | "for" "(" [DesignatorStatement ] ";" [Condition] ";" [DesignatorStatement] ")" Statement
  | "break" ";"
  | "continue" ";"
  | "return" [Expr] ";"
  | "read" "(" Designator ")" ";"
  | "print" "(" Expr ["," numConst] ")" ";"
  | "{" {Statement} "}".

DesignatorStatement = Designator (Assignop Expr | "(" [ActPars] ")" | "++" | "--").

ActPars = Expr {"," Expr}.

Condition = CondTerm {"||" CondTerm}.

CondTerm = CondFact {"&&" CondFact}.

CondFact = Expr [Relop Expr].

Expr = ["-"] Term {Addop Term}.

Term = Factor {Mulop Factor}.

Factor = Designator ["(" [ActPars] ")"]
  | numConst
  | charConst
  | booleanConst
  | "new" Type ["[" Expr "]"]
  | "(" Expr ")".

Designator = ident {"." ident | "[" Expr "]"}.

Assignop = "=".

Relop = "==" | "!=" | ">" | ">=" | "<" | "<=".

Addop = "+" | "-".

Mulop = "*" | "/" | "%".


### Other Lexical Structures ###

keywords: project, break, class, interface, enum, else, const, if,
new, print, read, return, void, for, extends, continue

token types:
    ident = letter {letter | digit | "_"}.
    numConst = digit {digit}.
    charConst = "'" printableChar "'".
    booleanConst = ("true" | "false")

operators: +, -, *, /, %, ==, !=, >, >=, <, <=, &&, ||, =, ++, --, ;,
comma, ., (, ), [, ], {, }

comments: // until the end of the line

OUTPUT: if there is any lexical error, print "LEX ERROR" to the stdout.


### Semantics ###

 - Each name must be declared before its fist use.
   OUTPUT: if this error happens, output "NAME USE ERROR" to the stdout.
 - There cannot be two variables with the same name in one scope.
   OUTPUT: if this error happens, output "VAR ERROR" to the stdout.
 - There must be a method "entry"; the return type must be void and the
   method should have no arguments.
   OUTPUT: if this error happens, output "ENTRY ERROR" to the stdout.
 - Come up with an analysis that you find appropriate for this language,
   implement it and describe briefly (using an example test program).

These checks should be done on the AST. Note that ANTLR already
generates visitors for you (see the provided script).

OUTPUT: if there is any error during parsing (order of tokens), print
"PARSER ERROR" to the stdout.


### Submission Instructions ###

Share with us a PRIVATE GitHub repository (see syllabus for our IDs)
that use the following naming convention: pp-YOUR_UT_ID.  If
YOUR_UT_ID is "abc", then share: pp-abc.

Take the given directory (do NOT change the name) and include into
your repository.  (Extending the example above, you would have
pp-abc/lexparse.)

Then you should start modifying code/ and tests/.  No need to modify
files outside these two directories.


### Clarifications and Hints ###

We expect you will mostly modify the following files: code/simple,
code/SimpleLang.g4, files that implement Visitors.

We will use Linux to test all assignments. If you do not test on
Linux, we might see different result from you.

Be creative.  When something is unclear make a reasonable assumption.

Also, do not try to cover everything at once; start with small
examples and then expand from there.
