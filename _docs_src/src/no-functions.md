# You can only bind methods, not functions

Currently, you can only bind to functions within Python classes (a.k.a., Python methods).  At some point, I will change it so you can also bind Python functions that aren't associated with a class.

Here's what I mean.  A function that isn't associated with a class currently cannot be bound with `pyml_bindgen`.

```python
# Can't bind this
def foo(x, y):
    return x + y
```

But that same function associated with a class, can be bound by `pyml_bindgen`.

```python
# Can bind this
class Apple:
    @staticmethod
    def foo(x, y):
        return x + y
```

Let me just be clear that `pyml` can bind this function just fine, only, you would need to write this binding by hand.
