(define (domain sorbet-station)
  (:requirements :strips :equality)
  (:predicates
    (Stackable ?o ?r)
    (Tub ?r)
    (Bowl ?r)
    (Scoop ?r)

    (Gripped ?o)
    (Grasp ?o ?g)
    (Kin ?o ?p ?g ?q ?t)
    (FreeMotion ?q1 ?t ?q2)
    (HoldingMotion ?q1 ?t ?q2 ?o ?g)
    (Supported ?o ?p ?r)
    (TrajCollision ?t ?o2 ?p2)

    (AtPose ?o ?p)
    (AtGrasp ?o ?g)
    (HandEmpty)
    (AtConf ?q)
    (CanMove)
    (Cleaned)
    (Wash ?o)
    (VanillaDirty)
    (StrawDirty)

    (First ?o ?r)
    (Second ?o ?r)
    (isEmpty)
    (isOne)
    (isTwo)
    (One ?o)
    (Two ?o)
    (Holding ?o)
    (UnsafeTraj ?t)

    (StrawScoop ?o)
    (VanillaScoop ?o)
  )

  (:action move_free
    :parameters (?q1 ?q2 ?t)
    :precondition (and (FreeMotion ?q1 ?t ?q2)
                       (AtConf ?q1) (HandEmpty) (CanMove) (not (UnsafeTraj ?t)))
    :effect (and (AtConf ?q2)
                 (not (AtConf ?q1)) (not (CanMove)))
  )
  (:action move_holding
    :parameters (?q1 ?q2 ?o ?g ?t)
    :precondition (and (HoldingMotion ?q1 ?t ?q2 ?o ?g)
                       (AtConf ?q1) (AtGrasp ?o ?g) (CanMove) (not (UnsafeTraj ?t)))
    :effect (and (AtConf ?q2)
                 (not (AtConf ?q1)) (not (CanMove)))
  )
  (:action scoop_vanilla
    :parameters (?o ?p ?g ?q ?t)
    :precondition (and (Kin ?o ?p ?g ?q ?t)
                       (AtPose ?o ?p) (HandEmpty) (AtConf ?q)  (VanillaScoop ?o) (not (StrawDirty)) (not (UnsafeTraj ?t)) )
    :effect (and (AtGrasp ?o ?g) (CanMove)
                 (not (AtPose ?o ?p)) (not (HandEmpty)) (VanillaDirty))
  )
  (:action scoop_straw
    :parameters (?o ?p ?g ?q ?t)
    :precondition (and (Kin ?o ?p ?g ?q ?t)
                       (AtPose ?o ?p) (HandEmpty) (AtConf ?q) (StrawScoop ?o) (not (VanillaDirty))  (not (UnsafeTraj ?t)) )
    :effect (and (AtGrasp ?o ?g) (CanMove)
                 (not (AtPose ?o ?p)) (not (HandEmpty)) (StrawDirty))
  )
  (:action dump_first
    :parameters (?o ?p ?g ?q ?t)
    :precondition (and (Kin ?o ?p ?g ?q ?t)
                       (AtGrasp ?o ?g) (AtConf ?q) (isEmpty) (not (UnsafeTraj ?t)))
    :effect (and (AtPose ?o ?p) (HandEmpty) (CanMove)
                 (not (AtGrasp ?o ?g))
                  (not(isEmpty)) (One ?o))
  )
  (:action dump_second
    :parameters (?o ?p ?g ?q ?t)
    :precondition (and (Kin ?o ?p ?g ?q ?t)
                       (AtGrasp ?o ?g) (AtConf ?q) (not(isEmpty)) (not (UnsafeTraj ?t)))
    :effect (and (AtPose ?o ?p) (HandEmpty) (CanMove)
                 (not (AtGrasp ?o ?g))
                  (Two ?o))
  )
  (:action wash
    :parameters (?o ?p ?g ?q ?t)
    :precondition (and (Kin ?o ?p ?g ?q ?t)
                       (AtPose ?o ?p) (HandEmpty) (Wash ?o) (AtConf ?q) (not (UnsafeTraj ?t)) (or (VanillaDirty) (StrawDirty)))
    :effect (and (CanMove)
                 (not (AtPose ?o ?p)) (not (VanillaDirty)) (not (StrawDirty)) )
  )
 
  (:derived (First ?o ?r)
    (exists (?p) (and (One ?o) (Supported ?o ?p ?r)
                      (AtPose ?o ?p) (Bowl ?r) (or (VanillaScoop ?o) (StrawScoop ?o)) ))
  )
  (:derived (Second ?o ?r)
    (exists (?p) (and (Two ?o) (Supported ?o ?p ?r)
                      (AtPose ?o ?p) (or (VanillaScoop ?r) (StrawScoop ?r)) (or (VanillaScoop ?o) (StrawScoop ?o))  ))
  )


  (:derived (Holding ?o)
    (exists (?g) (and (Grasp ?o ?g)
                      (AtGrasp ?o ?g)))
  )
  ; (:derived (UnsafeTraj ?t)
  ;  (exists (?o2 ?p2) (and (TrajCollision ?t ?o2 ?p2)
  ;                         (AtPose ?o2 ?p2)))
  ; )
)