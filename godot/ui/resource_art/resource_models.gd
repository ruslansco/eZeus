extends RefCounted
# Original procedural presentation art. No native assets, simulation RNG, physics or live HUD viewports.
var root: Node3D
var materials := {}
func material(colour: String, metal:=0.0) -> StandardMaterial3D:
	var key:=colour+str(metal)
	if not materials.has(key):
		var m:=StandardMaterial3D.new();m.albedo_color=Color(colour);m.roughness=.4;m.metallic=metal;materials[key]=m
	return materials[key]
func part(mesh: Mesh, pos: Vector3, scale: Vector3, colour: String, metal:=0.0) -> MeshInstance3D:
	var node:=MeshInstance3D.new();node.mesh=mesh;node.position=pos;node.scale=scale;node.material_override=material(colour,metal)
	root.add_child(node);node.owner=root
	return node
func ball(pos: Vector3, scale: Vector3, colour: String, metal:=0.0) -> MeshInstance3D:
	var m:=SphereMesh.new();m.radius=.5;m.height=1;m.radial_segments=16;m.rings=8
	return part(m,pos,scale,colour,metal)
func box(pos: Vector3, scale: Vector3, colour: String, metal:=0.0) -> MeshInstance3D:
	return part(BoxMesh.new(),pos,scale,colour,metal)
func rod(a: Vector3,b: Vector3,radius: float,colour: String, metal:=0.0) -> MeshInstance3D:
	var m:=CylinderMesh.new();m.top_radius=radius;m.bottom_radius=radius;m.height=a.distance_to(b);m.radial_segments=12
	var node:=part(m,(a+b)*.5,Vector3.ONE,colour,metal)
	var direction: Vector3=(b-a).normalized()
	if absf(direction.dot(Vector3.UP))<.999:node.quaternion=Quaternion(Vector3.UP,direction)
	return node
func cone(pos: Vector3, height: float, radius: float, colour: String) -> MeshInstance3D:
	var m:=CylinderMesh.new();m.top_radius=0;m.bottom_radius=radius;m.height=height;m.radial_segments=12
	return part(m,pos,Vector3.ONE,colour)
func ring(pos: Vector3, radius: float, thickness: float, colour: String) -> MeshInstance3D:
	var m:=TorusMesh.new();m.inner_radius=radius-thickness;m.outer_radius=radius+thickness;m.rings=16;m.ring_segments=8
	return part(m,pos,Vector3.ONE,colour)
func leaf(pos: Vector3, colour: String) -> void:
	var node:=ball(pos,Vector3(.16,.05,.4),colour);node.rotation_degrees=Vector3(0,35,25)
func amphora(colour: String, detail: String) -> void:
	ball(Vector3(0,.45,0),Vector3(.7,1,.7),colour)
	rod(Vector3(0,.8,0),Vector3(0,1.12,0),.16,colour)
	ring(Vector3(0,1.12,0),.17,.045,detail)
	for side in [-1,1]:
		var handle:=ring(Vector3(side*.35,.78,0),.2,.04,colour);handle.rotation_degrees.x=90
	rod(Vector3(0,.55,0),Vector3(0,.66,0),.36,detail)
func ingots(colour: String, metal: float) -> void:
	for index in 3:
		var node:=box(Vector3((index%2)*.52-.26,(index/2)*.28+.15,0),Vector3(.48,.25,.8),colour,metal);node.rotation_degrees.y=12
