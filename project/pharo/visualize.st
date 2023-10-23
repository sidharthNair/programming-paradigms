| graph |

(Smalltalk hasClassNamed: #NeoJSONReader) ifFalse: [
	Metacello new
		baseline: 'NeoJSON';
		repository: 'github://svenvc/NeoJSON';
		load.
].

graph := GraphVis new.
graph loadJSON: '../antlr/response.json'.
