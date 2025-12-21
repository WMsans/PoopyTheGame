extends CharacterBody2D



### ### Maddie's Ultra-Simple Sonic Physics!! ### ###
## The absolute bare minimum needed to make a Sonic fangame.

## Right now, it's just the 360 degree movement and slope physics, nothing else.

## I've written tons of helpful comments in the hopes that you'll understand how this code works.
## Then, if you do, I encourage you to try and add stuff like a spindash or a boost, if you want.


## I've also set bookmarks for each segment of the script.

## To access the bookmarks, look above that text field at the top left that says "Filter Scripts"-
## -and click "Go To". Then, click "Bookmarks". Now you'll hopefully be able to-
## -easily navigate this script.


## If you end up using this for a game, credit is absolutely not required, but would be appreciated.


## If the comments get annoying, find the script labelled "player (no comments)"-
## -and swap this script out with that one.




## Variables go at the top. Let's start with the most important ones.

var motion := Vector2(0, 0)
# Motion, the magical variable. Consider it a pseudo-Velocity.
## Motion and Velocity are used in conjunction with each other to simulate the 360 degree movement-
## -found in Classic Sonic games, only with much more theoretical effectiveness.
## Check underneath the "Movement" segment of the script for a full explanation.

var rot := 0.0
# Rotation.
## This helps your Sprite and Collision rotate.

var grounded := false
# The state that tracks if you've left the floor.
## Walking on a wall or a ceiling also counts as being grounded.

var slopeangle := 0.0
# The exact angle (in Radians) of the floor you're standing on.
## This number will be positive if the slope rises to the left, and negative if it rises to the right.
# Why Radians?
# Because Degrees calculations are finicky in this engine. Radians are far more accurate.

var slopefactor := 0.0
# The steepness of the slope you're standing on.
## Straight floors and cielings will emit "0". Perfectly vertical walls will emit "1".
## This number will be positive if the slope rises to the left, and negative if it rises to the right.




## Fixes for problems involving walls and steep slopes.

var falloffwall = false
# This makes sure you can't permanently stick to the wall.
## See the "Slope" section of the script for more info.

var control_lock = false
# This briefly removes your ability to move if you're trying to walk up a slope that's far too steep.
## See the "Slope" section of the script for more info.

var stuck = false
# This one activates in a very specific situation involving a steep downward slope and a wall.
## See the very bottom of this script for more info.




## Jump variables. These help us make a Jump mechanic that feels really good.

var jumping = false
# Activates if you've successfully left the ground by Jumping.
## This one is necessary for our Variable Jump Height.

var canjump = false
# Whether or not you're able to jump. When deactivated, your jump button will become useless.
## This one is necessary for our Coyote Timer.

var jumpbuffered = false
# Briefly activates every time you press the Jump button.
## This one variable is necessary for our Jump Buffer.




## The Player's stats.

const JUMP_VELOCITY = 350.0
# Jump height. Default: 350.0

var GRAVITY = 600
# Gravity force. Default: 600

const acc := 2
# Acceleration. Default: 2
# This is what moves you forward.

const dec := 30.0
# Deccelleration. Default: 30.0
## This is only used when you try to turn around.

const topspeed := 300.0
# Top Speed. Default: 300.0
## You won't be able to Accelerate past this point without some Momentum.


## Note: If you'd like to change the player's stats mid-game, make them variables instead.
## You can do this by changing the word "const" to "var".



## Alright, let's get started.

func _physics_process(delta):

# Set the Slope variables
	if is_on_floor():
		slopeangle = get_floor_normal().angle() + (PI/2)
		# This takes the angle of the floor and rotates it 90 degrees.
		
		slopefactor = get_floor_normal().x
		# Your acceleration will be affected based on how steep the slope is.
		## You'll slow down the most on a perfectly vertical wall,
		## and the least on the flat floor or the ceiling.
	else:
		slopefactor = 0
		# This makes sure your acceleration isn't affected by slopes while you're not on the ground.




