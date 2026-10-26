"""Photo-led cartoon balcony with a clear route from the living room.

The balcony is open on its south edge.  The west side carries the compact
laundry cabinet, while the north, west, and east boundaries use glazed window
assemblies so the room reads as a bright corner balcony without losing a
solid outer boundary for collision.
"""


def build(api):
    """Populate the balcony through the shared room geometry adapter."""

    x0, x1, y0, y1 = api.bounds
    height = 3.30
    sill = 0.64
    window_top = 2.82
    glass_z = (sill + window_top) / 2
    glass_h = window_top - sill - 0.08

    # South is deliberately omitted: the living room owns that edge and the
    # centre route stays open all the way to the north windows.
    api.floor()
    api.ceiling()

    # North glazing replaces a solid wall.  The low wall, piers, lintel, and
    # solid glass panels preserve the room boundary for the player.
    north_mid = (x0 + x1) / 2
    api.box('north lower wall', (north_mid, y1, sill / 2),
            (x1 - x0, .12, sill), 'wall', .008, True, 'north')
    api.box('north lintel', (north_mid, y1, (window_top + height) / 2),
            (x1 - x0, .12, height - window_top), 'wall', .008, True, 'north')
    north_left, north_right = x0 + .46, x1 - .46
    for x in (x0 + .23, x1 - .23):
        api.box('window north pier', (x, y1, glass_z),
                (.46, .12, window_top - sill), 'wall', .008, True, 'north')
    north_edges = (north_left, -1.22, 0.0, 1.22, north_right)
    for index, (a, b) in enumerate(zip(north_edges[:-1], north_edges[1:])):
        api.box('window north glass ' + str(index),
                ((a + b) / 2, y1 + .012, glass_z),
                (b - a - .08, .025, glass_h), 'window', .002,
                True, 'north')
    for index, x in enumerate(north_edges):
        api.box('window north vertical frame ' + str(index),
                (x, y1 - .035, glass_z),
                (.045, .055, window_top - sill + .04),
                'frame', .003, False, 'north')
    for index, z in enumerate((sill, (sill + window_top) / 2, window_top)):
        api.box('window north horizontal frame ' + str(index),
                (north_mid, y1 - .035, z),
                (north_right - north_left + .08, .055, .045),
                'frame', .003, False, 'north')
    api.box('window north sill', (north_mid, y1 - .09, sill),
            (north_right - north_left + .16, .16, .08),
            'trim', .008, False, 'north')
    api.box('north crown', (north_mid, y1, height - .14),
            (x1 - x0, .16, .10), 'trim', .008, False, 'north')

    # The two side faces use the same glazed construction.  Their solid lower
    # wall, corner piers, lintel, and glass keep the balcony perimeter closed.
    side_mid = (y0 + y1) / 2
    side_left, side_right = y0 + .32, y1 - .32
    side_edges = (side_left, 6.90, side_right)
    for side, x in (('west', x0), ('east', x1)):
        api.box(side + ' lower wall', (x, side_mid, sill / 2),
                (.12, y1 - y0, sill), 'wall', .008, True, side)
        api.box(side + ' lintel', (x, side_mid, (window_top + height) / 2),
                (.12, y1 - y0, height - window_top),
                'wall', .008, True, side)
        for y in (y0 + .16, y1 - .16):
            api.box('window ' + side + ' pier', (x, y, glass_z),
                    (.12, .32, window_top - sill),
                    'wall', .008, True, side)
        for index, (a, b) in enumerate(zip(side_edges[:-1], side_edges[1:])):
            api.box('window ' + side + ' glass ' + str(index),
                    (x, (a + b) / 2, glass_z),
                    (.025, b - a - .08, glass_h),
                    'window', .002, True, side)
        for index, y in enumerate(side_edges):
            api.box('window ' + side + ' vertical frame ' + str(index),
                    (x + (-.035 if side == 'west' else .035), y, glass_z),
                    (.055, .045, window_top - sill + .04),
                    'frame', .003, False, side)
        for index, z in enumerate((sill, (sill + window_top) / 2, window_top)):
            api.box('window ' + side + ' horizontal frame ' + str(index),
                    (x + (-.035 if side == 'west' else .035), side_mid, z),
                    (.055, side_right - side_left + .08, .045),
                    'frame', .003, False, side)
        api.box('window ' + side + ' sill',
                (x + (-.09 if side == 'west' else .09), side_mid, sill),
                (.16, side_right - side_left + .16, .08),
                'trim', .008, False, side)
        api.box(side + ' crown', (x, side_mid, height - .14),
                (.16, y1 - y0, .10), 'trim', .008, False, side)

    # The fitted utility group follows the west wall.  Its working faces point
    # inward (+X), leaving the south opening and the centre route clear.
    cabinet_x = x0 + .44
    cabinet_y = y0 + .98
    cabinet_back_x = x0 + .08
    sink_y = cabinet_y - .41
    washer_y = cabinet_y + .41
    api.box('laundry backsplash', (cabinet_back_x, cabinet_y, 1.52),
            (.06, 1.72, .88), 'tile', .004, False, 'west')

    # Lower cabinet and wash basin.
    api.furniture_id = 'balcony_wash_basin'
    api.box('wash basin cabinet', (cabinet_x, sink_y, .43),
            (.72, .74, .78), 'cream', .035, True)
    api.box('wash basin counter', (cabinet_x, cabinet_y, .98),
            (.82, 1.66, .14), 'trim', .025, True)
    api.box('wash basin', (cabinet_x + .02, sink_y, 1.055),
            (.50, .52, .095), 'cream', .025, False)
    api.box('wash basin inner', (cabinet_x + .02, sink_y, 1.10),
            (.38, .40, .035), 'screen', .022, False)
    api.rod('wash basin faucet', (cabinet_x - .18, sink_y, 1.08),
            (cabinet_x - .18, sink_y, 1.36), .025, 'brass', False)
    api.rod('wash basin faucet spout', (cabinet_x - .18, sink_y, 1.35),
            (cabinet_x - .03, sink_y, 1.35), .022, 'brass', False)
    for index, y in enumerate((sink_y - .18, sink_y + .18)):
        api.box('wash basin cabinet door ' + str(index),
                (cabinet_x + .371, y, .43), (.025, .32, .58),
                'trim', .008, False)
        api.ellipsoid('wash basin cabinet pull ' + str(index),
                      (cabinet_x + .405, y, .46), (.025, .035, .035),
                      'brass', False)

    # Front-loading washer sits beside the basin beneath the same counter;
    # every face detail shares the same inward (+X) orientation.
    api.furniture_id = 'balcony_washing_machine'
    api.box('washing machine body', (cabinet_x, washer_y, .53),
            (.72, .76, 1.00), 'cream', .035, True)
    api.box('washing machine control panel',
            (cabinet_x + .371, washer_y, .91), (.035, .70, .17),
            'screen', .012, False)
    api.ellipsoid('washing machine dial',
                  (cabinet_x + .405, washer_y + .24, .92),
                  (.024, .045, .045), 'brass', False)
    api.ellipsoid('washing machine door rim',
                  (cabinet_x + .385, washer_y, .53),
                  (.045, .29, .29), 'trim', False)
    api.ellipsoid('washing machine door glass',
                  (cabinet_x + .43, washer_y, .53),
                  (.032, .235, .235), 'black', False)

    # Upper laundry cupboards and the open shelf visible in the reference.
    api.furniture_id = 'balcony_upper_cabinet'
    upper_z = 2.46
    api.box('laundry upper cabinet', (cabinet_x, cabinet_y, upper_z),
            (.66, 1.66, .70), 'cream', .035, True)
    for index, y in enumerate((cabinet_y - .53, cabinet_y, cabinet_y + .53)):
        api.box('laundry upper door ' + str(index),
                (cabinet_x + .341, y, upper_z), (.025, .48, .58),
                'trim', .008, False)
        api.ellipsoid('laundry upper pull ' + str(index),
                      (cabinet_x + .375, y + .16, upper_z - .02),
                      (.025, .035, .035), 'brass', False)
    api.furniture_id = 'balcony_laundry_shelf'
    api.box('laundry open shelf', (cabinet_x, cabinet_y, 1.76),
            (.62, 1.62, .08), 'trim', .015, True)
    api.box('laundry shelf back', (cabinet_x - .34, cabinet_y, 1.97),
            (.06, 1.62, .42), 'wall', .004, False, 'west')

    # A minimal empty overhead drying rack keeps the photo cue while leaving
    # the floor route completely free.  The rods are ceiling attachments.
    api.furniture_id = ''
    rack_z = 2.88
    rack_front_y, rack_back_y = 6.58, 7.04
    rack_left, rack_right = -.92, 2.28
    for y in (rack_front_y, rack_back_y):
        api.rod('drying rack rail', (rack_left, y, rack_z),
                (rack_right, y, rack_z), .025, 'brass', False, 'top')
    for x in (rack_left + .16, rack_right - .16):
        api.rod('drying rack support', (x, rack_front_y, rack_z),
                (x, rack_back_y, rack_z), .02, 'brass', False, 'top')
        api.rod('drying rack ceiling drop', (x, rack_front_y, rack_z),
                (x, rack_front_y, 2.72), .018, 'brass', False, 'top')
