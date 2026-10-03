#!/usr/bin/env python3
"""Headless PICO-8 emulation for testing parkour.p8 without PICO-8.

Runs the cart's Lua (PICO-8 syntax translated to Lua 5.4) inside lupa,
implements the subset of the PICO-8 API the cart uses, renders the
128x128 framebuffer and can save PNG screenshots. Also counts Lua VM
instructions per frame as a rough CPU-cost estimate.

    from sim import Pico
    pc = Pico("parkour.p8")
    pc.press("z"); pc.run(60, hold="up")
    pc.shot("out.png")
"""
import math, os, re, sys

from lupa import lua54 as lupa

SHRINKO = os.environ.get("SHRINKO8", "/tmp/shrinko8")
sys.path.insert(0, SHRINKO)
try:
    from pico_defs import to_p8str, k_palette
    PALETTE = [tuple(c)[:3] for c in k_palette][:16]
except Exception:  # pragma: no cover
    to_p8str = None
    PALETTE = None
if not PALETTE:
    PALETTE = [(0, 0, 0), (29, 43, 83), (126, 37, 83), (0, 135, 81),
               (171, 82, 54), (95, 87, 79), (194, 195, 199), (255, 241, 232),
               (255, 0, 77), (255, 163, 0), (255, 236, 39), (0, 228, 54),
               (41, 173, 255), (131, 118, 156), (255, 119, 168), (255, 204, 170)]

BUTTONS = {"left": 0, "right": 1, "up": 2, "down": 3, "z": 4, "x": 5}

# ---------------------------------------------------------------- lua prep
TOKEN_RE = re.compile(r"""
 (?P<ws>\s+)|
 (?P<comment>--\[(?P<eq>=*)\[.*?\](?P=eq)\]|--[^\n]*)|
 (?P<lstr>\[(?P<eq2>=*)\[.*?\](?P=eq2)\])|
 (?P<str>"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')|
 (?P<num>0[xX][0-9a-fA-F.]+|0[bB][01.]+|\d+\.?\d*(?:[eE][-+]?\d+)?|\.\d+)|
 (?P<name>[A-Za-z_][A-Za-z_0-9]*)|
 (?P<op>\.\.\.|\.\.=|\.\.|==|~=|!=|<=|>=|\+=|-=|\*=|/=|%=|\^=|<<|>>|//|[-+*/%^#<>=(){}\[\];:,.&|~\\@?])
""", re.S | re.X)

BINOPS = {"+", "-", "*", "/", "%", "^", "..", "==", "~=", "!=", "<", ">", "<=",
          ">=", "and", "or", "&", "|", "<<", ">>", "//", "\\", "~"}
UNOPS = {"-", "not", "#", "~"}


def tokenize(src):
    toks, i = [], 0
    while i < len(src):
        m = TOKEN_RE.match(src, i)
        if not m:
            raise SyntaxError("bad char at %d: %r" % (i, src[i:i + 20]))
        kind = m.lastgroup
        if kind == "eq":
            kind = "comment"
        if kind == "eq2":
            kind = "lstr"
        if kind not in ("ws", "comment"):
            toks.append([kind, m.group(), m.start(), m.end()])
        i = m.end()
    return toks


