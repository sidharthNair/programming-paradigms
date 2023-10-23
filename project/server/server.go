package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/neo4j/neo4j-go-driver/v5/neo4j"
	"github.com/neo4j/neo4j-go-driver/v5/neo4j/dbtype"
)

const neo4jURI = "bolt://localhost:7687"
const neo4jUser = "neo4j"
const neo4jPassword = "neo4j"

type RequestData struct {
	Request string `json:"request"`
}

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

	var data RequestData
	decoder := json.NewDecoder(r.Body)
	err := decoder.Decode(&data)
	if err != nil {
		http.Error(w, "Error parsing request", http.StatusBadRequest)
		fmt.Println(err)
		return
	}
	request := data.Request

	ctx := context.Background()
	driver, err := neo4j.NewDriverWithContext(neo4jURI, neo4j.BasicAuth(neo4jUser, neo4jPassword, ""))
	if err != nil {
		fmt.Println("Failed to connect to the Neo4j database", err)
		return
	}
	defer driver.Close(ctx)

	result, err := neo4j.ExecuteQuery(ctx, driver, request, nil, neo4j.EagerResultTransformer, neo4j.ExecuteQueryWithDatabase("neo4j"))
	if err != nil {
		http.Error(w, fmt.Sprintf("%s", err), http.StatusInternalServerError)
		fmt.Println(err)
		return
	}

	json, err := json.Marshal(result)
	fmt.Printf("result: %s\n", string(json))

	w.Header().Set("Content-Type", "application/json")
	_, err = w.Write(json)
	if err != nil {
		http.Error(w, "Failed to write response", http.StatusInternalServerError)
		return
	}
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
