#include <iostream>
#include <fstream>
#include <csignal>
#include <regex>
#include <curl/curl.h>
#include <json/json.h>
#include <sqlite3.h>

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

std::string getCommand()
{
    std::cout << "(cypher) > ";
    std::string command;
    getline(std::cin, command);

    while (command.back() == '\\' && running)
    {
        std::cout << "\t\t";
        command.pop_back();
        std::string add;
        getline(std::cin, add);
        command.append(add);
    }

    return command;
}

bool isModifyingQuery(const std::string &cypherQuery)
{
    std::regex createPattern(R"(CREATE\s.*)", std::regex::icase);
    std::regex mergePattern(R"(MERGE\s.*)", std::regex::icase);
    std::regex setPattern(R"(SET\s.*)", std::regex::icase);
    std::regex deletePattern(R"(DELETE\s.*)", std::regex::icase);

    return std::regex_search(cypherQuery, createPattern) ||
           std::regex_search(cypherQuery, mergePattern) ||
           std::regex_search(cypherQuery, setPattern) ||
           std::regex_search(cypherQuery, deletePattern);
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
    if (value.isString())
    {
        ret << value.asString() << std::endl;
    }
    else if (value.isInt())
    {
        ret << value.asInt() << std::endl;
    }
    else if (value.isMember("Type"))
    {
        ret << value["ElementId"].asString() << " (" << value["StartId"].asString() << ")-[" << value["Type"].asString() << "]-(" << value["EndId"].asString() << ") " << writer.write(value["Props"]);
    }
    else if (value.isMember("Labels"))
    {
        ret << value["ElementId"].asString() << " " + writer.write(value["Labels"]) << " " << writer.write(value["Props"]);
    }
    std::string tmp = ret.str();
    tmp.erase(std::remove(tmp.begin(), tmp.end(), '\n'), tmp.end());
    return tmp;
}

int main(int argc, const char **argv)
{
    signal(SIGINT, handleInterrupt);
    CURL *curl;
    CURLcode res;
    sqlite3 *db;
    int rc;
    Json::StreamWriterBuilder writer;

    std::string external_command;
    if (argc == 2)
    {
        external_command = argv[1];
    }

    rc = sqlite3_open("cache.db", &db);
    if (rc)
    {
        std::cerr << "Error opening sqlite db: " << sqlite3_errmsg(db) << std::endl;
        return rc;
    }

    const std::string createTableSQL = "CREATE TABLE IF NOT EXISTS cache ("
                                       "id INTEGER PRIMARY KEY AUTOINCREMENT,"
                                       "command TEXT NOT NULL,"
                                       "response TEXT NOT NULL);";
    sqlite3_exec(db, createTableSQL.c_str(), NULL, NULL, NULL);

    curl = curl_easy_init();
    if (!curl)
    {
        std::cerr << "Error initializing curl" << std::endl;
        sqlite3_close(db);
        return 1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:8080/request");
    curl_easy_setopt(curl, CURLOPT_POST, 1L);

    struct curl_slist *headers = NULL;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    bool external = false;
    while (running && !external)
    {
        std::string command;
        if (external_command.empty())
        {
            command = getCommand();
            if (command.empty())
            {
                continue;
            }
        }
        else
        {
            command = external_command;
            external = true;
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

        std::string response_data;
        bool modifying = isModifyingQuery(command);
        bool got_cached = false;
        if (!modifying)
        {
            std::string selectDataSQL = "SELECT response FROM cache WHERE command = '" + command + "';";
            sqlite3_stmt *stmt;
            rc = sqlite3_prepare_v2(db, selectDataSQL.c_str(), -1, &stmt, nullptr);

            if (rc != SQLITE_OK)
            {
                std::cerr << "Error preparing select statement: " << sqlite3_errmsg(db) << std::endl;
                break;
            }

            rc = sqlite3_step(stmt);

            if (rc == SQLITE_ROW)
            {
                std::cout << "Using cached response:" << std::endl;
                const unsigned char *response = sqlite3_column_text(stmt, 0);
                response_data = std::string(reinterpret_cast<const char *>(response));
                got_cached = true;
            }
            else
            {
                std::cerr << "No cached response found for command: " << command << std::endl;
            }

            sqlite3_finalize(stmt);
        }

        if (!got_cached)
        {
            Json::Value request;
            request["request"] = command;
            std::string request_data = Json::writeString(writer, request);

            curl_easy_setopt(curl, CURLOPT_POSTFIELDS, request_data.c_str());
            curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, request_data.length());

            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, responseCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
            res = curl_easy_perform(curl);
            if (res != CURLE_OK)
            {
                std::cerr << "curl request failed: " << curl_easy_strerror(res) << std::endl;
                continue;
            }

            if (modifying)
            {
                const std::string deleteRowsSQL = "DELETE FROM cache;";
                rc = sqlite3_exec(db, deleteRowsSQL.c_str(), 0, 0, 0);
                if (rc != SQLITE_OK)
                {
                    std::cerr << "Error invalidating cache: " << sqlite3_errmsg(db) << std::endl;
                    break;
                }
                else
                {
                    std::cout << "Modifying query submitted, invalidated cache" << std::endl;
                }
            }
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

        Json::StyledWriter styledWriter;
        std::ofstream file("response.json");
        if (file.is_open())
        {
            file << styledWriter.write(response);
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
            for (const Json::Value &element : response["Keys"])
            {
                header << "| " << element.asString() << " ";
            }
            header << "|\n";
            length = std::max(length, (int)header.str().length());

            std::stringstream separator;
            separator << "+";
            for (int i = 0; i < length - 3; i++)
            {
                separator << "-";
            }
            separator << "+\n";

            std::cout << separator.str() << header.str() << separator.str() << result << separator.str();
        }

        if (!modifying && !got_cached)
        {
            std::string insertDataSQL = "INSERT INTO cache (command, response) VALUES ('" + command + "', '" + response_data + "');";
            rc = sqlite3_exec(db, insertDataSQL.c_str(), NULL, NULL, NULL);
            if (rc != SQLITE_OK)
            {
                std::cerr << "Error caching response: " << sqlite3_errmsg(db) << std::endl;
                break;
            }
            else
            {
                std::cout << "Cached response" << std::endl;
            }
        }

        std::cout << std::endl;

        if (external)
        {
            break;
        }
    }

    sqlite3_close(db);
    curl_easy_cleanup(curl);
    curl_slist_free_all(headers);
    return 0;
}
