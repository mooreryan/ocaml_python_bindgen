class Thing:
    """A thing is pretty basic.  It does have a color though!"""

    def __init__(self, color):
        """Just to see if {| any |} characters mess it up."""
        self.color = color

    def __str__(self):
        return(f'Thing -- color: {self.color}')
