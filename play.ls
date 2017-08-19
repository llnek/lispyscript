
;(var a 5 b (+ 4 3) c (poo.foo (+ 6 8) (fred.jer 9 0)))
;(throw (new String (str "poo" (str "face"))))

;(get (poo.foo (+ 2 "2")) (+ 3 4) )
(loop (x i) (7 1)
      (if (= i 10)
        i
        (recur x ++i)))


function ttt(fn) {
  while (fn &&
         Object.prototype.toString.call(fn) == "[object Function]") {
    fn=fn();
  }
  return fn;
}

function fac(acc, n) {
  console.log("fac entered: n= " + n);
  try {
    if (n < 1) return acc;
    else return function() { return fac(acc *n, n-1); };
  } finally {
    console.log("fac exited: n= " + n);
  }
}

a=ttt(function() { return fac(1,5);});
console.log(a);

public class Trampoline<T>
{
    public T getValue() {
        throw new RuntimeException("Not implemented");
    }

    public Optional<Trampoline<T>> nextTrampoline() {
        return Optional.empty();
    }

    public final T compute() {
        Trampoline<T> trampoline = this;

        while (trampoline.nextTrampoline().isPresent()) {
            trampoline = trampoline.nextTrampoline().get();
        }

        return trampoline.getValue();
    }
}

public final class Factorial
{
    public static Trampoline<Integer> createTrampoline(final int n, final int sum)
    {
        if (n == 1) {
            return new Trampoline<Integer>() {
                public Integer getValue() { return sum; }
            };
        }

        return new Trampoline<Integer>() {
            public Optional<Trampoline<Integer>> nextTrampoline() {
                return Optional.of(createTrampoline(n - 1, sum * n));
            }
        };
    }
}

Factorial.createTrampoline(4, 1).compute()




