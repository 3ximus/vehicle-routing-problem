;;; Run a few tests

(load "vrp")

(setf *vrp-prob* (make-vrp  :name "CMT1"
							:vehicle.capacity 160
							:vehicles.number 5
							:max.tour.length 150
							:customer.locations '((0 30.0 40.0) (1 37.0 52.0) (2 49.0 49.0) (3 52.0 64.0)
													(4 20.0 26.0) (5 40.0 30.0) (6 21.0 47.0) (7 17.0 63.0)
													(8 31.0 62.0) (9 52.0 33.0) (10 51.0 21.0) (11 42.0 41.0)
													(12 31.0 32.0) (13 5.0 25.0) (14 12.0 42.0)
													(15 36.0 16.0) (16 52.0 41.0) (17 27.0 23.0)
													(18 17.0 33.0) (19 13.0 13.0) (20 57.0 58.0)
													(21 62.0 42.0) (22 42.0 57.0) (23 16.0 57.0)
													(24 8.0 52.0) (25 7.0 38.0) (26 27.0 68.0) (27 30.0 48.0)
													(28 43.0 67.0) (29 58.0 48.0) (30 58.0 27.0)
													(31 37.0 69.0) (32 38.0 46.0) (33 46.0 10.0)
													(34 61.0 33.0) (35 62.0 63.0) (36 63.0 69.0)
													(37 32.0 22.0) (38 45.0 35.0) (39 59.0 15.0) (40 5.0 6.0)
													(41 10.0 17.0) (42 21.0 10.0) (43 5.0 64.0)
													(44 30.0 15.0) (45 39.0 10.0) (46 32.0 39.0)
													(47 25.0 32.0) (48 25.0 55.0) (49 48.0 28.0)
													(50 56.0 37.0))
							:customer.demand '((0 0) (1 7) (2 30) (3 16) (4 9) (5 21) (6 15) (7 19) (8 23)
												(9 11) (10 5) (11 19) (12 29) (13 23) (14 21) (15 10)
												(16 15) (17 3) (18 41) (19 9) (20 28) (21 8) (22 8) (23 16)
												(24 10) (25 28) (26 7) (27 15) (28 14) (29 6) (30 19)
												(31 11) (32 12) (33 23) (34 26) (35 17) (36 6) (37 9)
												(38 15) (39 14) (40 7) (41 27) (42 13) (43 11) (44 16)
												(45 10) (46 5) (47 25) (48 17) (49 18) (50 10))))

;(write (create-initial-state *vrp-prob*))
;(format T "~%~%state: ~S~%~%" state)

;(setf *customerHash* (makeCustomerHash (vrp-customer.locations *vrp-prob*) (vrp-customer.demand *vrp-prob*)))
;(format T "id: ~X location: ~X demand: ~D~%" 3 (getCustomerLocation *customerHash* 3) (getCustomerDemand *customerHash* 3))

(trace exponential-multiplicative-cooling)
;(trace gen-successors)
;(trace cost-function)
(setf result (vrp *vrp-prob* "simulated.annealing.or.genetic.algoritm"))
(write result)

; NOTE OUTPUT TO BE MADE INTO A GRAPH
(with-open-file (str "out.txt"
					 :direction :output
					 :if-exists :supersede
					 :if-does-not-exist :create)
	(format str "~S~%~%~S" *vrp-prob* result))
