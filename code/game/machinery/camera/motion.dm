/obj/machinery/camera
	var/list/motionTargets = list()
	var/detectTime = 0
	var/area/ai_monitored/area_motion = null
	var/alarm_delay = 100 // Don't forget, there's another 10 seconds in queueAlarm()

/obj/machinery/camera/internal_process()
	// motion camera event loop
	if (stat & (EMPED|NOPOWER))
		return
	if(!isMotion())
		return PROCESS_KILL
	if (detectTime > 0)
		var/elapsed = world.time - detectTime
		if (elapsed > alarm_delay)
			triggerAlarm()
	else if (detectTime == -1)
		for (var/mob/target in motionTargets)
			if (target.stat == 2) lostTarget(target)
			// If not detecting with motion camera...
			if (!area_motion)
				// See if the camera is still in range
				if(!in_range(src, target))
					// If they aren't in range, lose the target.
					lostTarget(target)

/obj/machinery/camera/proc/newTarget(var/mob/target)
	if (isAI(target)) return 0
	if (detectTime == 0)
		detectTime = world.time // start the clock
	if (!(target in motionTargets))
		motionTargets += target
	return 1

/obj/machinery/camera/proc/lostTarget(var/mob/target)
	if (target in motionTargets)
		motionTargets -= target
	if (motionTargets.len == 0)
		cancelAlarm()

/obj/machinery/camera/proc/cancelAlarm()
	if (!status || (stat & NOPOWER))
		return 0
	if (detectTime == -1)
		motion_alarm.clearAlarm(loc, src)
	detectTime = 0
	return 1

/obj/machinery/camera/proc/triggerAlarm()
	if (!status || (stat & NOPOWER))
		return 0
	if (!detectTime) return 0
	motion_alarm.triggerAlarm(loc, src)
	detectTime = -1
	return 1

/obj/machinery/camera/HasProximity(turf/T, datum/weakref/WF, old_loc)
	if(isnull(WF))
		return
	var/atom/movable/AM = WF.resolve()
	if(isnull(AM))
		log_debug("DEBUG: HasProximity called without reference on [src].")
		return
	// Motion cameras outside of an "ai monitored" area will use this to detect stuff.
	if (!area_motion)
		if(isliving(AM))
			newTarget(AM)
