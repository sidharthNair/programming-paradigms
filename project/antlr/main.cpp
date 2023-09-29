#include <iostream>

#include "antlr4-runtime.h"
#include "CypherLexer.h"
#include "CypherParser.h"

using namespace antlrcpptest;
using namespace antlr4;

int main(int, const char **)
{
    while (true)
    {
        std::cout << "(cypher) > ";
        std::string command;
        getline(std::cin, command);

        if (command.empty())
        {
            continue;
        }

        ANTLRInputStream input(command);
        CypherLexer lexer(&input);
        CommonTokenStream tokens(&lexer);

        tokens.fill();
        if (lexer.getNumberOfSyntaxErrors() > 0)
        {
            std::cout << std::endl;
            continue;
        }

        CypherParser parser(&tokens);
        tree::ParseTree *tree = parser.oC_Cypher();
        if (parser.getNumberOfSyntaxErrors() > 0)
        {
            std::cout << std::endl;
            continue;
        }

        std::cout << "successful command" << std::endl
                  << std::endl;
    }

    return 0;
}
