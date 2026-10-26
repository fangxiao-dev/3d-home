"""Photo-led cartoon study room.

The room stays in Blender world coordinates (Z up).  Hallway owns the north
side, so this module keeps the doorway open and leaves a straight route from
the doorway toward the south window.
"""

def build(api):
    """Build the study shell and its recognizable, low-clutter furniture."""
    x0, x1, y0, y1 = api.bounds
    height = 3.3
    xmid = (x0 + x1) / 2

    # Hallway owns the north wall and its X=6.1..7.6 opening.  The south
    # wall is rebuilt around a broad window so it does not block daylight.
    api.floor()
    api.wall('west')
    api.wall('east')

    window_left, window_right = x0 + .48, x1 - .48
    window_mid = (window_left + window_right) / 2
    window_width = window_right - window_left
    sill_height, window_top = .72, 2.78
    api.box('south lower wall', (xmid, y0, sill_height / 2),
            (x1 - x0, .12, sill_height), 'wall', .008, True, 'south')
    for x in (x0 + .24, x1 - .24):
        api.box('south window pier', (x, y0, (sill_height + window_top) / 2),
                (.48, .12, window_top - sill_height), 'wall', .008, True, 'south')
    api.box('south window lintel', (xmid, y0, (window_top + height) / 2),
            (x1 - x0, .12, height - window_top), 'wall', .008, True, 'south')
    api.box('south crown', (xmid, y0, height - .14),
            (x1 - x0, .16, .10), 'trim', .008, False, 'south')

    glass_center = (sill_height + window_top) / 2
    glass_height = window_top - sill_height - .08
    api.box('window glass', (window_mid, y0 + .018, glass_center),
            (window_width, .025, glass_height), 'window', .002, False, 'south')
    api.box('window sill', (window_mid, y0 + .10, sill_height),
            (window_width + .12, .16, .08), 'trim', .008, False, 'south')
    for x in (window_left, window_mid, window_right):
        api.box('window vertical frame', (x, y0 + .042, glass_center),
                (.045, .055, window_top - sill_height + .04),
                'frame', .003, False, 'south')
    for z in (sill_height, (sill_height + window_top) / 2, window_top):
        api.box('window horizontal frame', (window_mid, y0 + .042, z),
                (window_width + .04, .055, .045), 'frame', .003, False, 'south')
    for x in (window_left + .08, window_right - .08):
        api.box('window curtain', (x, y0 + .105, glass_center),
                (.16, .13, glass_height), 'curtain', .025, False, 'south')
    api.ceiling()

    # East-wall workstation and bookcase.  Their west edge remains beyond the
    # X=6.85 route, leaving the center open from the doorway to the window.
    desk_x, desk_y = x1 - .62, -4.82
    api.furniture_id = 'study_desk'
    desk_length = 2.90
    api.box('desk top', (desk_x, desk_y, .88),
            (1.00, desk_length, .12), 'cream', .035, True)
    for y in (desk_y - 1.08, desk_y + 1.08):
        api.box('desk pedestal', (desk_x, y, .45),
                (.70, .44, .72), 'cream', .03, True)
        api.box('desk drawer front', (desk_x - .36, y, .58),
                (.025, .34, .34), 'trim', .006, False)

    bookcase_x = x1 - .20
    api.furniture_id = 'study_bookcase'
    bookcase_y = desk_y
    bookcase_length = 3.05
    api.box('bookcase backing', (bookcase_x, bookcase_y, 1.84),
            (.16, bookcase_length, 2.12), 'cream', .018, True, 'east')
    # The real cabinet has vertical side boards at the two Y ends.  Keep their
    # X dimension as cabinet depth; a full Y-length board here would become a
    # solid front panel when viewed from the room.
    for y in (bookcase_y - bookcase_length / 2 + .055,
              bookcase_y + bookcase_length / 2 - .055):
        api.box('bookcase side panel', (x1 - .34, y, 1.84),
                (.72, .11, 2.12), 'trim', .012, True, 'east')
    # Four wider shelf boards leave three wider display bays for the important
    # objects that will later be placed here, while keeping cabinet edges.
    for z in (.80, 1.40, 2.00, 2.60):
        api.box('bookcase shelf', (x1 - .34, bookcase_y, z),
                (.72, bookcase_length - .12, .07), 'trim', .008, True, 'east')
    # A few upright blocks read as books without bringing the photographed clutter
    # into the scene.
    for z, y, mat in ((.99, -5.55, 'wood'), (.99, -5.25, 'red'),
                      (1.59, -4.42, 'green'), (1.59, -4.12, 'wood'),
                      (2.19, -5.45, 'red'), (2.19, -5.10, 'green')):
        api.box('book', (x1 - .58, y, z), (.08, .16, .31),
                mat, .006, False, 'east')

    # Simple wooden chair, facing east toward the desk.  Keep its west edge
    # clear of the one-metre-plus center route.
    chair_x, chair_y = desk_x - 1.00, desk_y + .06
    api.furniture_id = 'study_chair'
    api.box('chair seat', (chair_x, chair_y, .57),
            (.58, .58, .12), 'wood', .045, True)
    api.box('chair cushion', (chair_x + .02, chair_y, .65),
            (.47, .47, .08), 'throw', .035, False)
    api.box('chair back', (chair_x - .25, chair_y, 1.02),
            (.10, .58, .83), 'wood', .035, True)
    for x in (chair_x - .20, chair_x + .20):
        for y in (chair_y - .20, chair_y + .20):
            api.rod('chair leg', (x, y, .06), (x, y, .52),
                    .032, 'wood', False)

    # Guzheng and two trestles on the west side.  Its long axis follows the
    # room depth, opposite the desk, so it remains visible from the doorway.
    guzheng_x, guzheng_y = x0 + .72, -4.62
    api.furniture_id = 'guzheng'
    guzheng_length = 1.82
    api.box('guzheng', (guzheng_x, guzheng_y, 1.02),
            (.42, guzheng_length, .13), 'tablewood', .045, True)
    api.box('guzheng soundboard', (guzheng_x, guzheng_y, 1.095),
            (.34, guzheng_length - .12, .035), 'cream', .012, False)
    for i in range(5):
        x = guzheng_x - .12 + i * .06
        api.rod('guzheng string', (x, guzheng_y - .78, 1.12),
                (x, guzheng_y + .78, 1.12), .004, 'brass', False)
    for y in (guzheng_y - .56, guzheng_y + .56):
        api.box('guzheng stand crossbar', (guzheng_x, y, .52),
                (.54, .10, .08), 'wood', .015, False)
        for x in (guzheng_x - .20, guzheng_x + .20):
            api.rod('guzheng stand leg', (x, y, .08),
                    (x + (.12 if x < guzheng_x else -.12), y, .98),
                    .035, 'wood', False)

    # One small desk lamp preserves the photo cue while keeping the worktop
    # readable and free of loose objects.
    lamp_x, lamp_y = desk_x - .25, desk_y - 1.05
    api.furniture_id = 'study_desk'
    api.cylinder('desk lamp base', (lamp_x, lamp_y, .96),
                 .11, .04, 'brass', solid=False)
    api.rod('desk lamp stem', (lamp_x, lamp_y, .98),
            (lamp_x, lamp_y, 1.23), .018, 'brass', False)
    api.ellipsoid('desk lamp shade', (lamp_x, lamp_y, 1.29),
                  (.15, .11, .07), 'bulb', False)

