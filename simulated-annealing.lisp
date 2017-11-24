; SIMULATED ANNEALING
; current ← MAKE-NODE (problem.INITIAL-STATE)
;   for t = 1 to ∞ do
;   T ← schedule(t)
;   if T = 0 then return current
;   next ← a randomly selected successor of current
;   ΔE ← next.VALUE – current.VALUE
;   if ΔE > 0 then current ← next
;   else current ← next only with probability e^ΔE/T

(defstruct problem
	initial-state
	gen-successors
	state-value ; evaluate a state to determine how good it is
	schedule ; cooling schedule function
	initial-schedule-value) ; initial value for the scheduling function

(defun create-problem-simulated-annealing (initial-state gen-successors
											&key state-value schedule initial-schedule-value)
	(make-problem :initial-state initial-state
				  :gen-successors gen-successors
				  :state-value state-value
				  :schedule schedule
				  :initial-schedule-value initial-schedule-value))

(defun get-random-element (some-list)
	"Get a random element from a list"
	(nth (random (length some-list)) some-list))

(defun check-probability (delta-worse temp)
	"Returns true with probability e^ΔE/T"
	(<= (/ (random 100) 100) (exp (/ delta-worse temp))))

(defun cost-savings (a b c)
	"Calculate cost savings between location a and b when c is inserted between, Cost = c[a-c] + c[b-c] - c[a-b]
	NOTE LESS is BETTER"
	(let ((dac (distance (get-location a) (get-location c)))
		  (dbc (distance (get-location b) (get-location c)))
		  (dab (distance (get-location a) (get-location b))))
		(- (+ dac dbc) dab)))


(defun invalid-vehicle (state vehicle)
	(or (>= vehicle (length (state-vehicle-routes state))) (< vehicle 0)))

(defun invalid-index (vehicle-route index)
	(or (> index (length vehicle-route)) (< index 0)))

;; index [0 ...... n] (para inserir na ultima posicao e necessario colocar index = n)
;; insere cliente na posicao especificada por index
(defun insert-customer (state id vehicle index added-length) ; NOTE this does not adjust remaining capacity or remaining length
	"Insert a customer ID in given vehicle path at specific index, added-length should contain how much the route will be increased"
	(if (invalid-vehicle state vehicle)
		(error "~S is not a valid vehicle-id." vehicle)
		(let ((vehicle-route (get-vehicle-route state vehicle)))
			(if (invalid-index vehicle-route index)
				(error "Index out-of-range [input: ~D, Maxlength: ~D] in vehicle-route of vehicle ~D." index (length vehicle-route) vehicle)
				(progn
					(if (= index 0) ; push normal
						(push id vehicle-route)
						(push id (cdr (nthcdr (1- index) vehicle-route))))
					(set-vehicle-route state vehicle-route vehicle)
					(set-remaining-capacity state (- (get-remaining-capacity state vehicle) (get-demand id)) vehicle)
					(set-remaining-length state (- (get-remaining-length state vehicle) added-length) vehicle))))))

