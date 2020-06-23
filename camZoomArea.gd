extends Area2D

export (global.ZOOM) var enterLeftZoom = global.ZOOM.NORM
export (float) var enterLeftZoomTime = 2
export (float) var customLeftZoom = 0
export (global.ZOOM) var enterRightZoom = global.ZOOM.NORM
export (float) var enterRightZoomTime = 2
export (float) var customRightZoom = 0
export (NodePath) var CAM_NODE_PATH
onready var CAM_NODE = get_node(CAM_NODE_PATH)

func _on_camZoomArea_body_entered(body):
	var customZoom = null
	if body.is_in_group("astro"):
		if body.get_global_position().x > get_global_position().x:
				customZoom = customRightZoom if customRightZoom > 0 else null
				CAM_NODE.setZoom(enterRightZoom, enterRightZoomTime, customZoom)
		else:
			customZoom = customLeftZoom if customLeftZoom > 0 else null
			CAM_NODE.setZoom(enterLeftZoom, enterLeftZoomTime, customZoom)


func _on_camZoomArea_body_exited(body):
	return
#	if body.is_in_group("astro"):
#
#		if body.get_global_position().x > get_global_position().x:
#			CAM_NODE.setZoom(exitRightZoom, exitRightZoomTime)
#		else:
#			CAM_NODE.setZoom(exitLeftZoom, exitLeftZoomTime)
