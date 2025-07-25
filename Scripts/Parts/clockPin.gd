extends Pin

var step : Simulator.Step
var pulsing = false # If false, move forward in step X and back in step X+2. If true, move forward and back in X and don't move in X+2
var direction : int
