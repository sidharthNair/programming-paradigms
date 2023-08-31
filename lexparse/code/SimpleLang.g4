grammar SimpleLang;

fragment CHAR       : ([a-z] | [A-Z]) ;
fragment DIGIT      : [0-9] ;

PROJECT         : 'project' ;
CLASS           : 'class' ;
INTERFACE       : 'interface' ;
ENUM            : 'enum' ;
CONST           : 'const' ;
IF              : 'if' ;
ELSE            : 'else' ;
NEW             : 'new' ;
PRINT           : 'print' ;
READ            : 'read' ;
RETURN          : 'return' ;
VOID            : 'void' ;
FOR             : 'for' ;
BREAK           : 'break' ;
EXTENDS         : 'extends' ;
IMPLEMENTS      : 'implements' ;
CONTINUE        : 'continue' ;
IDENT           : CHAR (CHAR | DIGIT | '_')* ;
NUMCONST        : DIGIT (DIGIT)* ;
CHARCONST       : '\'' [\u0020-\u007E] '\'' ;
BOOLEANCONST    : ('True' | 'False') ;
ASSIGN          : '=' ;
PLUS            : '+' ;
MINUS           : '-' ;
MULTIPLY        : '*' ;
DIVIDE          : '/' ;
MODULO          : '%' ;
EQUAL           : '==' ;
NOT_EQUAL       : '!=' ;
GREATER         : '>' ;
GREATER_EQUAL   : '>=' ;
LESS            : '<' ;
LESS_EQUAL      : '<=' ;
AND             : '&&' ;
OR              : '||' ;

WHITESPACE      : [ \t\r\n]+ -> skip ;
COMMENT         : '//' (~[\r\n])* -> skip ;
OTHER           : . ;

project     : PROJECT IDENT (constDecl | varDecl | classDecl | enumDecl | interfaceDecl)* '{' (methodDecl)* '}' ;

constDecl   : CONST type constSet (',' constSet)* ';' ;
constSet    : IDENT ASSIGN (NUMCONST | CHARCONST | BOOLEANCONST) ;

enumDecl    : ENUM IDENT '{' enumSet (',' enumSet)* '}' ;
enumSet     : IDENT (ASSIGN NUMCONST)? ;

varDecl     : type var (',' var)* ';' ;
var         : IDENT ('[' ']')? ;

classDecl   : CLASS IDENT (EXTENDS type)? (IMPLEMENTS type (',' type)*)? '{' (varDecl)* ('{' (methodDecl)* '}')? '}' ;

interfaceDecl       : INTERFACE IDENT '{' (interfaceMethodDecl)* '}' ;
interfaceMethodDecl : (type | VOID) IDENT '(' (formPars)? ')' ';' ;

methodDecl  : (type | VOID) IDENT '(' (formPars)? ')' (varDecl)* '{' (stmt)* '}' ;

formPars    : parameter (',' parameter)* ;
parameter   : type IDENT ('[' ']')? ;

type        : IDENT ;

stmt        : (designatorStmt ';')
              | (IF '(' condition ')' stmt (ELSE stmt)?)
              | (FOR '(' (designatorStmt)? ';' (condition)? ';' (designatorStmt)? ')' stmt)
              | (BREAK ';' )
              | (CONTINUE ';')
              | (RETURN (expr)? ';')
              | (READ '(' designator ')' ';')
              | (PRINT '(' expr (',' NUMCONST)? ')' ';')
              | ('{' (stmt)* '}') ;
designatorStmt  : designator ((assignop expr)
                            | ('(' (actPars)? ')')
                            | ('++')
                            | ('--') ) ;

actPars     : expr (',' expr)* ;

condition   : condTerm ('||' condTerm)* ;
condTerm    : condFact ('&&' condFact)* ;
condFact    : expr (relop expr)? ;

expr        : ('-')? term (addop term)* ;
term        : factor (mulop factor)* ;
factor      : (designator ('(' (actPars)? ')')?)
              | NUMCONST
              | CHARCONST
              | BOOLEANCONST
              | (NEW type ('[' expr ']')?)
              | ('(' expr ')') ;

designator  : IDENT (('.' IDENT) | ('[' expr ']'))* ;

assignop    : ASSIGN ;
relop       : EQUAL | NOT_EQUAL | GREATER | GREATER_EQUAL | LESS | LESS_EQUAL ;
addop       : PLUS | MINUS ;
mulop       : MULTIPLY | DIVIDE | MODULO ;
