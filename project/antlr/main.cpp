#include <iostream>

#include "antlr4-runtime.h"
#include "CypherLexer.h"
#include "CypherParser.h"

using namespace antlrcpptest;
using namespace antlr4;

int main(int , const char **) {
  ANTLRInputStream input("test input");
  CypherLexer lexer(&input);
  CommonTokenStream tokens(&lexer);

  tokens.fill();
  for (auto token : tokens.getTokens()) {
    std::cout << token->toString() << std::endl;
  }

  CypherParser parser(&tokens);
  tree::ParseTree* tree = parser.oC_Cypher();

  std::cout << tree->toStringTree(&parser) << std::endl << std::endl;

  return 0;
}
