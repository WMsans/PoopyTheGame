extends CharacterBody2D



### ### Maddie's Ultra-Simple Sonic Physics!! ### ###
## Don't want comments? Alright, I'll remove all the useless ones.
## The bookmarks are staying, though.




var motion := Vector2(0, 0)
var rot := 0.0

var grounded := false

var slopeangle := 0.0
var slopefactor := 0.0

var falloffwall = false
var control_lock = false
var stuck = false

var jumping = false
var canjump = false
var jumpbuffered = false

const JUMP_VELOCITY = 350.0
var GRAVITY = 600

const acc := 2
const dec := 30.0
const topspeed := 300.0



func _physics_process(delta):

# Set the Slope variables
	if is_on_floor():
		slopeangle = get_floor_normal().angle() + (PI/2)
		slopefactor = get_floor_normal().x
	else:
		slopefactor = 0


# Rotation & Momentum Conversion
	$Collision.rotation = rot
	$Sprite.rotation = lerp_angle($Sprite.rotation, rot, 0.25)

	if is_on_floor():
		if not grounded:
			if abs(slopeangle) >= 0.25 and abs(motion.y) > abs(motion.x):
				motion.x += motion.y * slopefactor
			grounded = true
		
		up_direction = get_floor_normal()
		rot = slopeangle
	else:
		if not $Collision/Raycast.is_colliding() and grounded:
			grounded = false
			
			motion = get_real_velocity()
			rot = 0
			up_direction = Vector2(0, -1)


# Gravity
	if not is_on_floor() and rot == 0:
		motion.y += GRAVITY * delta
	else:
		if abs(slopefactor) == 1:
			motion.y = 0
		else:
			motion.y = 50


# Jump
	if Input.is_action_just_pressed("jump"):
		jumpbuffered = true
		$JumpBufferTimer.start()

	if not grounded and canjump:
		if $CoyoteTimer.is_stopped():
			$CoyoteTimer.start()
	else:
		$CoyoteTimer.stop()


	if jumpbuffered and canjump:
		motion.y = -JUMP_VELOCITY
		jumping = true
		canjump = false
		
		if abs(rot) > 1:
			position += Vector2(0, -(14)).rotated(rot)
		
		$JumpBufferTimer.stop()
		jumpbuffered = false


	if motion.y >= 0 and grounded:
		jumping = false
		canjump = true


	if jumping and motion.y < -JUMP_VELOCITY / 1.625:
		if not Input.is_action_pressed("jump"):
			motion.y = -JUMP_VELOCITY / 1.625




# (Debug) Speed Boost
	#if Input.is_action_just_pressed("action"):
	#	motion.x += topspeed * sign($Sprite.scale.x)



# Movement
	var direction = Input.get_axis("left", "right")
	
	if direction and not control_lock:
		if is_on_floor():
			if direction == sign(motion.x):
				if abs(motion.x) <= topspeed:
					motion.x += acc * direction
			else:
				if abs(slopefactor) < 0.4:
					motion.x += dec * direction
				else:
					motion.x += acc * direction
				
		else:
			if direction == sign(motion.x):
				if abs(motion.x) <= topspeed:
					motion.x += (acc * 2) * direction
			else:
				motion.x += (acc * 2) * direction
			
	else:
		if is_on_floor() and abs(slopefactor) < 0.25:
			motion.x = move_toward(motion.x, 0, acc)



# Set Velocity to the Motion variable, but rotated.
	velocity = Vector2(motion.x, motion.y).rotated(rot)



# Slopes
	if is_on_floor() and not stuck and not $Collision/WallCast.is_colliding():
		motion.x += (acc * 2) * slopefactor
	
	if grounded and abs(slopefactor) >= 0.5 and abs(motion.x) < 10:
		control_lock = true
		$ControlLockTimer.start()
	
	if grounded and abs(slopeangle) > 1.5:
		if abs(motion.x) < 80:
			falloffwall = true
			position += Vector2(0, -(14)).rotated(rot)
			canjump = false
			
			control_lock = true
			$ControlLockTimer.start()
	else:
		falloffwall = false



# Stoppers
	if is_on_ceiling() and not grounded:
		if motion.y < 0:
			motion.y = 100

	if is_on_wall() and $Collision/WallCast.is_colliding():
		motion.x = 0



	animate()
	#slope_failsafe()
	move_and_slide()



# Animation

var idle := true
var idleset := false

func animate():
	if abs(motion.x) > 1:
		$Sprite.scale.x = sign(motion.x)
		$Collision.scale.x = sign(motion.x)
	
	
	if grounded:
		if abs(motion.x) < 1:
			$Sprite.speed_scale = 1
		elif abs(motion.x) < topspeed - 10:
			$Sprite.play("walk")
			$Sprite.speed_scale = 0.5 + (abs(motion.x) / 350)
		else:
			$Sprite.play("run")
			$Sprite.speed_scale = 1 + (abs(motion.x) / (topspeed * 2))
	elif jumping:
		$Sprite.play("jump")
		$Sprite.speed_scale = 1 + (abs(motion.x) / (topspeed * 2))


	# Idle animation
	
	if grounded and abs(motion.x) < 1:
		idle = true
	else:
		idle = false
	
	if idle:
		if idleset:
			$Sprite.play("idle")
			idleset = false
		
		if $IdleTimer.is_stopped():
			$IdleTimer.start()
	else:
		idleset = true
		$IdleTimer.stop()


func _on_idle_timer_timeout():
	if abs(motion.x) < 1:
		$Sprite.play("idleanim")




# Timer signals

func _on_control_lock_timer_timeout():
	control_lock = false

func _on_jump_buffer_timer_timeout():
	jumpbuffered = false

func _on_coyote_timer_timeout():
	canjump = false





func slope_failsafe():
	if is_on_floor() and ($Collision/WallCast.is_colliding() and abs(rot) > 0.4):
		if abs(motion.x) > 100 and sign(rot) == sign(motion.x):
			stuck = true
			motion.x = -sign(slopefactor) * motion.x
	else:
		stuck = false



## Squeaky clean.
