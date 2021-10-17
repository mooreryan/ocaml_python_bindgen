class Silly:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def foo(self, a, b):
        return a + b + self.x + self.y

    def do_nothing(self):
        return None

    @staticmethod
    def bar(a, b):
        return a + b

    @staticmethod
    def do_nothing2():
        return None
