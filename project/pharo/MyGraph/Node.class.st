Class {
	#name : #Node,
	#superclass : #EllipseMorph,
	#instVars : [
		'edges',
		'id',
		'labels',
		'props'
	],
	#category : #MyGraph
}

{ #category : #adding }
Node >> addEdge: node [
	edges add: (Edge newFrom: self to: node).
	
]

{ #category : #accessing }
Node >> getEdges [
	^edges.
]

{ #category : #accessing }
Node >> getId [
	^id.
]

{ #category : #initialization }
Node >> initialize [ 
	super initialize.
	edges := Set new.
	self bounds: (0@0 corner: 20@20).
	self color: Color blue.
]

{ #category : #initialization }
Node >> setId: i [
	id := i.
]
