Class {
	#name : #Edge,
	#superclass : #LineMorph,
	#instVars : [
		'startNode',
		'endNode',
		'description',
		'dialog'
	],
	#category : #MyGraph
}

{ #category : #'instance creation' }
Edge class >> newFrom: startNode to: endNode [
	| edge |
	edge := self new.
	edge initialize.
	edge startNode: startNode.
	edge endNode: endNode.
	^edge.
]

{ #category : #accessing }
Edge >> endNode: node [
	endNode := node.
]

{ #category : #accessing }
Edge >> getDescription [
	^description
]

{ #category : #accessing }
Edge >> getEndNode [
	^endNode.
]

{ #category : #accessing }
Edge >> getStartNode [
	^startNode.
]

{ #category : #accessing }
Edge >> highlight [
	self borderColor: Color red.
	
]

{ #category : #initialization }
Edge >> initialize [ 
	super initialize.
	self color: Color black.
	self borderColor: Color black.
	self borderWidth: 4.
	self on: #mouseEnter send: #highlight to: self.
	self on: #mouseLeave send: #unhighlight to: self.
	self on: #mouseUp send: #showDescription to: self.

]

{ #category : #initialization }
Edge >> setDescription: d [
	description := d
]

{ #category : #'as yet unclassified' }
Edge >> showDescription [
	| ui |
   ui := UIManager default.
   ui inform: description.
]

{ #category : #accessing }
Edge >> startNode: node [
	startNode := node.
]

{ #category : #drawing }
Edge >> unhighlight [ 
	self borderColor: Color black.
]
