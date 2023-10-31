Class {
	#name : #GraphVis,
	#superclass : #Object,
	#instVars : [
		'nodes',
		'window',
		'canvas',
		'padding',
		'refresh',
		'file'
	],
	#category : #MyGraph
}

{ #category : #adding }
GraphVis >> addEdgeFrom: startId to: endId [
	| startNode endNode |
	(nodes includesKey: startId)
		ifFalse: [
			| newNode |
			newNode := Node new.
			newNode setId: startId.
			newNode setDescription: 'Id: ', startId asString.
			self addNode: newNode.
		].
	startNode := nodes at: startId.
	(nodes includesKey: endId)
		ifFalse: [
			| newNode |
			newNode := Node new.
			newNode setId: endId.
			newNode setDescription: 'Id: ', endId asString.
			self addNode: newNode.
		].
	endNode := nodes at: endId.
	startNode getEdges do: [ :e |
		e getEndNode = endNode 
			ifTrue: [^nil].
	].
	startNode addEdge: endNode.
]

{ #category : #adding }
GraphVis >> addEdgeFrom: startId to: endId description: d [
	| startNode endNode edge desc |
	(nodes includesKey: startId)
		ifFalse: [
			| newNode |
			newNode := Node new.
			newNode setId: startId.
			newNode setDescription: 'Id: ', startId asString.
			self addNode: newNode.
		].
	startNode := nodes at: startId.
	(nodes includesKey: endId)
		ifFalse: [
			| newNode |
			newNode := Node new.
			newNode setId: endId.
			newNode setDescription: 'Id: ', endId asString.
			self addNode: newNode.
		].
	endNode := nodes at: endId.
	startNode getEdges do: [ :e |
		e getEndNode = endNode 
			ifTrue: [^nil].
	].
	edge := (startNode addEdge: endNode).
	desc := WriteStream on: ''.
	desc nextPutAll: d.
	endNode getEdges do: [ :e | 
		e getEndNode = startNode
			ifTrue: [ 
				desc nextPutAll: String lf asString; nextPutAll: e getDescription.
				e setDescription: desc contents.
			]. 
	].
	edge setDescription: desc contents.
]

{ #category : #adding }
GraphVis >> addNode: node [
	nodes at: node getId put: node.
]

{ #category : #display }
GraphVis >> drawGraph [
	| topLeft nodePositions current x y limitx limity spacing i |
	canvas removeAllMorphs.
	current := 0.
	topLeft := canvas position.
	limitx := canvas extent x - (2 * padding).
	limity := canvas extent y - (2 * padding).
	spacing := (limitx * limity) / (nodes size).
	nodePositions := Dictionary new.
	i := 0.
	nodes keysAndValuesDo: [:key :value |
		| point modified |
		modified := current + (limitx * ((i raisedTo: 2) / (nodes size raisedTo: 2))).
		x := modified % limitx.
		y := modified / limitx.
		i % 2 == 1
			ifTrue: [ x := limitx - x. y:= limity - y. ].
		point := Point x: x + topLeft x + padding y: y + topLeft y + padding.
		nodePositions at: key put: point.
		value position: point.
		current := current + spacing.
		canvas addMorph: value.
		i := i + 1
	].
	nodes keysAndValuesDo: [:key :value |
		| edges startPoint |
		startPoint := nodePositions at: key.
		edges := value getEdges.
		edges do: [ :edge |
			| endPoint |
			endPoint := nodePositions at: (edge getEndNode getId).
			edge setVertices: {startPoint + (value extent x / 2) . endPoint + (value extent x / 2)}.
			canvas addMorphBack: edge.
		].
	].
	
]

{ #category : #initialization }
GraphVis >> initialize [ 
	nodes := Dictionary new.
	window := StandardWindow new.
	canvas := (ColorForm extent: 600@600) asMorph.
	canvas position: 0@30.
	window title: 'Graph Visualizer'.
	window extent: 600@630.
	window addMorphBack: canvas.
	refresh := PluggableButtonMorph new.
	refresh label: 'Refresh'.
	refresh extent: 90@30.
	refresh on: #mouseUp send: #reload to: self.
	padding := 50.
	window addMorph: refresh.
   window openInWorld.
]

{ #category : #'as yet unclassified' }
GraphVis >> loadJSON: filePath [
	| jsonText jsonData records edges |
	file := filePath.
	nodes := Dictionary new.
	jsonText := filePath asFileReference.
	jsonData := NeoJSONReader fromString: jsonText.
	records := (jsonData at: 'Records') asArray.
	edges := Set new.
	
	records do: [ :record |
		| keys values |
		keys := (record at: 'Keys') asArray.
		values := (record at: 'Values') asArray.
		
		keys withIndexDo: [ :key :index |
			| value id props description |
			value := values at: index.
			value ifNotNil: [ 
				id := (value at: 'Id') asInteger.
				props := (value at: 'Props') asString.
				description := WriteStream on: ''.
				(value includesKey: 'Type') ifTrue: [ 
					| edge type startId endId |
					type := (value at: 'Type') asString.
					startId := (value at: 'StartId') asInteger.
					endId := (value at: 'EndId') asInteger.
					edge := Edge new.
					description
						nextPutAll: 'Key: '; nextPutAll: key; nextPutAll: ', ';
    					nextPutAll: 'Id: '; nextPutAll: id asString; nextPutAll: ', ';
    					nextPutAll: 'Type: '; nextPutAll: type; nextPutAll: ', ';
    					nextPutAll: 'Props: '; nextPutAll: props; nextPutAll: ', ';
						nextPutAll: 'From: '; nextPutAll: startId asString; nextPutAll: ', ';
						nextPutAll: 'To: '; nextPutAll: endId asString.
					edge setDescription: description contents.
					edge startNode: startId.
					edge endNode: endId.
					edges add: edge.
				] ifFalse: [  
					| node labels |
					labels := (value at: 'Labels') asString.
					node := Node new.
					node setId: id.
					description
						nextPutAll: 'Key: '; nextPutAll: key; nextPutAll: ', ';
    					nextPutAll: 'Id: '; nextPutAll: id asString; nextPutAll: ', ';
    					nextPutAll: 'Labels: '; nextPutAll: labels; nextPutAll: ', ';
    					nextPutAll: 'Props: '; nextPutAll: props.
					node setDescription: description contents. 
					self addNode: node.
				].
			].
		].
	].
	edges do: [ :edge |
		self addEdgeFrom: edge getStartNode to: edge getEndNode description: edge getDescription.
	].

	self drawGraph.	
	
]

{ #category : #actions }
GraphVis >> reload [
	self loadJSON: file.
]
