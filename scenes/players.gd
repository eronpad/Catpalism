extends CharacterBody3D

#Primeiramente fazemos exports para mudar a sensibilidade do mouse fora do codigo
@export_group("Camera")
@export_range(0.0, 1.0) var mouse_sensibilidade := 0.25
var _gravity := 30.0
#Movimentacao do Personagem
@export_group("Movimentação")
@export var move_speed := 8.0
@export var aceleracao := 20.0
@export var forca_pulo := 5
@onready var camera: Camera3D = %Camera3D
#holding items
@export_category("Holding Items")
@export var arremesoForca = 7.5
@export var followSpeed = 4.0
@export var followDistance = 6
@export var dropBelowPlayer = false
@export var maxDinstanceFromCamera = 5.0
@onready var groundRay = $GroundRayCast
@onready var interactRay = $CameraPivot/Camera3D/RayCast3D
@export var holdObject: RigidBody3D = null

var debug_tick:int =0

#dps pegamos a variavel da camera pivot (uma "linha" invisivel que vai da cabeca do personagem ate a camera)
@onready var camera_pivot: Node3D = %CameraPivot

#logo apos fazemos um variavel para o input da direcao da camera em 2 dimensoes X e Y
var camera_input_direcao: = Vector2.ZERO

func _input(event: InputEvent) -> void:
	%interact_text.hide()
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#basicamente se a pessoa clicar com botao esquerdo na tela do jogo, ele ira capturar o mouse
	# da pessoa para ser a camera.
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# ja isso aq serve para caso a pessoa aperte ESC o mouse se torne visivel


#a funcao unhandled serve pra pegar os inputs do mouse
func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
		)
		
	if is_camera_motion:
		camera_input_direcao = event.screen_relative * mouse_sensibilidade
		
#essa funcao ja serve para como se fosse um update da unity (atualiza a cada tick(eu acho))
func _physics_process(delta: float) -> void:
	handle_holding_objects()
	camera_pivot.rotation.x += camera_input_direcao.y * delta
	
	#clampamos a rotacao para nao rotacionarmos a camera demasiadamente
	# -PI /6.0 = -3 graus e PI / 3.0 = 60 graus
	camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -PI /6.0, PI / 3.0)
	
	camera_pivot.rotation.y -= camera_input_direcao.x * delta
	
	#a cada update o mouse nao resetar e ir pro meio a gente diz que a posicao que ele esta eh o novo 0
	camera_input_direcao = Vector2.ZERO
	
	#movimentacao 
	var input_puro := Input.get_vector("move_esquerda", "move_direita", "move_frente", "move_back")
	var para_frente := camera.global_basis.z
	var para_direita := camera.global_basis.x
	
	var move_direcao := para_frente * input_puro.y + para_direita * input_puro.x
	#como a camera geralmente esta a cima do personagem, ele pode tentar entrar no chao, ent eh sempre bom zerar o Y 
	move_direcao.y = 0.0
	move_direcao = move_direcao.normalized()
	
	
	var velocity_y := velocity.y
	
	velocity = velocity.move_toward(move_direcao * move_speed, aceleracao * delta)
	velocity.y = velocity_y - _gravity * delta
	velocity_y = 0.0
	
	var pulando := Input.is_action_just_pressed("pular") and is_on_floor()
	if pulando:
		velocity.y += forca_pulo
	

	move_and_slide()

func set_hold_items(body: RigidBody3D):
	if body is RigidBody3D:
		holdObject = body

func drop_hold_objects():
	holdObject = null

func jogar_item():
	var obj = holdObject
	print("objeto hold sendo jogado")
	drop_hold_objects()
	obj.apply_central_impulse(-camera.global_transform.basis.z * forca_pulo * 10)

func handle_holding_objects():
	if Input.is_action_just_pressed("drop"):
		if holdObject != null: jogar_item()
	
	
	if Input.is_action_just_pressed("interagir"):
		if holdObject!=null: 
			jogar_item()
		elif interactRay.is_colliding(): 
			set_hold_items(interactRay.get_collider())
			print(interactRay.get_collider())
			print("interagiu")
		
		
	if holdObject != null: 
		#var targetPos = camera.global_transform.origin + (camera.global_position + Vector3(0,0, followDistance))
		var x_target = %Player.global_position.x-2*camera.global_position.x
		var y_target = %Player.global_position.y-2*camera.global_position.y + 3
		
		var targetPos = camera.global_transform.origin + (Vector3(x_target,y_target,camera.global_position.z)+ Vector3(0,0, followDistance))
		#var targetPos = camera.global_transform.origin + (Vector3(x_target,camera.global_position.y,camera.global_position.z)+ Vector3(0,0, followDistance))
		
		debug_tick+=1
		var itemPos = holdObject.global_transform.origin 
		
		#var vel =  (itemPos - targetPos) * followSpeed
		var vel =  (targetPos - itemPos) * followSpeed
		
		print("loop",debug_tick," camera.global_transform.origin",camera.global_transform.origin)
		vel = vel.limit_length(8.0)
		holdObject.linear_velocity = holdObject.linear_velocity.lerp(vel, 0.05)
		
		
		#if holdObject.global_position.distance_to(camera.global_position) > maxDinstanceFromCamera:
			#drop_hold_objects()
		
	
		if dropBelowPlayer && groundRay.is_colliding():
			if groundRay.get_collider() == holdObject: drop_hold_objects()
