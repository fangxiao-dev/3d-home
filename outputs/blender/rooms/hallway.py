"""Build the long, uncluttered hallway in Blender world coordinates.

The hallway is a shared circulation shell.  Its north and south walls keep
only the portals owned by the room contract; the three closed doors are
decorative endpoints with no interior room behind them.
"""


def build(api):
    """Build the hallway shell, closed doors, wall lights, and ceiling lights."""
    x0, x1, y0, y1 = api.bounds

    # The corridor is intentionally open along the center line.  Adjacent
    # rooms own the omitted boundaries and the closed doors do not imply any
    # modeled space behind them.
    api.shell({
        'west': (),
        'east': (),
        'north': ((-2.9, 2.9, 3.3),),
        'south': ((-2.9, 2.0, 3.3), (2.35, 4.2), (6.1, 7.6)),
    })

    # Closed doors sit on the existing wall segments.  The west/east casing
    # and handle are supplied by the shared adapter; there is no F action.
    api.furniture_id = 'hallway_door'
    api.door('hallway north storage door', (5.6, y1), 'north')
    api.door('hallway north bedroom door', (10.2, y1), 'north')
    api.door('hallway south storage door', (10.8, y0), 'south')

    # Two small end-wall sconces provide a warm visual cue without narrowing
    # the route.  They are detail-only; lighting remains owned by the scene.
    api.furniture_id = ''
    api.box('hallway west sconce plate', (x0 + .025, -1.0, 1.76),
            (.05, .18, .30), 'trim', .02, False, 'west')
    api.ellipsoid('hallway west sconce glow', (x0 + .065, -1.0, 1.76),
                  (.035, .12, .16), 'bulb', False, 'west')
    api.box('hallway east sconce plate', (x1 - .025, -1.0, 1.76),
            (.05, .18, .30), 'trim', .02, False, 'east')
    api.ellipsoid('hallway east sconce glow', (x1 - .065, -1.0, 1.76),
                  (.035, .12, .16), 'bulb', False, 'east')

    # Four small round fixtures distribute warm light over the long run.
    # They sit below the ceiling crown and are non-collidable details.
    for index, x in enumerate((-1.0, 3.2, 7.4, 11.0)):
        api.cylinder('hallway ceiling light ' + str(index),
                     (x, -1.0, 3.25), .12, .05, 'brass', solid=False,
                     side='top')
        api.ellipsoid('hallway ceiling bulb ' + str(index),
                      (x, -1.0, 3.20), (.10, .10, .05), 'bulb', False,
                      'top')

