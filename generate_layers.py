#!/usr/bin/env python2.7

import sys, os, codecs, collections, errno, json
from yaml import load as yload
from yaml import dump as ydump
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper

###############################################################################
## Helper functions
###############################################################################
def loadyaml(fname):
    data = codecs.open(fname, mode="r", encoding="utf-8").read()
    for evar in ["POSTGRES_USER", "POSTGRES_PASSWORD",
                 "POSTGRES_DB", "POSTGRES_HOST", "POSTGRES_PORT"]:
        data = data.replace(evar, os.environ.get(evar, evar))
    return yload(data, Loader=Loader)

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise

###############################################################################
## Main
###############################################################################

if len(sys.argv) != 3:
    print "Usage: " + sys.argv[0] + " <path for layers project directory> <build directory>"
    print "Generates layers definition file used by vector source generator"
    sys.exit(-1)

projectdir = sys.argv[1]
builddir = sys.argv[2]

# load project
layers = loadyaml(os.path.join(projectdir, "layers-list.yaml"))
project = loadyaml(os.path.join(projectdir, "layers-header.yaml"))
project["layers"] = []
layers_desc = {}
for l in layers:
    print "Layer:", l
    current = loadyaml(os.path.join(projectdir, l, l + ".yaml"))
    project["layers"].extend(current["layers"])

    for L in current["layers"]:
        if "id" not in L:
            print "Layer is missing ID"
            sys.exit(-2)
        id = L["id"]
        fields = {}
        for k, v in L.get("fields", {}).iteritems():
            fields[k] = v.title()
        layers_desc[id] = dict(id = id, fields = fields)

vector_layers = [v for v in layers_desc.values()]
project["parameters"]["json"] = json.dumps(dict(vector_layers = vector_layers))

mkdir_p(builddir)
f = open(os.path.join(builddir, "layers.yaml"), mode="w")
f.write(ydump(dict(project), Dumper=Dumper))
