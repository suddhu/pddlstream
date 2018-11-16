; everything written here, should have a corresponding function!
; what are all these streams? 
(define (stream kitchen2d)
	;(:predicate (Collision ?control ?gripper ?pose)
	;    (and (IsControl ?control) (IsPose ?gripper ?pose))
	;)
	(:stream sample-motion
		:inputs (?gripper ?pose ?pose2)
		:domain (and (IsGripper ?gripper) (IsPose ?gripper ?pose) (IsPose ?gripper ?pose2))
		:outputs (?control)
		:certified (and (Motion ?gripper ?pose ?pose2 ?control) (IsControl ?control))
	)
	(:stream sample-motion-h
		:inputs (?gripper ?pose ?cup ?grasp ?pose2)
		:domain (and (IsGripper ?gripper) (IsPose ?gripper ?pose)
					(IsGrasp ?cup ?grasp) (IsPose ?gripper ?pose2))
		:outputs (?control)
		:certified (and (MotionH ?gripper ?pose ?cup ?grasp ?pose2 ?control)
		                (IsControl ?control))
	)
	(:stream sample-grasp-ctrl
		:inputs (?gripper ?cup ?pose2 ?grasp)
		:domain (and (IsGripper ?gripper) (IsPose ?cup ?pose2)
					(IsGrasp ?cup ?grasp))
		:outputs (?pose ?control)
		:certified (and (CanGrasp ?gripper ?pose ?cup ?pose2 ?grasp ?control)
						(IsPose ?gripper ?pose) (IsControl ?control))
	)
	(:stream sample-grasp-cup
		:inputs (?cup)
		:domain (IsCup ?cup)
		:outputs (?grasp)
		:certified (IsGrasp ?cup ?grasp)
	)
	(:stream sample-scoop
		:inputs (?gripper ?kettle ?pose3)
		:domain (and (IsGripper ?gripper)
					(IsCup ?kettle) (IsPose ?kettle ?pose3))
		:outputs (?pose ?pose2 ?control)
		:certified (and (CanScoop ?gripper ?pose ?pose2 ?kettle ?pose3 ?control)
						(IsPose ?gripper ?pose) (IsPose ?gripper ?pose2)
						)
	)
	(:stream sample-dump
		:inputs (?gripper ?kettle ?pose2)
		:domain (and (IsGripper ?gripper)
					 (IsCup ?kettle)
					(IsPose ?kettle ?pose2))
		:outputs (?pose ?pose3 ?control)
		:certified (and (CanDump ?gripper ?pose ?pose3 ?kettle ?pose2 ?control)
						(IsPose	?gripper ?pose) (IsPose ?gripper ?pose3))
	)
)
