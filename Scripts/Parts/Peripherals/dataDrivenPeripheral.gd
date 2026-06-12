extends Peripheral

# JSON Format
# peripheral:
#	L_ type: (int) generic / input exponent slider / output exponent slider / program reader
#	L_ inputs: (list)
#	|   L_ {
#	|   	L_ uuid: int
#	|		L_ pos_x: float
#	|		L_ pos_y: float
#	|		L_ state: int (0/1)
#	|   	}
#	L_ outputs: (list)
#	|   L_ {
#	|   	L_ uuid: int
#	|		L_ pos_x: float
#	|		L_ pos_y: float
#	|		L_ state: int (0/1)
#	|		L_ behavior:
#	|			L_ {
#	|				TODO
#	|				}
#	|   	}
#	L_ values:
#	|	L_ {
#	|		L_ pins: list of uuids
#	|		L_ display: boolean
#	|		L_ d_x: float, optional
#	|		L_ d_y: float, optional
#	|		L_ d_z: float, optional
#	|		}
