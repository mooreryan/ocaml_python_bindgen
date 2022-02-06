class Cat:
    def __init__(self, name):
        self.name = name
        self.hunger = 10

    def eat(self, fly):
        # fly is pointless here, but its just an example :)
        self.hunger -= 5
        
