extends Movable
class_name Pin

var global = false

var affectedBy = []
var priorState = 0 # 1 bit per hole/sheet. Check if state before and after match, if not, move in direction of differing bit's hole/sheet
