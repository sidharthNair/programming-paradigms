#include <iostream>
#include <csignal>
#include <curl/curl.h>

#include "antlr4-runtime.h"
#include "CypherLexer.h"
#include "CypherParser.h"

using namespace antlrcpptest;
using namespace antlr4;

bool running = true;

void handleInterrupt(int signal)
{
    if (signal == SIGINT)
    {
        running = false;
        std::cout << std::endl
                  << "Interrupt signal received. Press Enter to quit..." << std::endl;
    }
}

int main(int, const char **)
{
    signal(SIGINT, handleInterrupt);
    CURL *curl;
    CURLcode res;

    curl = curl_easy_init();
    if (!curl)
    {
        std::cout << "Error initializing curl" << std::endl;
        return 1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:8080/request");
    curl_easy_setopt(curl, CURLOPT_POST, 1L);

    while (running)
    {
        std::cout << "(cypher) > ";
        std::string command;
        getline(std::cin, command);
        if (command.empty())
        {
            continue;
        }

        while (command.back() == '\\' && running)
        {
            std::cout << "\t\t";
            command.pop_back();
            std::string add;
            getline(std::cin, add);
            command.append(add);
        }

        if (!running)
        {
            break;
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

        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, command.c_str());
        res = curl_easy_perform(curl);
        if (res != CURLE_OK)
        {
            std::cerr << "curl request failed: " << curl_easy_strerror(res) << std::endl;
        }
        std::cout << std::endl;
    }

    curl_easy_cleanup(curl);
    return 0;
}
