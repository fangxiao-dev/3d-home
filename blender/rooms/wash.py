"""Photo-led, walkable wash area in Blender world coordinates.

The north edge belongs to the hallway.  The vanity stays against the west
wall so the approach from the hallway keeps a straight clear line through the
room; the south door is a closed visual boundary with no room behind it.
"""


def build(api):
    """Build the wash shell, a compact vanity, and the closed toilet door."""
    x0, x1, y0, y1 = api.bounds

    # Hallway owns the north boundary and its X=2.35..4.2 doorway.  The
    # remaining three sides make this room visually complete without exposing
    # the non-open toilet area behind the south wall.
    api.shell({
        'west': (),
        'east': (),
        'south': (),
    })

    # Closed toilet door: decorative only, with no interior geometry behind it.
    api.furniture_id = 'wash_door'
    api.door('toilet closed door', (3.72, y0), 'south', width=1.10)

    # The vanity runs along the west side.  Its east edge stops at x=2.88, so
    # the required x=3.25 approach remains clear from the north entry to y=-3.3.
    vanity_x, vanity_y = 2.45, -3.17
    api.furniture_id = 'wash_vanity'
    api.box('vanity cabinet', (vanity_x, vanity_y, .61),
            (.78, 1.42, 1.08), 'cream', .045, True)
    api.box('vanity plinth', (vanity_x, vanity_y, .10),
            (.84, 1.46, .18), 'trim', .025, True)
    api.box('vanity countertop', (vanity_x, vanity_y, 1.18),
            (.90, 1.48, .14), 'wall', .025, True)

    # Two simple cabinet fronts face the room; their thin details stay
    # non-collidable because the cabinet body owns the obstruction.
    for index, y in enumerate((-3.53, -2.83)):
        api.box('vanity door ' + str(index), (vanity_x + .401, y, .60),
                (.025, .58, .78), 'trim', .012, False)
        api.ellipsoid('vanity pull ' + str(index),
                      (vanity_x + .435, y, .62),
                      (.035, .035, .035), 'brass', False)

    # Basin and a short faucet make the counter read as a wash station from
    # the hallway while the countertop remains the collision surface.
    api.ellipsoid('wash basin', (vanity_x, vanity_y, 1.27),
                  (.30, .40, .10), 'throw', False)
    api.cylinder('wash faucet base', (vanity_x, vanity_y - .14, 1.34),
                 .045, .06, 'brass', solid=False)
    api.rod('wash faucet', (vanity_x, vanity_y - .14, 1.36),
            (vanity_x, vanity_y + .03, 1.48), .025, 'brass', False)

    # Mirror and the small wall shelves are attached to the same west side as
    # the wall.  The cutaway system can therefore hide the entire wall group
    # together when the near side is removed.
    mirror_x, mirror_y = x0 + .068, -3.08
    api.furniture_id = 'wash_mirror'
    api.box('wash mirror', (mirror_x, mirror_y, 2.05),
            (.025, 1.34, 1.14), 'screen', .012, False, 'west')
    for index, y in enumerate((mirror_y - .68, mirror_y + .68)):
        api.box('wash mirror frame ' + str(index),
                (x0 + .045, y, 2.05),
                (.055, .055, 1.20), 'trim', .008, False, 'west')
    for z in (1.49, 2.61):
        api.box('wash mirror frame rail', (x0 + .045, mirror_y, z),
                (.055, 1.44, .055), 'trim', .008, False, 'west')
    api.furniture_id = ''
    for index, z in enumerate((1.55, 1.77)):
        api.box('wash wall shelf ' + str(index), (x0 + .10, -2.52, z),
                (.16, .46, .055), 'wood', .012, False, 'west')