func make(kind: String) -> Node3D:
	root=Node3D.new();root.name=kind.to_pascal_case()
	match kind:
		"food_total":
			box(Vector3(0,.2,0),Vector3(.8,.35,.6),"c39758")
			for x in [-.34,0,.34]:box(Vector3(x,.22,.31),Vector3(.055,.36,.025),"ecd09a")
			for x in [-.22,.22]:ball(Vector3(x,.5,0),Vector3(.33,.33,.33),"e6a14c")
			leaf(Vector3(.16,.7,0),"70a269")
		"urchin":
			ball(Vector3(0,.4,0),Vector3(.6,.6,.6),"59385e")
			for index in 20:
				var d:=Vector3(sin(index*2.4),float(index)/10-1,cos(index*2.4)).normalized()
				rod(Vector3(0,.4,0)+d*.18,Vector3(0,.4,0)+d*.58,.026,"a385ad")
		"fish":
			ball(Vector3(0,.35,0),Vector3(1.2,.5,.35),"86c4ca",.3)
			var tail:=cone(Vector3(-.65,.35,0),.5,.27,"427e96");tail.rotation_degrees.z=-90;tail.scale.z=.22
			ball(Vector3(.43,.43,.155),Vector3(.1,.1,.06),"102b37")
			cone(Vector3(0,.6,0),.22,.18,"427e96").scale.z=.2
		"meat":
			rod(Vector3(-.6,.25,0),Vector3(.55,.25,0),.085,"e6d6b4")
			ball(Vector3(.08,.3,0),Vector3(.85,.55,.5),"b74f46")
			for z in [-.075,.075]:ball(Vector3(-.6,.25,z),Vector3(.21,.23,.17),"fff0d3")
		"cheese":
			rod(Vector3(0,.1,0),Vector3(0,.4,0),.5,"edc45e")
			for p in [Vector3(-.15,.405,.14),Vector3(.2,.405,.1),Vector3(.06,.405,-.24)]:ball(p,Vector3(.12,.012,.12),"b48839")
		"carrots":
			for i in 3:
				var x: float=(i-1)*.3;var carrot:=cone(Vector3(x,.35,0),.7,.15,"ed8039");carrot.rotation_degrees.z=180
				for z in [-.08,.08]:rod(Vector3(x,.68,0),Vector3(x+.1,.95,z),.03,"689e4b")
		"onions":
			for x in [-.24,.24]:
				ball(Vector3(x,.25,0),Vector3(.52,.5,.5),"d8ad6a");cone(Vector3(x,.54,0),.2,.12,"ead199")
				rod(Vector3(x,.55,0),Vector3(x+.12,.86,0),.03,"6b8e44")
		"grain":
			for x in [-.3,0,.3]:
				rod(Vector3(x,0,0),Vector3(x,1.1,0),.025,"b38d42")
				for i in 4:
					for side in [-1,1]:
						var seed:=ball(Vector3(x+side*.08,.6+i*.12,0),Vector3(.12,.22,.1),"f0cf78");seed.rotation_degrees.z=side*-30
		"oranges":
			for p in [Vector3(-.23,.2,.1),Vector3(.23,.2,.1),Vector3(0,.48,-.12)]:ball(p,Vector3(.48,.48,.48),"ec993e")
			leaf(Vector3(.12,.75,-.12),"4e8850")
		"grapes":
			for row in 4:
				for col in 4-row:ball(Vector3((col-(3-row)*.5)*.23,.9-row*.22,0),Vector3(.27,.27,.3),"9465aa")
			rod(Vector3(0,.94,0),Vector3(.12,1.14,0),.03,"918452");leaf(Vector3(.22,1.04,0),"79a45b")
		"olives":
			for i in 4:ball(Vector3((i%2)*.32-.16,(i/2)*.24+.2,0),Vector3(.27,.35,.3),"8caa4d")
			leaf(Vector3(.1,.64,0),"aac090")
		"wine":amphora("a65d79","edb18b")
		"oil":amphora("bcaa51","ece3a6")
		"fleece":
			for p in [Vector3(-.25,.23,0),Vector3(.25,.23,0),Vector3(0,.45,0),Vector3(0,.23,.25)]:ball(p,Vector3(.6,.52,.6),"f2e6cb")
		"wood":
			for p in [Vector3(-.24,.18,0),Vector3(.24,.18,0),Vector3(0,.52,0)]:
				rod(p+Vector3(0,0,-.48),p+Vector3(0,0,.48),.2,"8c6240")
				rod(p+Vector3(0,0,.48),p+Vector3(0,0,.5),.17,"dab183")
		"bronze":ingots("c9945d",.55)
		"orichalcum":ingots("71c2bd",.6)
		"silver":ingots("d2e0e6",.65)
		"marble","black_marble":
			var colour: String="e9e4cf" if kind=="marble" else "3b5163"
			box(Vector3(0,.35,0),Vector3(.9,.65,.75),colour)
			for i in 3:rod(Vector3(-.43,.22+i*.15,.382),Vector3(.43,.31+i*.15,.382),.009,"abbaa9" if kind=="marble" else "abb3bb")
		"arms":
			ball(Vector3(0,.55,0),Vector3(.75,.75,.5),"cfad6a",.5)
			box(Vector3(0,.32,.27),Vector3(.48,.4,.08),"304b60")
			rod(Vector3(0,.77,0),Vector3(0,1.13,0),.14,"b45749")
			for side in [-1,1]:box(Vector3(side*.28,.22,0),Vector3(.18,.3,.5),"cfad6a",.5)
		"sculptures":
			box(Vector3(0,.06,0),Vector3(.66,.12,.5),"d5c7a9")
			ball(Vector3(0,.3,0),Vector3(.68,.5,.4),"eae5d3")
			rod(Vector3(0,.3,0),Vector3(0,.64,0),.13,"eae5d3")
			ball(Vector3(0,.82,0),Vector3(.4,.48,.4),"f3eddb");ball(Vector3(0,.81,.2),Vector3(.09,.14,.1),"e4d7bd")
		"horses":
			ball(Vector3(0,.5,0),Vector3(.95,.45,.36),"b68963")
			for x in [-.32,.32]:
				for z in [-.14,.14]:rod(Vector3(x,.42,z),Vector3(x-.05,0,z),.045,"78553e")
			rod(Vector3(.32,.5,0),Vector3(.42,.96,0),.13,"b68963");ball(Vector3(.58,1,0),Vector3(.4,.23,.22),"b68963")
			for z in [-.07,.07]:cone(Vector3(.4,1.17,z),.2,.045,"78553e")
			rod(Vector3(-.44,.58,0),Vector3(-.66,.28,0),.045,"503d37")
		"chariots":
			box(Vector3(0,.35,0),Vector3(.7,.17,.65),"c69d64");box(Vector3(-.28,.62,0),Vector3(.1,.44,.7),"d5b170")
			for z in [-.42,.42]:
				var wheel:=ring(Vector3(0,.29,z),.29,.05,"e1c590");wheel.rotation_degrees.x=90
				for angle in [0,PI/3,2*PI/3]:rod(Vector3(-sin(angle)*.26,.29-cos(angle)*.26,z),Vector3(sin(angle)*.26,.29+cos(angle)*.26,z),.025,"d5b170")
			for z in [-.24,.24]:rod(Vector3(.1,.36,z),Vector3(.95,.3,z),.04,"ba8c54")
	return root