# Rotation & Momentum Conversion
	$Collision.rotation = rot
	# Snap your Collision's rotation with the floor.
	## This ensures consistency when running along slopes.
	
	$Sprite.rotation = lerp_angle($Sprite.rotation, rot, 0.25)
	# Smoothly Interpolate your Sprite's rotation with the floor, somewhat similarly to Sonic Mania.
	## Looks nice!


	if is_on_floor():
		# Momentum Conversion
		if not grounded:
			if abs(slopeangle) >= 0.25 and abs(motion.y) > abs(motion.x): # If you land on a slope-
				# -and are falling faster than you're moving...
				motion.x += motion.y * slopefactor
				# Add Vertical Speed to Horizontal Speed based on the slope's steepness.
			grounded = true
		
		# Rotation
		up_direction = get_floor_normal()
		rot = slopeangle
		# The Up Direction is what helps you differentiate a wall from a floor.
		
		## This engine's platformer logic is simple:
		## You bump into walls, walk on floors, and bonk on ceilings.
		
		## By normal means, you can't walk on walls...
		## ...but by changing the Up Direction, we can change what the game defines as a floor,
		## thereby letting you walk on walls and ceilings.
		
		## Of course, we have to rotate the player along the floor as well,
		## otherwise that would cause some visual bugs.
		
	else: # If not on the floor anymore...
		# Reset Rotation and apply Momentum
		if not $Collision/Raycast.is_colliding() and grounded:
			grounded = false
			
			motion = get_real_velocity()
			# Set your motion to your actual velocity.
			## This is what converts your momentum when you fly off a slope.
			
			rot = 0
			up_direction = Vector2(0, -1)
			# Set your Rotation and Up Direction to their defaults.




# Gravity
	if not is_on_floor() and rot == 0:
		motion.y += GRAVITY * delta
		# The basic Gravity procedure.
		# We only trigger this if you're in the air. Otherwise, your vertical motion- 
		# -would try to increase infinitely while you're on the ground.
	else:
		if abs(slopefactor) == 1: # If running up a perfectly vertical wall...
			motion.y = 0
			# This makes sure you don't get any unwanted horizontal air speed when- 
			# -riding a perfectly U-shaped crevice. (Most of the time, at least.)
			# Without this, the motion addition below would cause you to drift off to-
			# -the side after launching yourself upwards.
		else:
			motion.y = 50
			# This tries to help you stick to the ground, though it's not very-
			# -effective at high speeds.
	



# Jump

# You'd think a Jumping mechanic would be simple, right? 
# Just add -JUMP_VELOCITY when you press the Jump button while on the floor, and you're done.
# That would make sense, but in reality, it's just not that simple.
# Think of it this way: While the game has frame-perfect reaction time for every little thing, the-
# -PLAYER does not.
# For example, you might walk off a cliff for a single frame and THEN press the jump button.
# In that situation, the game will NOT be forgiving.
# It will only see that you're not on the ground, and will ignore the jump input accordingly,
# -causing you to fall down embarrasingly.

# To avoid this, let's make a forgiving Jump mechanic.


## First, we make sure every jump input gets buffered.
# This will let us detect a single jump input for several frames instead of just one.

# The intention for this is to make it so that if you press jump slightly before hitting the ground, 
# it'll execute the jump the moment you land.

	if Input.is_action_just_pressed("jump"):
		jumpbuffered = true
		$JumpBufferTimer.start()
		# When the Jump button is pressed, start buffering the jump.
		# In the same breath, let's start a timer. Once that timer runs out,
		# the jump will stop being buffered.
		
		## To see exactly what happens when this timer runs out, check near the very bottom of the script.

## Now for the Coyote Timer.

	if not grounded and canjump: # If you're not on the ground, but are still able to jump...
		if $CoyoteTimer.is_stopped():
			$CoyoteTimer.start()
			# Start the Coyote timer.
			## We must only start it if it's stopped.
			## Otherwise, it would just constantly restart itself before it even finishes.
	else:
		$CoyoteTimer.stop()
		# If you're on the ground, or are already not able to jump, then there's no reason-
		# -for us to start the timer.

