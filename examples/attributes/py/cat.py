class Cat:
    def __init__(self, name):
        self.name = name
        self.hunger = 0

    def __str__(self):
        return(f'Cat -- name: {self.name}, hunger: {self.hunger}')

    def eat(self, num_mice=1):
        self.hunger -= (num_mice * 5)
        if self.hunger < 0:
            self.hunger = 0

    def jump(self, how_high=1):
        if how_high > 0:
            self.hunger += how_high

    def say(self, a, b, c, d):
        return(f'{self.name} says {a}, {b}, {c} and {d}.')
