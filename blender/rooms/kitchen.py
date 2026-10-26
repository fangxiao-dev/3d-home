"""Photo-led, display-only kitchen in Blender world coordinates.

The kitchen is a shallow room at the south end of the dining room.  Its
north edge is owned by dining, so the only north-side geometry here is the
closed, glazed entrance.  The fitted cabinets stay on the perimeter and keep
the view from the dining room open to the cooktop, sink, corner worktop, and
window.
"""


def _entrance_glass_material(api):
    """Create the low-alpha material used by the closed kitchen entrance."""
    material = api.env['material'](
        'Kitchen entrance glass', (.68, .82, .80), .20, 0.0, .05
    )
    rgba = (.68, .82, .80, .15)
    material.diffuse_color = rgba
    material.use_nodes = True
    nodes = getattr(material, 'node_tree', None)
    principled = nodes.nodes.get('Principled BSDF') if nodes else None
    if principled is not None:
        principled.inputs['Base Color'].default_value = rgba
        principled.inputs['Alpha'].default_value = .15
    # Blender 4.5 renamed the material blend setting.  DITHERED is the
    # exporter-compatible transparent surface mode for this low-alpha pane.
    try:
        material.surface_render_method = 'DITHERED'
    except (AttributeError, TypeError):
        pass
    material['gltf_alpha_mode'] = 'BLEND'
    material['alpha'] = .15
    api.m['glass'] = material
    return material


def _lower_cabinet(api, name, center, size, front):
    """Add one collision-owning base cabinet and its light visual details."""
    x, y = center
    width, depth = size
    api.box(name + ' body', (x, y, .50), (width, depth, .80),
            'cream', .035, True)
    api.box(name + ' plinth', (x, y, .09),
            (width + .04, depth + .04, .16), 'trim', .018, True)
    api.box(name + ' countertop', (x, y, .96),
            (width + .10, depth + .08, .14), 'trim', .025, True)

    # Fronts are visual panels; the body is the only meaningful obstruction.
    if front == 'east':
        panel_loc = (x + width / 2 + .012, y, .52)
        panel_size = (.024, depth - .08, .62)
        pull_loc = (x + width / 2 + .035, y, .54)
    elif front == 'west':
        panel_loc = (x - width / 2 - .012, y, .52)
        panel_size = (.024, depth - .08, .62)
        pull_loc = (x - width / 2 - .035, y, .54)
    else:
        panel_loc = (x, y + depth / 2 + .012, .52)
        panel_size = (width - .08, .024, .62)
        pull_loc = (x, y + depth / 2 + .035, .54)
    api.box(name + ' front', panel_loc, panel_size,
            'trim', .010, False)
    api.ellipsoid(name + ' pull', pull_loc, (.035, .035, .035),
                  'brass', False)


def _upper_cabinet(api, name, center, size, front):
    """Add a compact upper cupboard, keeping its wall-side detail shallow."""
    x, y = center
    width, depth = size
    side = 'west' if front == 'east' else 'east'
    previous_id = api.furniture_id
    api.furniture_id = f'kitchen_{side}_upper_cabinet'
    parts = [api.box(name + ' body', (x, y, 2.33), (width, depth, .72),
                     'cream', .035, True, side)]
    if front == 'east':
        panel_loc = (x + width / 2 + .012, y, 2.33)
        panel_size = (.024, depth - .06, .62)
        pull_loc = (x + width / 2 + .035, y, 2.18)
    else:
        panel_loc = (x - width / 2 - .012, y, 2.33)
        panel_size = (.024, depth - .06, .62)
        pull_loc = (x - width / 2 - .035, y, 2.18)
    parts.append(api.box(name + ' door', panel_loc, panel_size,
                         'trim', .010, False, side))
    parts.append(api.ellipsoid(name + ' pull', pull_loc, (.035, .035, .035),
                              'brass', False, side))
    for part in parts:
        part['wall_mounted'] = True
    api.furniture_id = previous_id


