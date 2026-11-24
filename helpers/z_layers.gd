class_name ZLayers
extends RefCounted
## Every draw-order number in the game lives here. Higher = drawn on top.
## Machines additionally Y-sort among themselves (see GridManager.buildingsNode).

const BELT := 0
const ITEM := 10 # relative to its belt, which is at BELT
const MACHINE := 20
const LINK_LINE := 25
const CELL_OUTLINE := 30
const PREVIEW := 40
