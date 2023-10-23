Class {
	#name : #Graph,
	#superclass : #Object,
	#instVars : [
		'nodes',
		'canvas',
		'padding'
	],
	#category : #MyGraph
}

{ #category : #adding }
Graph >> addEdgeFrom: startId to: endId [
	| startNode endNode |
	startNode := nodes at: startId.
	endNode := nodes at: endId.
	startNode addEdge: endNode.
]

{ #category : #adding }
Graph >> addNode: node [
	nodes at: node getId put: node.
]

{ #category : #display }
Graph >> drawGraph [
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
			edge vertices: {startPoint + (value extent x / 2) . endPoint + (value extent x / 2)} color: Color black borderWidth: 2 borderColor: Color black.
			canvas addMorph: edge.
		].
	].
	
]

{ #category : #initialization }
Graph >> initialize [ 
	nodes := Dictionary new.
	canvas := (ColorForm extent: 600@600) asMorph.
	padding := 50.
   canvas openInWorld.
]
