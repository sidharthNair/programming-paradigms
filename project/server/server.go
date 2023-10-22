package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/neo4j/neo4j-go-driver/v5/neo4j"
	"github.com/neo4j/neo4j-go-driver/v5/neo4j/dbtype"
)

const neo4jURI = "bolt://localhost:7687"
const neo4jUser = "neo4j"
const neo4jPassword = "neo4j"

func formatValue(value interface{}) string {
	switch v := value.(type) {
	case dbtype.Node:
		return fmt.Sprintf("%d | %v | %v", v.Id, v.Labels, v.Props)
	case dbtype.Relationship:
		return fmt.Sprintf("%d | %s | %v | %d -> %d", v.Id, v.Type, v.Props, v.StartId, v.EndId)
	default:
		return fmt.Sprintf("%v", v)
	}
}

func request(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Only POST requests are allowed", http.StatusMethodNotAllowed)
		return
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		fmt.Println(err)
	}

	query := string(body)

	ctx := context.Background()
	driver, err := neo4j.NewDriverWithContext(neo4jURI, neo4j.BasicAuth(neo4jUser, neo4jPassword, ""))
	if err != nil {
		fmt.Println("Failed to connect to the Neo4j database", err)
		return
	}
	defer driver.Close(ctx)

	result, err := neo4j.ExecuteQuery(ctx, driver, query, nil, neo4j.EagerResultTransformer, neo4j.ExecuteQueryWithDatabase("neo4j"))
	if err != nil {
		http.Error(w, "Failed to execute the Neo4j query", http.StatusInternalServerError)
		fmt.Println(err)
		return
	}

	var response string

	for _, record := range result.Records {
		response += "{\n\t"
		for i, key := range record.Keys {
			value, _ := record.Get(key)
			response += key + ": " + formatValue(value)
			if i < len(record.Keys)-1 {
				response += ",\n\t"
			}
		}
		response += "\n}\n"
	}

	fmt.Printf("Records returned: %v, Database Updated: %v, Time: %+v.\n",
		len(result.Records),
		result.Summary.Counters().ContainsUpdates(),
		result.Summary.ResultAvailableAfter())

	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, response)
}

func main() {
	http.HandleFunc("/request", request)
	port := 8080
	fmt.Printf("Server is running on :%d...\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		fmt.Println("Error:", err)
	}
}
