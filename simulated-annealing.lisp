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
	"get a random element from a list"
	(nth (random (length some-list)) some-list))

(defun check-probability (delta-worse temp)
	"returns true with probability e^ΔE/T"
	(<= (/ (random 100) 100) (exp (/ delta-worse temp))))


; VALUE OF A STATE
(defun state-value (state)
	(let ((remaining-tour (reduce #'+ (state-remaining-tour-length state)))
		  (remaining-capacity (reduce #'+ (state-remaining-capacity state)))
		  (max-capacity (* (vrp-vehicles.number *vrp-data*) (vrp-vehicle.capacity *vrp-data*)))
		  (max-length (* (vrp-vehicles.number *vrp-data*) (vrp-max.tour.length *vrp-data*))))
		(+ (state-number-unvisited-locations state) (+ remaining-tour remaining-capacity)))) ; FIXME

;; -----------------------------
;; COOLING SCHEDULES
;; -----------------------------

; Good values for this ALPHA range from 0.8 to 0.99
(defconstant ALPHA 0.9) ; used for exponential-multiplicative cooling
(defconstant INITIAL_TEMP 2000) ; used for exponential-multiplicative cooling

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
	current)) ; FIXME This should not be needed, only stops when temp is zero
