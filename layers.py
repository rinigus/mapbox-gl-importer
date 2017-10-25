#!/usr/bin/env python2.7

import sys, copy, os, codecs
from yaml import load as yload
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper
from lxml import etree


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
    print "Layer: ", name
    srs = layer.get("srs", defaults["srs"])
    l = etree.SubElement(head, "Layer", name=name, srs=srs)
    ds = etree.SubElement(l, "Datasource")

    ll = copy.copy(defaults)
    for k in layer: ll[k] = layer[k]

    keys = ll.keys()
    keys.sort()
    for par in keys:
        if par in ["id", "srs"]: continue
        if ll["type"] != "sqlite" and par in ["use_spatial_index"]: continue
        
        p = etree.SubElement(ds, "Parameter", name=par)
        txt = unicode(ll[par])
        if par == "table": txt = "(" + txt + ") AS data"
        p.text = txt
        

outFile = codecs.open(foutname, mode="w", encoding="utf-8")
outFile.write("""<?xml version='1.0' encoding='utf-8'?>
<!DOCTYPE Map>
""")
etree.ElementTree(head).write(outFile, pretty_print=True)
outFile.close()
