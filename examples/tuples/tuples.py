def pair(x, y):
    return (x, y)


def first(x):
    return x[0]


def identity(x):
    return x


def make(x=(0, 0)):
    return x


def add(points1, points2):
    return [(x1 + y1, x2 + y2) for (x1, x2), (y1, y2) in zip(points1, points2)]