## Alright! Now let's actually execute the jump.

	if jumpbuffered and canjump: # If your jump input is detected and you're currently able to jump...
		motion.y = -JUMP_VELOCITY
		jumping = true
		# Jump.
		
		canjump = false
		# Then revoke your ability to jump. Don't worry, this will get reactivated once you land.
		## Without this part, you'd be able to fly up infinitely.
		
		
		if abs(rot) > 1: # If you're sideways or upside-down (on a wall or cieling)...
			position += Vector2(0, -(14)).rotated(rot)
			# Shift your position a bit away from the floor.
			## Because of the type of collision we're using,
			## getting stuck in a wall or ceiling is a big risk the player has.
			## This tries to prevent that from happening.
		
		
		$JumpBufferTimer.stop()
		jumpbuffered = false
		# Once all that's done, we stop the timer from running out-
		# -so that we can deactivate the buffer manually.
		# We are no longer detecting that Jump input.


	if motion.y >= 0 and grounded: # If you're DEFINITELY on the ground...
		jumping = false
		canjump = true
		# Let the script know you're not jumping anymore, and return your ability to jump.


	if jumping and motion.y < -JUMP_VELOCITY / 1.625: # If your jumping motion goes beyond a certain point...
		if not Input.is_action_pressed("jump"): # ...but you're NOT pressing the jump button anymore...
			motion.y = -JUMP_VELOCITY / 1.625
			# Set your vertical motion to that exact point.
			## Simply put, this lets you do high and low jumps depending on- 
			## -how long you press the button.




# (Debug) Speed Boost
	#if Input.is_action_just_pressed("action"):
	#	motion.x += topspeed * sign($Sprite.scale.x)




# Movement
	var direction = Input.get_axis("left", "right") # Emits "-1" if holding left, and "1" if holding right.
	
	if direction and not control_lock: # If holding left or right, and not slipping down a slope...
		if is_on_floor(): # If touching the floor...
			if direction == sign(motion.x): # If you're holding in the direction you're moving...
				if abs(motion.x) <= topspeed: # If you're not over your Top Speed...
					motion.x += acc * direction
					# Accelerate in the direction you're holding.
					
			else: # If you're trying to turn around...
				if abs(slopefactor) < 0.4: # If you're standing on flat or slightly slanted ground...
					motion.x += dec * direction
					# Very quickly Deccelerate to a stop.
				else: # If you're standing on a far too steep slope...
					motion.x += acc * direction
					# Turn at normal speed.
					## Logically, it would be pretty hard to slow down when running down a hill.
				
				
		else: # If mid-air...
			if direction == sign(motion.x): # If you're holding in the direction you're moving...
				if abs(motion.x) <= topspeed: # If you're not over your Top Speed...
					motion.x += (acc * 2) * direction
					# Accelerate (a bit faster) in the direction you're holding.
					
			else: # If you're trying to turn around...
				motion.x += (acc * 2) * direction
				# Deccellerate at the same speed.
			
			# Note: Due to logic, you can't quickly turn around mid-air.
			
	else: # If not pressing anything...
		if is_on_floor() and abs(slopefactor) < 0.25: # If you're on flat, or near-flat ground...
			motion.x = move_toward(motion.x, 0, acc)
			# Slow to a stop.
			## We shouldn't be able to stand perfectly still on a steep slope, right? Right.




# Set Velocity to the Motion variable, but rotated.
	velocity = Vector2(motion.x, motion.y).rotated(rot)
	
	# Right here's where the magic happens.
	# Since Velocity is a Vector2, we've cleverly created a separate Vector2 called "Motion" to-
	# -take all the commands that Velocity would normally take, to then give it right back to-
	# -Velocity with an added ".rotated()" function, which effortlessly rotates Motion based on
	# -your actual rotation, therefore letting you run up walls and stuff.
	



