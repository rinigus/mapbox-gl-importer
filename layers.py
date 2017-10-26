#!/usr/bin/env python2.7

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
foutname = os.path.splitext(finname)[0] + ".xml"

print "Reading:", finname
print "Writing:", foutname

definitions = yload(codecs.open(finname, mode="r", encoding="utf-8"), Loader=Loader)

defaults = definitions["defaults"]
layers = definitions["layers"]
parameters = definitions["parameters"]

xml = {}
# zoom levels [0..14]
for Z in range(14):

    print "Z: %2d" % Z, " - ",

    head = etree.Element('Map', srs="+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs +over")

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
        
        print name,
        l = etree.SubElement(head, "Layer", name=name, srs=srs)
        ds = etree.SubElement(l, "Datasource")

        ll = copy.copy(defaults)
        for k in layer: ll[k] = layer[k]

        keys = ll.keys()
        keys.sort()
        for par in keys:
            if par in ["id", "srs", "zmin", "zmax"]: continue
            if ll["type"] != "sqlite" and par in ["use_spatial_index"]: continue

            p = etree.SubElement(ds, "Parameter", name=par)
            txt = unicode(ll[par])
            if par == "table": txt = "(" + txt + ") AS data"
            template = Template(txt)        
            p.text = template.render(z=Z)

    xml[Z] = """<?xml version='1.0' encoding='utf-8'?>
    <!DOCTYPE Map>
    """ + etree.tostring(head, pretty_print=True)
    print

kk = xml.keys()
kk.sort()
for Z1 in kk:
    if Z1 not in xml: continue
    for Z2 in kk:
        if Z1 == Z2 or Z2 not in xml: continue
        if xml[Z1] == xml[Z2]:
            del xml[Z2]

for Z in xml:
    outFile = codecs.open(foutname + "-" + str(Z), mode="w", encoding="utf-8")
    outFile.write(xml[Z])
    outFile.close()
    # outFile.write("""<?xml version='1.0' encoding='utf-8'?>
    # <!DOCTYPE Map>
    # """)
    # etree.ElementTree(head).write(outFile, pretty_print=True)
    # outFile.close()