(defun assess-path-insertions (id path remaining-length remaining-capacity &key (index 1))
	"Verify all insertions in path and returns the best one, takes remaining length and capacity into account"
	(when (equalp path '(0)) (return-from assess-path-insertions (values most-positive-fixnum index))) ; returns largest number possible
	(let ((cost (cost-savings (car path) (car (cdr path)) id)))
		(multiple-value-bind (rest-cost rest-index) (assess-path-insertions id (cdr path) remaining-length remaining-capacity :index (1+ index))
			; verify remaining length and capacity, if not enough return large cost so it doesn't get selected
 			(when (or (> (get-demand id) remaining-capacity) (< remaining-length cost)) (return-from assess-path-insertions (values most-positive-fixnum index)))
			; decide if we return the cost gathered by recursion or the current one
			;(format t "~F[~D] . ~F[~D]~%" cost index rest-cost rest-index)
			(if (< cost rest-cost) (values cost index) (values rest-cost rest-index)))))

(defun is-in-vehicle-slice (id vehicle)
	"Check if id is in vehicle map slice, any point in a vehicle map slice ... FIXME")

(defun do-optimal-insertion (state id)
	"Returns state in which the optimal insertion was done"
	(let ((min-vcost most-positive-fixnum) (min-index nil) (min-vehicle nil))
		(dotimes (i (vrp-vehicles.number *vrp-data*))
			(multiple-value-bind (cost index) (assess-path-insertions id (get-vehicle-route state i) (get-remaining-length state i) (get-remaining-capacity state i))
				(print cost)
				(when (< cost min-vcost)
					(setf min-vcost cost) (setf min-index index) (setf min-vehicle i))))
	(when (not (null min-vehicle)) (insert-customer state id min-vehicle min-index min-vcost))))

;; ---------------------------------
;; INITIAL SOLUTION AND NEIGHBORHOOD
;; ---------------------------------

(defun initial-solution (zero-state)
	"get the first solution for the simulated annealing problem"
	(dolist (cid (get-unvisited-customer-ids zero-state))
		(do-optimal-insertion zero-state cid)
		(log-state zero-state)
		(print cid)
		(break )
		))

(defun neighbor-states (state)
	"Get all neighbor states"
	nil)

;; -----------------------------
;; VALUE OF A STATE
;; -----------------------------

(defconstant REMAIN_TOUR_CAPACITY_FACTOR 0.2) ; used for state-value calculations as a factor for remaining tour length and vehicles capacity (should be <1 to enphasise the number of unvisited locations)

(defun state-value (state)
	(let ((remaining-tour (reduce #'+ (state-remaining-tour-length state)))
		  (remaining-capacity (reduce #'+ (state-remaining-capacity state)))
		  (max-capacity (* (vrp-vehicles.number *vrp-data*) (vrp-vehicle.capacity *vrp-data*)))
		  (max-length (* (vrp-vehicles.number *vrp-data*) (vrp-max.tour.length *vrp-data*))))
		; unvisited-locations + REMAIN_TOUR_CAPACITY_FACTOR * (max-rem-tour - remaining-tour) (max-capacity - remaining-capacity)
		; closer to the end of the journey (length or capacity) higher the value of the state
		(+ (state-number-unvisited-locations state) (* REMAIN_TOUR_CAPACITY_FACTOR (+ (- max-length remaining-tour) (- max-capacity remaining-capacity))))))

;; -----------------------------
;; COOLING SCHEDULES
;; -----------------------------

; Good values for this ALPHA range from 0.8 to 0.99 (higher ALPHA => cools slower)
(defconstant ALPHA 0.97) ; used for exponential-multiplicative cooling
(defconstant INITIAL_TEMP 100) ; used for exponential-multiplicative cooling

(defun exponential-multiplicative-cooling (delta-t &key initial-temp)
	"Cooling scheduler Tk = T0 * a^k"
	(if (null initial-temp) (setf initial-temp INITIAL_TEMP))
	(* initial-temp (expt ALPHA delta-t)))


(defun logarithmic-multiplicative-cooling (delta-t &key initial-temp)
	"Cooling scheduler  = T0 / ( 1+ a * log(1 + k) )"
	0)

;; -----------------------------

(defun simulated-annealing (problem)
	(let ((current (problem-initial-state problem))
		  (time-value 0)
		  (successors nil))
		(loop while (and (incf time-value)
						 (setf successors (funcall (problem-gen-successors problem) current))
						 (incf *nos-expandidos*)
						 (incf *nos-gerados* (length successors))) do
			(let* ((temp (funcall (problem-schedule problem) time-value :initial-temp (problem-initial-schedule-value problem)))
				  (next (get-random-element successors))
				  (delta-worse (- (funcall (problem-state-value problem) current) (funcall (problem-state-value problem) next))))
				(if (equalp temp 0)
					(return current))
				(if (> delta-worse 0)
					(setf current next)
					(if (check-probability delta-worse temp)
						(setf current next)))))
	current))
