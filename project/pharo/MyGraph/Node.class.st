Class {
	#name : #Node,
	#superclass : #EllipseMorph,
	#instVars : [
		'edges',
		'id',
		'description'
	],
	#category : #MyGraph
}

{ #category : #adding }
Node >> addEdge: node [
	| edge |
	edge := Edge newFrom: self to: node.
	edges add: edge.
	^edge.
	
]

{ #category : #accessing }
Node >> getDescription [
	^description
]

{ #category : #accessing }
Node >> getEdges [
	^edges.
]

{ #category : #accessing }
Node >> getId [
	^id.
]

{ #category : #accessing }
Node >> highlight [ 
	self color: Color yellow.
]

{ #category : #initialization }
Node >> initialize [ 
	super initialize.
	edges := Set new.
	self bounds: (0@0 corner: 30@30).
	self color: Color blue.
	self on: #mouseEnter send: #highlight to: self.
	self on: #mouseLeave send: #unhighlight to: self.
	self on: #mouseUp send: #showDescription to: self.
]

{ #category : #initialization }
Node >> setDescription: d [
	description := d
]

{ #category : #initialization }
Node >> setId: i [
	id := i.
]

{ #category : #'as yet unclassified' }
Node >> showDescription [
	| ui |
   ui := UIManager default.
   ui inform: description.
]

{ #category : #drawing }
Node >> unhighlight [ 
	self color: Color blue.
]
