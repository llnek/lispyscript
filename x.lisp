
(loop (result [] x 4)
  (if (= 0 x)
    result
    (do
      (result.push x)
      (recur result (dec x)))))

