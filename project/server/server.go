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
		return fmt.Sprintf("%d %v %v", v.Id, v.Labels, v.Props)
	case dbtype.Relationship:
		return fmt.Sprintf("%d (%d)-[%s]-(%d) %v", v.Id, v.StartId, v.Type, v.EndId, v.Props)
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
		http.Error(w, fmt.Sprintf("%s", err), http.StatusInternalServerError)
		fmt.Println(err)
		return
	}

	var response string

	var length int = 0
	for _, record := range result.Records {
		var tmp string
		for _, key := range record.Keys {
			value, _ := record.Get(key)
			tmp += "| " + formatValue(value) + " "
		}
		tmp += "|\n"
		length = max(length, len(tmp))
		response += tmp
	}

	var header string
	var separator string = "+"
	for i := 0; i < length-2; i++ {
		separator += "-"
	}
	separator += "+\n"

	if result.Summary.Counters().ContainsUpdates() {
		header += "Database Updated\n"
	} else {
		header = fmt.Sprintf("Records Returned: %v\n", len(result.Records))
		header += separator

		record := result.Records[0]
		for _, key := range record.Keys {
			header += fmt.Sprintf("| %s ", key)
		}
		header += "|\n" + separator
	}

	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, header+response+separator)
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
