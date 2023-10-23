Class {
	#name : #Edge,
	#superclass : #LineMorph,
	#instVars : [
		'startNode',
		'endNode',
		'props'
	],
	#category : #MyGraph
}

{ #category : #'instance creation' }
Edge class >> newFrom: startNode to: endNode [
	| edge |
	edge := self new.
	edge startNode: startNode.
	edge endNode: endNode.
	^edge.
]

{ #category : #accessing }
Edge >> endNode: node [
	endNode := node.
]

{ #category : #accessing }
Edge >> getEndNode [
	^endNode.
]

{ #category : #accessing }
Edge >> getStartNode [
	^startNode.
]

{ #category : #initialization }
Edge >> initialize [ 
	super initialize.
	self color: Color black.
]

{ #category : #accessing }
Edge >> startNode: node [
	startNode := node.
]
