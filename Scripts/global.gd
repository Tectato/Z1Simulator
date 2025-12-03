extends Node

var workspace : Workspace
var editor : Editor

var lookSensitivity = 0.3
var moveSensitivity = 0.2
var historyLength = 24
signal clearHistory

var unnamedIDs = {}
