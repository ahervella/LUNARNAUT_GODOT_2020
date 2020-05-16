extends Resource

class_name CharacterRes

export (global.CHAR) var id
export (String) var name
export (String) var nationality
export (String) var description
export (Texture) var texture
#need to implement this
export (Texture) var spriteSheet
export (float) var baseGroundSpeed
export (float) var baseGroundAcceleration
export (float) var baseAirSpeed
export (float) var baseAirAcceleration
export (float) var baseJump
export (int) var baseOxygenCapacity

export (int) var health setget setHealth
export (bool) var o2ThrustUnlocked
export (float) var gravMag setget setGravMag
export (float) var gravDegAngleFromNorm setget setGravAng

export (String) var level

func setHealth(val):
	val = clamp(val, 0, 8)
	health = val

func setGravMag(val):
	val = clamp(val, 0, 3)
	gravMag = val
	
func setGravAng(val):
	val = clamp(val, -360, 360)
	gravDegAngleFromNorm = val