def build(api):
    """Build the closed entrance and recognizable kitchen work zones."""
    x0, x1, y0, y1 = api.bounds
    height = 3.30

    # Dining owns the north boundary.  A south opening lets the custom window
    # assembly replace the central wall span while retaining solid wall and
    # shell collision around it.
    api.shell({
        'west': (),
        'east': (),
        'south': ((-1.90, 1.25),),
    })

    # The kitchen is display-only: the portal is visually transparent but a
    # solid pane closes the whole dining-to-kitchen opening.
    glass = _entrance_glass_material(api)
    entrance_left, entrance_right = -1.70, .90
    entrance_y = y1
    entrance_bottom, entrance_top = .06, 2.78
    entrance_mid = (entrance_bottom + entrance_top) / 2
    api.box('entrance glass',
            ((entrance_left + entrance_right) / 2, entrance_y + .018,
             entrance_mid),
            (entrance_right - entrance_left, .025,
             entrance_top - entrance_bottom),
            'glass', .002, True, 'north')

    # Pale metal perimeter and a restrained grid echo the photographed glass
    # door without turning the threshold into visual clutter.
    frame_y = entrance_y + .045
    for x in (entrance_left, entrance_right):
        api.box('entrance metal frame upright', (x, frame_y, 1.42),
                (.055, .08, 2.84), 'trim', .008, False, 'north')
    for z in (entrance_bottom, entrance_top):
        api.box('entrance metal frame rail',
                ((entrance_left + entrance_right) / 2, frame_y, z),
                (entrance_right - entrance_left + .055, .08, .055),
                'trim', .008, False, 'north')
    api.box('entrance metal frame mullion',
            ((entrance_left + entrance_right) / 2, frame_y, entrance_mid),
            (.035, .065, entrance_top - entrance_bottom),
            'trim', .006, False, 'north')
    for x in (-.83, .03):
        api.box('entrance metal frame crossbar', (x, frame_y, 1.40),
                (.035, .065, 2.58), 'trim', .006, False, 'north')

    # South window: lower wall, corner piers, and a bright glazed pane preserve
    # a real boundary for the room while giving the kitchen its daylight cue.
    window_left, window_right = -1.82, 1.17
    sill, window_top = .70, 2.73
    window_mid = (sill + window_top) / 2
    window_width = window_right - window_left
    api.box('south window lower wall', ((window_left + window_right) / 2,
                                       y0, sill / 2),
            (window_width, .12, sill), 'wall', .008, True, 'south')
    for x in (window_left, window_right):
        api.box('south window pier', (x, y0, window_mid),
                (.12, .12, window_top - sill), 'wall', .008, True, 'south')
    api.box('south window glass', ((window_left + window_right) / 2,
                                  y0 + .018, window_mid),
            (window_width - .16, .025, window_top - sill - .08),
            'window', .002, True, 'south')
    for x in (window_left + .06, (window_left + window_right) / 2,
              window_right - .06):
        api.box('south window vertical frame', (x, y0 + .045, window_mid),
                (.045, .055, window_top - sill + .04),
                'frame', .003, False, 'south')
    for z in (sill, window_mid, window_top):
        api.box('south window horizontal frame',
                ((window_left + window_right) / 2, y0 + .045, z),
                (window_width + .04, .055, .045),
                'frame', .003, False, 'south')
    api.box('south window sill', ((window_left + window_right) / 2,
                                 y0 + .10, sill),
            (window_width + .16, .16, .08), 'trim', .008, False, 'south')

    # West and east fitted runs leave the center approach legible from dining.
    west_center = (x0 + .36, -8.03)
    east_center = (x1 - .36, -8.03)
    api.furniture_id = 'kitchen_cabinet'
    _lower_cabinet(api, 'west lower cabinet', west_center, (.62, 1.62),
                   'east')
    _lower_cabinet(api, 'east lower cabinet', east_center, (.62, 1.62),
                   'west')
    _upper_cabinet(api, 'west upper cabinet', (x0 + .36, -7.76),
                   (.62, 1.05), 'east')
    _upper_cabinet(api, 'east upper cabinet', (x1 - .36, -7.76),
                   (.62, 1.05), 'west')

    # Light tile strips make the side runs read as a fitted kitchen without
    # carrying the photographed loose containers into the scene.
    api.furniture_id = ''
    api.box('west backsplash', (x0 + .082, -8.03, 1.42),
            (.045, 1.62, .72), 'tile', .004, False, 'west')
    api.box('east backsplash', (x1 - .082, -8.03, 1.42),
            (.045, 1.62, .72), 'tile', .004, False, 'east')

    # The far run joins both side counters at the south wall, forming the
    # photographed U-shaped worktop and leaving the entrance sightline clear.
    api.furniture_id = 'kitchen_cabinet'
    api.box('south lower cabinet', (-.35, y0 + .36, .50),
            (3.72, .62, .80), 'cream', .035, True)
    api.box('south cabinet plinth', (-.35, y0 + .36, .09),
            (3.76, .66, .16), 'trim', .018, True)
    api.box('south countertop', (-.35, y0 + .36, .96),
            (3.82, .72, .14), 'trim', .025, True)
    api.box('corner countertop west', (x0 + .42, y0 + .40, 1.02),
            (.72, .70, .13), 'trim', .025, True)
    api.box('corner countertop east', (x1 - .42, y0 + .40, 1.02),
            (.72, .70, .13), 'trim', .025, True)
    api.box('corner countertop', (x1 - .54, y0 + .37, 1.04),
            (.62, .68, .12), 'trim', .025, True)

    for index, x in enumerate((-.98, -.18, .62)):
        api.box('south lower cabinet door ' + str(index),
                (x, y0 + .675, .52), (.70, .024, .62),
                'trim', .010, False)
        api.ellipsoid('south lower cabinet pull ' + str(index),
                      (x, y0 + .715, .55), (.035, .035, .035),
                      'brass', False)

    # Two-burner black cooktop and a simple oven face identify the south run.
    stove_x, stove_y = -.92, y0 + .36
    api.box('cooktop', (stove_x, stove_y, 1.045),
            (1.14, .47, .035), 'black', .012, False)
    for index, x in enumerate((stove_x - .28, stove_x + .28)):
        api.cylinder('cooktop burner ' + str(index),
                     (x, stove_y, 1.075), .15, .018,
                     'brass', solid=False)
        api.cylinder('cooktop inner burner ' + str(index),
                     (x, stove_y, 1.087), .075, .020,
                     'black', solid=False)
    api.box('oven face', (stove_x, y0 + .695, .53),
            (1.04, .025, .60), 'black', .018, False)
    api.box('oven handle', (stove_x, y0 + .735, .80),
            (.66, .045, .055), 'trim', .015, False)
    for x in (stove_x - .30, stove_x, stove_x + .30):
        api.ellipsoid('oven knob', (x, y0 + .75, .92),
                      (.035, .025, .035), 'brass', False)
    # The window sits behind the hob; the flue reaches its solid upper lintel.
    previous_id=api.furniture_id;api.furniture_id='kitchen_range_hood'
    hood_parts=[
        api.box('range hood', (stove_x, y0 + .36, 1.83),
                (1.18, .42, .16), 'trim', .025, True, 'south'),
        api.box('range hood underside', (stove_x, y0 + .47, 1.75),
                (.86, .12, .035), 'black', .008, False, 'south'),
        api.box('range hood rear housing', (stove_x, y0 + .08, 1.82),
                (.84, .20, .22), 'trim', .015, True, 'south'),
        api.box('range hood wall flue', (stove_x, y0 + .08, 2.13),
                (.48, .20, .64), 'trim', .015, True, 'south'),
    ]
    for part in hood_parts:part['wall_mounted']=True
    api.furniture_id=previous_id

    # A compact sink and arched faucet sit on the east run, facing the open
    # aisle and matching the reference's right-hand corner station.
    sink_x, sink_y = east_center[0], -8.38
    api.box('sink rim', (sink_x, sink_y, 1.045),
            (.44, .58, .055), 'trim', .025, False)
    api.box('sink basin', (sink_x, sink_y, 1.02),
            (.34, .45, .10), 'screen', .025, False)
    api.box('sink basin inner', (sink_x, sink_y, 1.075),
            (.25, .34, .025), 'black', .012, False)
    api.rod('sink faucet stem', (sink_x, sink_y + .12, 1.08),
            (sink_x, sink_y + .12, 1.39), .025, 'brass', False)
    api.rod('sink faucet spout', (sink_x, sink_y + .12, 1.39),
            (sink_x - .12, sink_y - .01, 1.39), .022, 'brass', False)
    api.cylinder('sink faucet base', (sink_x, sink_y + .12, 1.08),
                 .045, .06, 'brass', solid=False)

    # Side-mounted upper units and the hood stop below the window's visual
    # centre, so the glass and the main work zones remain readable from dining.
    previous_id = api.furniture_id
    for side, x in [('west', x0 + .675), ('east', x1 - .675)]:
        api.furniture_id = f'kitchen_{side}_upper_cabinet'
        part = api.box('upper cabinet side trim ' + side, (x, -7.76, 2.33),
                       (.035, 1.10, .76), 'trim', .008, False, side)
        part['wall_mounted'] = True
    api.furniture_id = previous_id

