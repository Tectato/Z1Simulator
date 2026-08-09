extends Peripheral

func serialize():
	var out = super.serialize()
	out["type"] = 6
	return out

func getBounds():
	return [Vector3(-1,0,-1)*0.8, Vector3(1,0.04,1)*0.4]
