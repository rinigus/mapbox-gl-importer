#!/usr/bin/env python2.7

MAX_ZOOM = 14

WORLD_ZOOM = 6

##################################################################################################
## Imports
##################################################################################################

import sys, copy, os, codecs, math, errno
from yaml import load as yload
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper
from lxml import etree
from jinja2 import Template

##################################################################################################
## Helper functions
##################################################################################################
def numTiles(z):
  return 2**z

def num2deg(xtile, ytile, zoom):
    n = 2.0 ** zoom
    lon_deg = xtile / n * 360.0 - 180.0
    lat_rad = math.atan(math.sinh(math.pi * (1 - 2 * ytile / n)))
    lat_deg = math.degrees(lat_rad)
    return (lat_deg, lon_deg)

def tile_bnd(xtile, ytile, zoom):
    b1 = num2deg(xtile, ytile, zoom)
    b2 = num2deg(xtile+1, ytile+1, zoom)
    bndstring = "%f,%f,%f,%f" % (b1[1], b2[0], b2[1], b1[0])
    return bndstring

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

##################################################################################################
## MAIN
##################################################################################################

if len(sys.argv) != 3:
    print "Usage: " + sys.argv[0] + " <path for layers.yml> <filebasename for tiles>"
    print "Output would be to the layers definition files, import shell script and makefile."
    print "Here, <filebasename for tiles> should be full path for MBTILES file basename. This is used in Makefile-based tile generation only."
    sys.exit(-1)

finname = sys.argv[1]
DATA_STORE = sys.argv[2]

foutdir = os.path.abspath(os.path.splitext(finname)[0])
foutname = os.path.abspath(os.path.join(foutdir,"layers.xml"))
mkdir_p(foutdir)

print "Reading:", finname
print "Writing:", foutname

definitions = yload(codecs.open(finname, mode="r", encoding="utf-8"), Loader=Loader)

defaults = definitions["defaults"]
layers = definitions["layers"]
parameters = definitions["parameters"]

xml = {}
# zoom levels [0..14]
for Z in range(MAX_ZOOM + 1):

    print "Z: %2d" % Z, " - ",

    head = etree.Element('Map',
                         srs="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over")

    # parameters
    par = etree.SubElement(head, "Parameters")
    keys = parameters.keys()
    keys.sort()
    for p in keys:
        el = etree.SubElement(par, "Parameter", name=p)
        el.text = unicode(parameters[p])

    # layers
    for layer in layers:
        name = layer["id"]
        srs = layer.get("srs", defaults["srs"])
        zmax = layer.get("zmax", defaults["zmax"])
        zmin = layer.get("zmin", defaults["zmin"])
        if Z < zmin or Z > zmax: continue
        bsize = str(layer.get("buffer-size", defaults["buffer-size"]))

        print name,
        l = etree.SubElement(head, "Layer", name=name, srs=srs)
        l.attrib["buffer-size"] = bsize
        ds = etree.SubElement(l, "Datasource")

        ll = copy.copy(defaults)
        for k in layer: ll[k] = layer[k]

        keys = ll.keys()
        keys.sort()
        for par in keys:
            if par in ["id", "srs", "zmin", "zmax", "buffer-size"]: continue
            if ll["type"] != "sqlite" and par in ["use_spatial_index"]: continue

            p = etree.SubElement(ds, "Parameter", name=par)
            if ll[par] is not None: txt = unicode(ll[par])
            else: txt = ""
            if par == "table": txt = "(" + txt + ") AS data"
            template = Template(txt)
            p.text = template.render(z=Z)

    xml[Z] = """<?xml version='1.0' encoding='utf-8'?>
    <!DOCTYPE Map>
    """ + etree.tostring(head, pretty_print=True).replace("ZLEVEL", str(Z))
    print

kk = xml.keys()
kk.sort()
xml_range = {}
for Z1 in kk:
    if Z1 not in xml: continue
    Z2 = Z1+1
    while Z2 in xml:
        if xml[Z1] == xml[Z2] and ((Z1<=WORLD_ZOOM and Z2<=WORLD_ZOOM) or (Z1>WORLD_ZOOM and Z2>WORLD_ZOOM)):
            del xml[Z2]
        else:
            break
        Z2 += 1
    Z2 -= 1
    xml_range[Z1] = [Z1,Z2]

# write xml files
kk = xml.keys()
kk.sort()
for z in kk:
    Z = xml_range[z]
    fname = "%s-%s-%s" % (foutname, Z[0], Z[1])
    outFile = codecs.open(fname, mode="w", encoding="utf-8")
    outFile.write(xml[z])
    outFile.close()

# generate the script
cmds = "#!/bin/bash\n\n# Automatically generated script by %s\n\nset -e\n\n" % sys.argv[0]
for z in kk:
    Z = xml_range[z]
    fname = "%s-%s-%s" % (foutname, Z[0], Z[1])
    cmds += "echo\necho Processing levels %d -- %d\n" % (Z[0], Z[1])
    cmds += "tilelive-copy --minzoom=%s --maxzoom=%s --scheme=pyramid bridge://%s $* \n" % (Z[0], Z[1], fname)

fimportername = foutname + "-importer.sh"
fout = open( fimportername, "w" )
fout.write(cmds)
print "Importer script at", fimportername

# generate makefile
cmds_world = []
cmds_section = []
for z in kk:
    Z = xml_range[z]
    fname = "%s-%s-%s" % (foutname, Z[0], Z[1])
    cmd = "tilelive-copy --timeout=300000 --minzoom=%s --maxzoom=%s --scheme=pyramid bridge://%s" % (Z[0], Z[1], fname)
    if z <= WORLD_ZOOM: cmds_world.append(cmd)
    else: cmds_section.append(cmd)

fmakename = foutname + "-makefile"
fmake = open(fmakename, "w")
fmake.write("# Automatically generated Makefile by %s\n\n" % sys.argv[0])
fmake.write("all: generate_all\n\n")
fmake.write("clean:\n\trm -f %s*\n\n" % DATA_STORE)
targets = []

# world layer
name = DATA_STORE + "-world.sqlite"
targets.append(name + "-done")
fmake.write(name + "-done:\n")
for c in cmds_world:
    fmake.write("\t" + c + " mbtiles://" + name + "\n")
fmake.write("\techo Done > " + name + "-done\n\n")

# section layers
z = WORLD_ZOOM+1
tiles_per_coor = numTiles(z)
for x in range(tiles_per_coor):
    for y in range(tiles_per_coor):
        name = DATA_STORE + "-section-%d-%d-%d.sqlite" % (z, x, y)
        targets.append(name + "-done")
        b = tile_bnd(x, y, z)
        fmake.write(name + "-done:\n")
        for c in cmds_section:
            fmake.write("\t" + c + (' --bounds="%s"' % b) + " mbtiles://" + name + "\n")
        fmake.write("\techo Done > " + name + "-done\n\n")

fmake.write("generate_all: ")
for t in targets: fmake.write(t + " ")
fmake.write("\n\n")

print "Import using make: make -f %s" % fmakename