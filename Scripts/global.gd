extends Node

var workspace : Workspace
var editor : Editor
@onready var config = $Config

var lookSensitivity = 0.3
var moveSensitivity = 0.1
var historyLength = 24
signal clearHistory

var unnamedIDs = {}
