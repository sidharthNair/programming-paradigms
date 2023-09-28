# Project

In this project, you will provide database as a service.  This is NOT
a group project, but an individual effort.

We cover graph databases (and talk about Neo4j, which is one
implementation), but if you need more resources check this wiki
article: https://en.wikipedia.org/wiki/Graph_database and this Neo4j
page: https://neo4j.com/docs/getting-started. You can also find free
books on the topic.


## You

Your UT EID plays a role when deciding what language to use and what
features to implement. It is very important to do this computation
properly, as we will grade only those that have done computation
properly.

```
hash(to_lower(eid)) => your group
```

hash function is the following:

```
hash(eid) = ascii(eid[0]) + ascii(eid[1]) + ... ascii(eid[n-1])
```

For example:
```
hash(sb43278) = 477
```

In the following section, we will compute problem that you should
solve by the following formula:

```
your group % N => your item
```

N will be defined in each section below, so pay attention.

```
sn25377 = 115 110 50 53 51 55 55 --> 489
```

## Components

This section describes components of the system. The design is modular
and you can easily replace any part of the system with a more robust
implementation.

```
 ---------        -------------
| client  |----->| visualizer  |
 ---------        -------------
   ^
   |
   v
 ---------
| server  |
 ---------
   ^
   |
   v
 ----------
| database |
 ----------
```

* client - client application that has API for sending
  queries/requests to server

* server - web server serving requests

* database - actual graph database implementation

* visualizer - (in a way part of the client) to visualize the result

In the following subsection we describe each of the components in more
detail.

### Client

Client application is responsible for:
* accepting user input
* checking correctness of the query (lexing + parsing)
* sending the request to server
* accepting the response (json)
* caching the results
* visualizing the results

Client application will be written in several programming languages.

Input by the user will be a Cypher query for the database (which might
be valid or invalid). You can decide in what way to accept the input.
You can decide in what language to write this code (it can even be
Python).

Once you have the input, you should check if the input can be properly
parsed. You should use ANTLR to obtain lexer and parser; grammar file
is already available for Open Cypher
(https://s3.amazonaws.com/artifacts.opencypher.org/M23/Cypher.g4), so
you do not need to write your own. (We define N=4 in this case: 0-Java
lexer+parser, 1-C/C++ lexer+parser, 2-Go lexer+parser, 3-Python
lexer+parser.) If the input cannot be parsed, give a nice error (your
decision what the error should say) and ask for the next input. If the
input is correct, move to the next step.

```
489 % 4 = 1 --> C/C++ lexer+parser
```

Once the input is successfully parsed, you should prepare a request
for the server and send it (json). You can write request code in any
language you wish.

Upon receiving a response (json), you should store the response into a
local relational database. We define N=2 in this case: 0-h2 database,
1-sqlite database. The result should always be a single table.

```
489 % 2 = 1 --> sqlite database
```

Every response should be cached (you already stored it in a local db),
so that any future input/request that uses the same input do not need
to be sent to the server. This can be written in any language. (Do not
forget that you might need to invalidate cache; feel free to be more
coarse-grained and invalidate everything if there is any modification
to the database in any query.)

### Visualizer

Visualize the response in Smalltalk (proper GUI with nodes and edges)
by communicating between your client and the visualizer via a json
file.

Another version of a visualizer (text-based) should be implemented in
OCaml; communication from your client to OCaml should be the same json
file as above. The result should be shown in a tabular
format. Additionally, OCaml should include stats about average values
for each int column (computed in OCaml not as part of a query).


### Server

Your server should be written in Go. The server will accept requests
and serve them. If the request has any error, appropriate message will
be sent to the client. If the request is valid, it will be sent to the
database, results will be accepted, packed, and sent to the user.

We leave to you to design communication protocol between the server
and database, e.g., log files, inter-process messages.

Client and server should communicate using REST. You have freedom to
define end points and arguments.

### Database

You should set up and use Neo4j as your actual database on the server.


## Testing

You should have tests for each part of your code; without tests, code
will be considered non-existent.


## Benchmarking

Graduate version only.

Write a bash script(s) that will collect benchmarking data for 100
queries. Each query should be run 100 times and averages should be
computed.


## Software

Your implementation should work under the following configuration:
* Linux (any recent distribution)
* N=2: 0 - Oracle Java 17 (https://www.oracle.com/java/technologies/downloads); 1 - Oracle Java 11
    * `489 % 2 = 1 --> Oracle Java 11`
* N=2: 0 - Neo4j v5.x (cloud Graph Database Self-Managed community edition https://neo4j.com/deployment-center); 1 - Neo4j v4.x
    * `489 % 2 = 1 --> Neo4j v4.x`
* Smalltalk Pharo 11 (https://pharo.org/download)
* Go 1.18+
* Python 3.8+
* gcc 9.4.0+
* h2 2.2.222+
* OCaml 4.08.1+
* If you pick a language not in the list, please contact us for the version number
* CMake 3.16+

If you create a Docker image with required software and demo
everything using it, you will receive extra points.


## Repository and Steps

Keep all your code in the same repo that you already shared with us
(in the `project` directory).

We will split the project in three parts.

*Part 1*

* ANTLR - build lexer and parser and test that it works as expected with random cypher queries
* Neo4j config - Configure graph database and run Cypher shell and use it to write some queries
* Client (part 1) that accepts a query, runs it through lexer and parser and prints it on the screen (or similar)

Due October 2.

Expected to deliver:

* A script (bash, Python, or something else that can run easily on Linux) that sets up Neo4j locally and demostrates successul run of the database.  The script should be end-to-end without any manual step required on the user end.
* Code that implements a client (as described earlier in this document) that gets input(s), checks queries, prints proper message.
* Code that is needed for checking if queries are valid. (You can commit/push code for checking even if files are auto generated.)

Do NOT include the following:

* Source code for Neo4j
* Neo4j in any form
* Any other library

Whatever you need, should be downloaded by the scripts you are
using/writing. Basically, do not include necessary binaries into your
repository.

*Part 2*

* Visualization in Smalltalk by reading a json file from a file system and visualizing
* Server (part 1) in Go that runs a few preselected queries to Neo4j (configured earlier)
* Client (part 2) language dependent send a request with the query
* Server (part 2) in Go that accepts the query and run with Neo4j

Due October 23.

*Part 3*

* Server (part 3) accept the response and send it to client as the response
* Client (part 3) accept the response from the server and save into json file
* Visualization in OCaml by reading from a json file
* Caching the response in a database for each response

Due November 13.
