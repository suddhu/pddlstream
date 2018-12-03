(define (problem pb2)
   (:domain blocksworld)
   (:objects vanilla strawberry cup1 cup2)
   (:init
     (is-cup cup1)
     (is-cup cup2)
     (clear cup1)
     (clear cup2)
     (is-vanilla vanilla)
     (is-straw strawberry)
   )
   (:goal ( and 
   				(Order cup1 vanilla strawberry vanilla) 
   				(Order cup2 vanilla vanilla vanilla) 
   		  )
   )
)