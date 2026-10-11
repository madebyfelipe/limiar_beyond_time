"""GLB -> OBJ+MTL (rest pose) for Mixamo auto-rigging. Pure stdlib."""
import json, struct, sys, math, os, zipfile

src, outdir = sys.argv[1], sys.argv[2]
d = open(src, 'rb').read()
total = struct.unpack('<III', d[:12])[2]
off, chunks = 12, []
while off < total:
    clen, ctype = struct.unpack('<II', d[off:off+8])
    chunks.append((ctype, d[off+8:off+8+clen])); off += 8 + clen
j = json.loads(chunks[0][1].decode('utf-8'))
bin_ = chunks[1][1]

def view(i):
    bv = j['bufferViews'][i]
    o = bv.get('byteOffset', 0)
    return bin_[o:o + bv['byteLength']]

CT = {5120: ('b', 1), 5121: ('B', 1), 5122: ('h', 2), 5123: ('H', 2), 5125: ('I', 4), 5126: ('f', 4)}
NC = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}

def read(ai):
    a = j['accessors'][ai]
    fmt, size = CT[a['componentType']]; n = NC[a['type']]
    bv = j['bufferViews'][a['bufferView']]
    base = bv.get('byteOffset', 0) + a.get('byteOffset', 0)
    stride = bv.get('byteStride') or size * n
    out = []
    for k in range(a['count']):
        o = base + k * stride
        out.append(struct.unpack_from('<' + fmt * n, bin_, o))
    return out

nodes = j['nodes']
parent = {}
for i, n in enumerate(nodes):
    for c in n.get('children', []):
        parent[c] = i

def ident(): return [[1.0 if r == c else 0.0 for c in range(4)] for r in range(4)]
def mul(a, b): return [[sum(a[r][k]*b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]
def local(n):
    if 'matrix' in n:
        m = n['matrix']; return [[m[c*4+r] for c in range(4)] for r in range(4)]
    t = n.get('translation', [0, 0, 0]); q = n.get('rotation', [0, 0, 0, 1]); s = n.get('scale', [1, 1, 1])
    x, y, z, w = q
    R = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
         [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
         [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    m = ident()
    for r in range(3):
        for c in range(3):
            m[r][c] = R[r][c] * s[c]
        m[r][3] = t[r]
    return m
def glob(i):
    m = local(nodes[i]); k = i
    while k in parent:
        k = parent[k]; m = mul(local(nodes[k]), m)
    return m

mesh_node = next(i for i, n in enumerate(nodes) if 'mesh' in n)
M = glob(mesh_node)
# Face +X source -> +Z for Mixamo's viewer: rotate -90 deg about Y.
c, s = math.cos(-math.pi/2), math.sin(-math.pi/2)
Ry = [[c, 0, s, 0], [0, 1, 0, 0], [-s, 0, c, 0], [0, 0, 0, 1]]
M = mul(Ry, M)

def xf(v, w):
    return tuple(M[r][0]*v[0] + M[r][1]*v[1] + M[r][2]*v[2] + M[r][3]*w for r in range(3))

prim = j['meshes'][0]['primitives'][0]
pos = read(prim['attributes']['POSITION'])
nrm = read(prim['attributes']['NORMAL'])
uv = read(prim['attributes']['TEXCOORD_0'])
idx = [i[0] for i in read(prim['indices'])]

# Ground the model: feet on y=0, centred on x/z, so the auto-rigger sees a clean stance.
P = [xf(v, 1.0) for v in pos]
minx = min(p[0] for p in P); maxx = max(p[0] for p in P)
minz = min(p[2] for p in P); maxz = max(p[2] for p in P)
miny = min(p[1] for p in P)
shift = (-(minx + maxx) / 2.0, -miny, -(minz + maxz) / 2.0)
P = [(p[0] + shift[0], p[1] + shift[1], p[2] + shift[2]) for p in P]
N = [xf(n, 0.0) for n in nrm]

img = j['images'][0]
tex = 'dylan_color.jpg'
os.makedirs(outdir, exist_ok=True)
open(os.path.join(outdir, tex), 'wb').write(view(img['bufferView']))

name = 'dylan'
with open(os.path.join(outdir, name + '.mtl'), 'w') as f:
    f.write("newmtl dylan_mat\nKa 1 1 1\nKd 1 1 1\nKs 0 0 0\nd 1\nillum 2\nmap_Kd %s\n" % tex)
with open(os.path.join(outdir, name + '.obj'), 'w') as f:
    f.write("# Dylan rest pose, exported from model-rigged.glb\nmtllib %s.mtl\no dylan\n" % name)
    for v in pos:
        f.write("v %.6f %.6f %.6f\n" % xf(v, 1.0))
    for n in nrm:
        f.write("vn %.6f %.6f %.6f\n" % xf(n, 0.0))
    for t in uv:
        f.write("vt %.6f %.6f\n" % (t[0], 1.0 - t[1]))
    f.write("usemtl dylan_mat\ns 1\n")
    for k in range(0, len(idx), 3):
        a, b, cc = idx[k] + 1, idx[k+1] + 1, idx[k+2] + 1
        f.write("f %d/%d/%d %d/%d/%d %d/%d/%d\n" % (a, a, a, b, b, b, cc, cc, cc))

zp = os.path.join(outdir, 'dylan_mixamo.zip')
with zipfile.ZipFile(zp, 'w', zipfile.ZIP_DEFLATED) as z:
    for fn in (name + '.obj', name + '.mtl', tex):
        z.write(os.path.join(outdir, fn), fn)
ys = [p[1] for p in P]
print("verts %d tris %d  height %.4f (y %.4f..%.4f)" % (len(pos), len(idx)//3, max(ys)-min(ys), min(ys), max(ys)))
print("zip:", zp, os.path.getsize(zp), "bytes")
