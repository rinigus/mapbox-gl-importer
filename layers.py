#!/usr/bin/env python2.7

MAX_ZOOM = 14

import sys, copy, os, codecs
from yaml import load as yload
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper
from lxml import etree
from jinja2 import Template

if len(sys.argv) != 2:
    print "Usage: " + sys.argv[0] + " <path for layers.yml>"
    print "Output would be to the layers definition file with the extension replaced by .xml"
    sys.exit(-1)

finname = sys.argv[1]
foutname = os.path.abspath(os.path.splitext(finname)[0] + ".xml")

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
            txt = unicode(ll[par])
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
        if xml[Z1] == xml[Z2]:
            del xml[Z2]
        else:
            break
        Z2 += 1
    Z2 -= 1
    xml_range[Z1] = [Z1,Z2]

cmds = "#!/bin/bash\n\n# Automatically generated script by %s\n\n" % sys.argv[0]
kk = xml.keys()
kk.sort()
for z in kk:
    Z = xml_range[z]
    fname = "%s-%s-%s" % (foutname, Z[0], Z[1])
    outFile = codecs.open(fname, mode="w", encoding="utf-8")
    outFile.write(xml[z])
    outFile.close()
    cmds += "echo\necho Processing levels %d -- %d\n" % (Z[0], Z[1])
    cmds += "tilelive-copy --minzoom=%s --maxzoom=%s --scheme=pyramid bridge://%s $* \n" % (Z[0], Z[1], fname)

fimportername = foutname + "-importer.sh"
fout = open( fimportername, "w" )
fout.write(cmds)

print "Importer script at", fimportername
