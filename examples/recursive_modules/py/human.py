class Human:
    # Humans have cats
    def __init__(self, name):
        self.name = name
        self.cat = None

    def __str__(self):
        if self.cat:
            cat = self.cat.name
        else:
            cat = "none"

        return f'Human -- name: {self.name}, cat: {cat}'

    def adopt_cat(self, cat):
        self.cat = cat
