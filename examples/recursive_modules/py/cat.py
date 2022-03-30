class Cat:
    # Cats have humans
    def __init__(self, name):
        self.name = name
        self.human = None

    def __str__(self):
        if self.human:
            human = self.human.name
        else:
            human = "none"

        return f'Cat -- name: {self.name}, human: {human}'

    def adopt_human(self, human):
        self.human = human