# Slopes
	if is_on_floor() and not stuck and not $Collision/WallCast.is_colliding():
		motion.x += (acc * 2) * slopefactor
		# When you're moving down a slope, add more acceleration.
		# When you're moving up a slope, slow the player down.
		## This is what gives Momentum.
		## Without this, running up walls would be too unnaturally easy.
	
	if grounded and abs(slopefactor) >= 0.5 and abs(motion.x) < 10: # 
		control_lock = true
		$ControlLockTimer.start()
		# If you slow down too much on a steep slope, briefly remove the ability to move left and right.
		## This makes the player slip down the slope
	
	if grounded and abs(slopeangle) > 1.5: # If you're on a wall...
		if abs(motion.x) < 80: # ...and you're moving too slow...
			falloffwall = true
			position += Vector2(0, -(14)).rotated(rot)
			canjump = false
			# Detatch from the wall.
			
			control_lock = true
			$ControlLockTimer.start()
			# Briefly lock the player's controls.
			## We wouldn't want them to awkwardly re-attatch to the wall over and over again.
	else:
		falloffwall = false
	



# Stoppers
	if is_on_ceiling() and not grounded: # If you bonk your head on the ceiling...
		if motion.y < 0: # If you're moving up...
			motion.y = 100
			# Get sent right back down.

	if is_on_wall() and $Collision/WallCast.is_colliding(): # If you bump into a wall...
		motion.x = 0
		# Stop moving.



	animate()
	#slope_failsafe()
	move_and_slide()




# That's the main part of the script done with.
# Now let's move on to extra functions and timer signals.




# Animation
## We don't set the animations in the physics_process() code because that would be messy.

## Like the Amy sprites? I made them myself. Use them if you'd like, I don't care.
## Though, you're obviously intended to swap them out with your own (probably ripped) sprites.

## I mostly just did this part for some visual flair.
## Could you imagine how boring it would be if you were just a box sliding around?

## Anyway, I won't explain every line in this part, but I will explain some of it.

var idle := true
var idleset := false

func animate():
	if abs(motion.x) > 1: # If you're moving...
		$Sprite.scale.x = sign(motion.x)
		$Collision.scale.x = sign(motion.x)
		# Set Sprite scale and Collision scale based your direction.
		# This is how the Sprite is able to turn when you move.
	
	
	if grounded:
		if abs(motion.x) < 1: # If you're standing still, or at least EXTREMELY CLOSE to standing still...
			$Sprite.speed_scale = 1
			# Reset the Speed Scale.
			
		elif abs(motion.x) < topspeed - 10: # If you're moving, but not at your Top Speed yet...
			$Sprite.play("walk")
			$Sprite.speed_scale = 0.5 + (abs(motion.x) / 350)
			# Play Walking Animation at half speed, quickening it as you move faster and faster.
			
		else: # If you've reached, or are at least close enough to your Top Speed...
			$Sprite.play("run")
			$Sprite.speed_scale = 1 + (abs(motion.x) / (topspeed * 2))
			# Play Running Animation, quickening it even further if you escalate past your Top Speed.
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
	# After a brief moment, your ability to move left and right is restored.

func _on_jump_buffer_timer_timeout():
	jumpbuffered = false
	# If you pressed jump but aren't close enough to the ground, it stops buffering your jump.

func _on_coyote_timer_timeout():
	canjump = false
	# If you've been in the air for too long, your ability to jump is revoked.




# WARNING
## I tucked this part at the bottom of the script since this is just for a pretty rare scenario.
## Basically, if you ran down a slope that looks like THIS:
##
##                                |
## _ _ _ _ _ _ _ _ _ _ _ _        |
##                         \      |
##                           \    |
##                             \  |
##                               \|
##
## ...You'll get trapped in the corner forever. And get stuck in the wall.
##  So... please don't do that.


# I tried to write a thing to fix this:
func slope_failsafe():
	if is_on_floor() and ($Collision/WallCast.is_colliding() and abs(rot) > 0.4):
		if abs(motion.x) > 100 and sign(rot) == sign(motion.x):
			stuck = true
			motion.x = -sign(slopefactor) * motion.x
			# It basically just reverses your movement if you get stuck.
	else:
		stuck = false
# ...but it kinda broke something else. So I disabled it. Oh well.





## Thanks for downloading.
## I made this because I was sick of there being no tutorials on how to make Sonic physics in Godot.
## Hope my comments were helpful.
## Have fun developing!!
## - Maddie
