#include <iostream>
#include <fstream>
#include <csignal>
#include <curl/curl.h>
#include <json/json.h>

#include "antlr4-runtime.h"
#include "CypherLexer.h"
#include "CypherParser.h"

using namespace antlrcpptest;
using namespace antlr4;

bool running = true;
std::vector<std::string> history;

void handleInterrupt(int signal)
{
    if (signal == SIGINT)
    {
        running = false;
        std::cout << std::endl
                  << "Interrupt signal received. Press Enter to quit..." << std::endl;
    }
}

size_t responseCallback(void *contents, size_t size, size_t nmemb, std::string *output)
{
    size_t total = size * nmemb;
    output->append(static_cast<char *>(contents), total);
    return total;
}

std::string formatValue(const Json::Value &value)
{
    std::stringstream ret;
    Json::FastWriter writer;
    if (value.isMember("Type"))
    {
        ret << value["ElementId"].asString() << " (" << value["StartId"].asString() << ")-[" << value["Type"].asString() << "]-(" << value["EndId"].asString() << ") " << writer.write(value["Props"]);
    }
    else if (value.isMember("Labels"))
    {
        ret << value["ElementId"].asString() << " " + writer.write(value["Labels"]) << " " << writer.write(value["Props"]);
    }
    else
    {
        ret << value.asString() << std::endl;
    }
    std::string tmp = ret.str();
    tmp.erase(std::remove(tmp.begin(), tmp.end(), '\n'), tmp.end());
    return tmp;
}

int main(int, const char **)
{
    signal(SIGINT, handleInterrupt);
    CURL *curl;
    CURLcode res;

    curl = curl_easy_init();
    if (!curl)
    {
        std::cerr << "Error initializing curl" << std::endl;
        return 1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:8080/request");
    curl_easy_setopt(curl, CURLOPT_POST, 1L);

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    Json::StreamWriterBuilder writer;

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

        if (command[0] == '/')
        {
            command.erase(0, 1);
            command.push_back(' ');
            size_t pos = 0;
            std::string token;
            if ((pos = command.find(" ")) != std::string::npos)
            {
                token = command.substr(0, pos);
                if (token == "exit")
                {
                    break;
                }
                else if (token == "history")
                {
                    for (int i = 0; i < history.size(); i++)
                    {
                        std::cout << history[i] << std::endl;
                    }
                }
                else
                {
                    std::cout << "Invalid command, options: /history, /exit" << std::endl;
                }
            }
            std::cout << std::endl;
            continue;
        }
        else
        {
            history.push_back(command);
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

        Json::Value request;
        request["request"] = command;
        std::string request_data = Json::writeString(writer, request);

        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request_data.c_str());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, request_data.length());

        std::string response_data;
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, responseCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
        res = curl_easy_perform(curl);
        if (res != CURLE_OK)
        {
            std::cerr << "curl request failed: " << curl_easy_strerror(res) << std::endl;
            continue;
        }

        Json::CharReaderBuilder reader;
        Json::Value response;
        std::istringstream response_stream(response_data);
        JSONCPP_STRING err;
        if (!Json::parseFromStream(reader, response_stream, &response, &err))
        {
            std::cout << response_data << std::endl;
            continue;
        }

        Json::StyledWriter writer;
        std::ofstream file("response.json");
        if (file.is_open())
        {
            file << writer.write(response);
            file.close();
        }
        else
        {
            std::cerr << "Unable to open file for writing" << std::endl;
        }

        std::string result;
        int length = 0;
        for (const Json::Value &element : response["Records"])
        {
            std::stringstream tmp;
            for (const Json::Value &inner : element["Values"])
            {
                tmp << "| " << formatValue(inner) << " ";
            }
            tmp << "|\n";
            std::string converted = tmp.str();
            length = std::max(length, (int)converted.length());
            result.append(converted);
        }

        if (!result.empty())
        {
            std::stringstream header;
            std::stringstream separator;
            separator << "+";
            for (int i = 0; i < length - 2; i++)
            {
                separator << "-";
            }
            separator << "+\n";
            header << separator.str();
            for (const Json::Value &element : response["Keys"])
            {
                header << "| " << element.asString() << " ";
            }
            header << "|\n"
                   << separator.str();

            std::cout << header.str() << result << separator.str();
        }
        std::cout << std::endl;
    }

    curl_easy_cleanup(curl);
    curl_slist_free_all(headers);
    return 0;
}