def skip_group(toks, i):
    """toks[i] is an opening bracket; return index after its match."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    depth = 0
    while True:
        t = toks[i][1]
        if t in pairs:
            depth += 1
        elif t in pairs.values():
            depth -= 1
            if depth == 0:
                return i + 1
        i += 1


def skip_expr(toks, i):
    """Return index just past the expression starting at toks[i]."""
    while True:
        while toks[i][1] in UNOPS and toks[i][0] in ("op", "name"):
            i += 1
        t = toks[i]
        if t[1] in ("(", "{"):
            i = skip_group(toks, i)
        elif t[1] == "function":
            depth, i = 1, i + 1
            while depth:
                w = toks[i][1]
                if w in ("function", "do", "if", "repeat") and toks[i][0] == "name":
                    depth += 1
                elif w in ("end", "until") and toks[i][0] == "name":
                    depth -= 1
                i += 1
        else:
            i += 1
        # suffixes
        while i < len(toks):
            t = toks[i]
            if t[1] in (".", ":"):
                i += 2
            elif t[1] in ("[", "("):
                i = skip_group(toks, i)
            elif t[1] == "{" or t[0] in ("str", "lstr"):
                i = skip_group(toks, i) if t[1] == "{" else i + 1
            else:
                break
        if i < len(toks) and toks[i][1] in BINOPS and toks[i][0] in ("op", "name"):
            i += 1
            continue
        return i


def lhs_start(toks, i):
    """toks[i-1] ends an lvalue; return index of its first token."""
    j = i - 1
    while True:
        if toks[j][1] == "]":
            depth = 0
            while True:
                if toks[j][1] == "]":
                    depth += 1
                elif toks[j][1] == "[":
                    depth -= 1
                    if depth == 0:
                        break
                j -= 1
            j -= 1
            continue
        if toks[j][0] == "name":
            if j > 0 and toks[j - 1][1] in (".", ":"):
                j -= 2
                continue
            return j
        raise SyntaxError("bad lvalue near %r" % toks[j][1])


def pico_to_lua(src):
    src = src.replace("\\^w", "").replace("\\^t", "")  # p8scii print codes
    toks = tokenize(src)
    edits = []  # (start, end, text)
    for i, t in enumerate(toks):
        if t[0] == "op" and t[1] in ("+=", "-=", "*=", "/=", "%=", "^=", "..="):
            s = lhs_start(toks, i)
            e = skip_expr(toks, i + 1)
            lhs = src[toks[s][2]:toks[i - 1][3]]
            rhs = src[toks[i + 1][2]:toks[e - 1][3]]
            op = t[1][:-1]
            edits.append((toks[s][2], toks[e - 1][3],
                          "%s = %s %s (%s)" % (lhs, lhs, op, rhs)))
        elif t[0] == "op" and t[1] == "!=":
            edits.append((t[2], t[3], "~="))
        elif t[0] == "op" and t[1] == "\\":
            edits.append((t[2], t[3], "//"))
    out, pos = [], 0
    for a, b, txt in sorted(edits):
        if a < pos:
            continue
        out.append(src[pos:a])
        out.append(txt)
        pos = b
    out.append(src[pos:])
    return "".join(out)


# --------------------------------------------------------------- lua prelude
PRELUDE = r"""
local py = python
flr=math.floor
function ceil(x) return -math.floor(-x) end
abs=math.abs
function sqrt(x) if x<0 then return 0 end return math.sqrt(x) end
function sin(x) return -math.sin(x*2*math.pi) end
function cos(x) return math.cos(x*2*math.pi) end
function atan2(dx,dy) return (math.atan(-dy,dx)/(2*math.pi))%1 end
function min(a,b) a=a or 0 b=b or 0 if a<b then return a end return b end
function max(a,b) a=a or 0 b=b or 0 if a>b then return a end return b end
function mid(a,b,c) a=a or 0 b=b or 0 c=c or 0
 if a>b then a,b=b,a end if b>c then b=c end if a>b then return a end return b end
