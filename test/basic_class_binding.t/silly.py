class Silly:
    def __init__(self, x, y):
        self.x = x
        self.y = y

    def foo(self, a, b):
        return a + b + self.x + self.y

    def do_nothing(self):
        return None

    def return_list(self, l):
        return l

    def return_opt_list(self, l):
        return l

    def return_array(self, a):
        return a

    def return_opt_array(self, a):
        return a

    @staticmethod
    def bar(a, b):
        return a + b

    @staticmethod
    def do_nothing2():
        return None
