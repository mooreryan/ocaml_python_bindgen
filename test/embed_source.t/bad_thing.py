class Thing:
    """A thing is pretty basic.  It does have a color though!"""

    def __init__(self, color):
        """This will break :) {pyml_bindgen_string_literal| any |pyml_bindgen_string_literal}."""
        self.color = color

    def __str__(self):
        return(f'Thing -- color: {self.color}')