function sgn(x) if x<0 then return -1 end return 1 end
function rnd(x) x=x or 1 if type(x)=="table" then return x[math.random(#x)] end return math.random()*x end
function srand(x) math.randomseed(math.floor(x)) end
function add(t,v,i) if i then table.insert(t,i,v) else t[#t+1]=v end return v end
function del(t,v) for i=1,#t do if t[i]==v then table.remove(t,i) return v end end end
function deli(t,i) return table.remove(t,i or #t) end
function count(t) return #t end
function all(t)
 if t==nil then return function() end end
 local i,n=0,#t
 return function()
  i=i+1
  while i<=#t and t[i]==nil do i=i+1 end
  return t[i]
 end
end
function foreach(t,f) for v in all(t) do f(v) end end
unpack=table.unpack
function sub(s,a,b) return string.sub(s,a,b) end
function tostr(x) return tostring(x) end
function tonum(x) return tonumber(x) end
function chr(n) return string.char(n) end
function ord(s,i) return string.byte(s,i or 1) end
function split(s,sep,conv)
 sep=sep or "," if conv==nil then conv=true end
 local out,pos={},1
 while true do
  local a=string.find(s,sep,pos,true)
  local piece=string.sub(s,pos,(a or 0)-1)
  if not a then piece=string.sub(s,pos) end
  local n=conv and tonumber(piece)
  out[#out+1]= n or piece
  if not a then break end
  pos=a+#sep
 end
 return out
end
function btn(i) return py.btn(i) end
function btnp(i) return py.btnp(i) end
function cls(c) py.cls(c or 0) end
function rectfill(a,b,c,d,col) py.rectfill(a,b,c,d,col) end
function rect(a,b,c,d,col) py.rect(a,b,c,d,col) end
function line(a,b,c,d,col) py.line(a,b,c,d,col) end
function circfill(x,y,r,c) py.circfill(x,y,r,c) end
function circ(x,y,r,c) py.circ(x,y,r,c) end
function pset(x,y,c) py.pset(x,y,c) end
function pget(x,y) return py.pget(x,y) end
function print(s,x,y,c) py.print(tostring(s),x,y,c) end
function fillp(p) py.fillp(p or 0) end
function color(c) py.color(c) end
function pal() end
function palt() end
function camera() end
function clip() end
function sfx(n) py.sfx(n) end
function music() end
function peek(a) return py.peek(a) end
function peek2(a) return py.peek2(a) end
function poke() end
local cdata={}
function cartdata() end
function dget(i) return cdata[i] or 0 end
function dset(i,v) cdata[i]=v end
function menuitem() end
function time() return py.time() end
t=time
function stat() return 0 end
function printh(s) py.printh(tostring(s)) end
"""


class Pico:
    def __init__(self, cart, seed=1):
        self.fb = bytearray(128 * 128)
        self.fill = 0
        self.pen = 6
        self.held = set()
        self.prev = set()
        self.frame = 0
        self.sounds = []
        self.instr = 0
        with open(cart, encoding="utf-8") as f:
            text = f.read()
        lua_src = text.split("__lua__\n")[1].split("\n__map__")[0]
        lua_src = lua_src.replace("-->8", "--")
        maphex = text.split("__map__\n")[1].split("\n__sfx__")[0].replace("\n", "")
        self.mem = bytearray(0x8000)
        data = bytes.fromhex(maphex)
        self.mem[0x2000:0x2000 + len(data)] = data
        self.L = lupa.LuaRuntime(unpack_returned_tuples=True)
        g = self.L.globals()
        api = self.L.table()
        for name in ("btn", "btnp", "cls", "rectfill", "rect", "line", "circfill",
                     "circ", "pset", "pget", "print", "fillp", "color", "sfx",
                     "peek", "peek2", "time", "printh"):
            api[name] = getattr(self, "api_" + name)
        g.python = api
        self.L.execute(PRELUDE)
        self.L.execute("math.randomseed(%d)" % seed)
        self.lua = pico_to_lua(lua_src)
        try:
            self.L.execute(self.lua)
        except Exception:
            with open("/tmp/sim_dump.lua", "w") as f:
                f.write(self.lua)
            raise
        self.g = g
        self.L.execute("""
        __icount=0
        function __hook() __icount=__icount+100 end
        """)
        g._init()

    # ------------------------------------------------------------- api
    def api_btn(self, i=None):
        if i is None:
            return sum(1 << BUTTONS[b] for b in self.held)
        return any(BUTTONS[b] == i for b in self.held)

    def api_btnp(self, i):
        return any(BUTTONS[b] == i for b in self.held - self.prev)

    def col(self, c, x, y):
        c = int(c) if c is not None else self.pen
        p = self.fill
        if p:
            bit = (int(p) >> (15 - ((y & 3) * 4 + (x & 3)))) & 1
            return ((c >> 4) & 15) if bit else (c & 15)
        return c & 15

    def api_cls(self, c=0):
        self.fb[:] = bytes([int(c) & 15]) * (128 * 128)

    def api_pset(self, x, y, c=None):
        x, y = int(math.floor(x)), int(math.floor(y))
        if 0 <= x < 128 and 0 <= y < 128:
            self.fb[y * 128 + x] = self.col(c, x, y)

    def api_pget(self, x, y):
        x, y = int(x), int(y)
        return self.fb[y * 128 + x] if 0 <= x < 128 and 0 <= y < 128 else 0

    def api_rectfill(self, x0, y0, x1, y1, c=None):
        x0, y0, x1, y1 = (int(math.floor(v)) for v in (x0, y0, x1, y1))
        if x0 > x1: x0, x1 = x1, x0
        if y0 > y1: y0, y1 = y1, y0
        x0, x1, y0, y1 = max(x0, 0), min(x1, 127), max(y0, 0), min(y1, 127)
        for y in range(y0, y1 + 1):
            row = y * 128
            if self.fill:
                for x in range(x0, x1 + 1):
                    self.fb[row + x] = self.col(c, x, y)
            elif x1 >= x0:
                self.fb[row + x0:row + x1 + 1] = bytes([self.col(c, 0, 0)]) * (x1 - x0 + 1)

    def api_rect(self, x0, y0, x1, y1, c=None):
        self.api_line(x0, y0, x1, y0, c); self.api_line(x0, y1, x1, y1, c)
        self.api_line(x0, y0, x0, y1, c); self.api_line(x1, y0, x1, y1, c)

    def api_line(self, x0, y0, x1, y1, c=None):
        x0, y0, x1, y1 = (int(math.floor(v)) for v in (x0, y0, x1, y1))
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        n = max(dx, dy)
        if n > 600:
            return
        for i in range(n + 1):
            t = i / n if n else 0
            self.api_pset(x0 + (x1 - x0) * t + .5, y0 + (y1 - y0) * t + .5, c)

    def api_circfill(self, cx, cy, r, c=None):
        r = int(r)
        cx, cy = int(math.floor(cx)), int(math.floor(cy))
        if r > 200:
            return
        for y in range(-r, r + 1):
            w = int(math.sqrt(max(0, r * r - y * y + r * .8)))
            self.api_rectfill(cx - w, cy + y, cx + w, cy + y, c)

    def api_circ(self, cx, cy, r, c=None):
        for i in range(32):
            a = i / 32 * math.tau
            self.api_pset(cx + math.cos(a) * r, cy + math.sin(a) * r, c)

    def api_print(self, s, x=0, y=0, c=None):
        if x is None:
            return
        if isinstance(s, bytes):
            s = s.decode("utf-8", "replace")
        if to_p8str:
            try:
                s = to_p8str(s)
            except Exception:
                pass
        ox = x = int(x)
        y = int(y)
        for ch in s:
            o = ord(ch)
            if ch == "\n":
                x, y = ox, y + 6
                continue
            w = 8 if o >= 0x80 else 4
            glyph = FONT.get(o)
            if glyph:
                for gy, rowbits in enumerate(glyph):
                    for gx in range(w):
                        if rowbits >> gx & 1:
                            self.api_pset(x + gx, y + gy, c)
            x += w

    def api_fillp(self, p=0):
        self.fill = int(p) & 0xffff

    def api_color(self, c):
        self.pen = int(c)

    def api_sfx(self, n):
        self.sounds.append((self.frame, n))

    def api_peek(self, a):
        return self.mem[int(a)]

    def api_peek2(self, a):
        a = int(a)
        v = self.mem[a] | self.mem[a + 1] << 8
        return v - 0x10000 if v & 0x8000 else v

    def api_time(self):
        return self.frame / 60

    def api_printh(self, s):
        print(s)

    # --------------------------------------------------------- driving
    def step(self, hold=(), draw=False, count=False):
        self.prev = self.held
        self.held = set(hold)
        if count:
            self.L.execute("__icount=0 debug.sethook(__hook,'',100)")
        self.g._update60()
        if count:
            self.L.execute("debug.sethook()")
            upd = self.g['__icount']
        if draw:
            if count:
                self.L.execute("__icount=0 debug.sethook(__hook,'',100)")
            self.g._draw()
            if count:
                self.L.execute("debug.sethook()")
                self.instr = (upd, self.g['__icount'])
        self.frame += 1

    def run(self, n, hold=(), draw=False):
        if isinstance(hold, str):
            hold = hold.split("+") if hold else ()
        for _ in range(n):
            self.step(hold, draw)

    def state(self):
        g = self.g
        return dict(st=g.st, x=round(g.px, 2), y=round(g.py, 2), z=round(g.pz, 2),
                    spd=round(g.spd, 2), hs=round(g.hs(), 2), vy=round(g.vy, 2),
                    ang=round(g.ang, 3), flow=round(g.flow, 2), pop=g.pop)

    def shot(self, path, scale=3):
        from PIL import Image
        self.g._draw()
        im = Image.new("RGB", (128, 128))
        im.putdata([PALETTE[c] for c in self.fb])
        im = im.resize((128 * scale, 128 * scale), Image.NEAREST)
        im.save(path)

    def teleport(self, x, y, z, ang=None):
        self.L.execute("px,py,pz=%f,%f,%f vx,vy,vz,spd=0,0,0,0 setst'ground' nearupd()" % (x, y, z))
        if ang is not None:
            self.L.execute("ang=%f" % ang)
        self.L.execute("camreset()")


def load_font():
    font = {}
    try:
        from PIL import Image
        im = Image.open(os.path.join(SHRINKO, "font.png")).convert("RGBA")
    except Exception:
        return font
    px = im.load()
    for o in range(256):
        w = 8 if o >= 0x80 else 4
        x0, y0 = o % 16 * 8, o // 16 * 6
        rows = []
        for gy in range(6):
            bits = 0
            for gx in range(w):
                r, g_, b, a = px[x0 + gx, y0 + gy]
                if a > 0 and (r + g_ + b) > 0:
                    bits |= 1 << gx
            rows.append(bits)
        font[o] = rows
    return font


FONT = load_font()

if __name__ == "__main__":
    pc = Pico(sys.argv[1] if len(sys.argv) > 1 else "parkour.p8")
    pc.shot("/tmp/title.png")
    print(pc.state())
