"""Godot-only field-worker adapters, used exclusively in background exports.

Native sprite recipes, rigs, saved scenes and simulation rules stay intact.
"""
import math

def install_skinning():
    """Evaluate the same authored weights without allocating every bone/vertex pair.

    Scoped to these background field-worker exports; the source kit is untouched.
    """
    import numpy as np
    import human
    def deform(part, R, T):
        if not hasattr(part, '_field_weights'):
            part._field_weights = [(bone, np.flatnonzero(part.W[:, bone])) for bone in range(part.W.shape[1])]
        out = np.zeros_like(part.rest)
        for bone, indices in part._field_weights:
            if len(indices):
                out[indices] += (part.rest[indices] @ R[bone].T + T[bone]) * part.W[indices, bone, None]
        if not hasattr(part, '_field_verified'):
            indices = np.linspace(0, len(part.rest)-1, min(128, len(part.rest)), dtype=int)
            reference = np.einsum('nb,nbi->ni', part.W[indices], np.einsum('bij,nj->nbi', R, part.rest[indices]) + T[None])
            if not np.allclose(out[indices], reference, rtol=1e-12, atol=1e-12):
                raise RuntimeError('Field export skinning differs from authored skinning')
            part._field_verified = True
        if part.floor is not None:
            out[:, 2] = np.maximum(out[:, 2], part.floor)
        part.ob.data.vertices.foreach_set('co', out.ravel())
        part.ob.data.update()
    human.Skinned.deform = deform

CLIPS = {
    'walker_hunter': [('collect','hunt',24),('carry','carry',12),('die','die',8)],
    'walker_deerhunter': [('collect','hunt',24),('carry','carry',12),('die','die',8)],
    'walker_shepherd': [('collect','shear',24),('fight','groom',24),('carry','carry',12),('die','die',8)],
    'walker_goatherd': [('collect','milk',24),('fight','groom',24),('carry','carry',12),('die','die',8)],
    'walker_grower': [('workgrapes','prunegrapes',24),('workolives','pruneolives',24),
                      ('collectgrapes','pickgrapes',24),('collectolives','pickolives',24),('die','die',8)],
    'walker_orangetender': [('workontree','pruneoranges',24),('collect','pickoranges',24),('die','die',8)],
    # Work clips the people kit authored for the SDL sprites but Godot never showed (5 October): the firefighter's
    # bucket run and throw, the lumberjack's chop, the miners' pick, the quarryman's cut, the artisan's building work.
    'walker_firefighter': [('carry','carry',12),('putout','putout',24),('die','die',8)],
    'walker_lumberjack': [('collect','chop',24),('carry','carry',12),('die','die',8)],
    'walker_bronzeminer': [('collect','mine',24),('carry','carry',12),('die','die',8)],
    'walker_silverminer': [('collect','mine',24),('carry','carry',12),('die','die',8)],
    'walker_orichalcminer': [('collect','mine',24),('carry','carry',12),('die','die',8)],
    'walker_marbleminer': [('collect','quarry',24),('die','die',8)],
    'walker_artisan': [('build','build',24),('buildstanding','buildstand',24),('die','die',8)],
}

def adapt(namespace, name, K):
    """Add hand-anchored shears, or a guiding crook for the corral worker."""
    from person_kit import Prop, walk, staff, lin
    h = namespace['spec']['h']
    states = namespace['STATES']
    if name == 'walker_hunter':
        # The sprite-sized boar sits inside the 3D cloak. Raise and widen it onto
        # the shoulders so the return load has a clear silhouette at city zoom.
        carry = next(fn for state,_,_,fn,_ in states if state=='carry')
        game = carry.__closure__[carry.__code__.co_freevars.index('game')].cell_contents
        def carry_visible(frame):
            carry(frame)
            game.root.scale = (.70,)*3
            game.root.location.z += .12
        namespace['STATES'] = [(state,count,heads,carry_visible if state=='carry' else fn,loop) for state,count,heads,fn,loop in states]
        states = namespace['STATES']
    if name == 'walker_shepherd':
        iron = K.material('Field shears iron',lin((.35,.38,.40)),rough=.35,metal=.7)
        spring = K.curve('Shears spring',[(0,0,0),(.018,0,-.025),(.036,0,0)],.003,iron)
        blades = [K.rod('Shears blade',(.018,0,0),(.018+s*.013,.09,0),.0035,iron,n=6) for s in [-1,1]]
        shears = Prop(h,[spring]+blades)
        wrapped = []
        for state,count,heads,fn,loop in states:
            def sample(frame, fn=fn, state=state, count=count):
                fn(frame)
                shears.place(h.hands[1],(-.15,0,.10),visible=state=='collect')
                for i,blade in enumerate(blades):
                    blade.rotation_euler.z = (1 if i else -1)*.11*math.sin(math.tau*frame/count*3)
            wrapped.append((state,count,heads,sample,loop))
        namespace['STATES'] = wrapped
    if name == 'walker_rancher':
        original = states[0][3]
        closure = dict(zip(original.__code__.co_freevars,[cell.cell_contents for cell in original.__closure__]))
        spear = closure['sp']
        crook = staff(K,h,.84,crook=True)
        def sample(frame, leading=False):
            original(0)
            ph, hands = walk(h,frame,N=24,lean=.025,hands=lambda ph: {
                1:(.16,.10-.025*math.cos(ph),.47),
                -1:(-.12,.23,.54+.018*math.sin(ph)) if leading else (-.15,.05+.07*math.cos(ph),.41)})
            for ob in spear.obs: ob.hide_render=True
            crook.place(hands[1],(-.08+.06*math.cos(ph),0,0))
        namespace['STATES'] = [('walk',24,8,sample,True),('lead',24,8,lambda f:sample(f,True),True)]
    return namespace['STATES']

def clips(states, name):
    recipes = CLIPS.get(name, [('lead','lead',24)] if name=='walker_rancher' else [])
    source = {label:(count,fn) for label,count,_,fn,_ in states}
    result = []
    for source_name,label,count in recipes:
        native_count,fn = source[source_name]
        if label=='putout':
            # The engine plays the 40-frame throw forwards then backwards; one 24-sample clip holds both halves, so it loops.
            callback=lambda frame,fn=fn,n=native_count,c=count:fn((n-1)*(1-abs(1-2*frame/c)))
        elif label=='die':
            callback=lambda frame,fn=fn,n=native_count,c=count:fn(frame*(n-1)/(c-1))
        else:
            callback=lambda frame,fn=fn,n=native_count,c=count:fn(frame*n/c)
        result.append((label,count,callback))
    return result
