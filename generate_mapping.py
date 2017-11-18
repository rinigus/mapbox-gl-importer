#!/usr/bin/env python2.7

import sys, os, codecs, collections, errno
from yaml import load as yload
from yaml import dump as ydump
try:
    from yaml import CLoader as Loader, CDumper as Dumper
except ImportError:
    from yaml import Loader, Dumper


###############################################################################
## Constants
###############################################################################

MAX_POSSIBLE_ZLEVEL=20

###############################################################################
## Helper functions
###############################################################################
def loadyaml(fname):
    try:
        txt = codecs.open(fname, mode="r", encoding="utf-8").read()
    except:
        print "Cannot open:", fname
        return []
    for z in reversed(range(MAX_POSSIBLE_ZLEVEL)):
        txt = txt.replace("ZAREA%d" % z, str(zarea(z)))
    for z in reversed(range(MAX_POSSIBLE_ZLEVEL)):
        txt = txt.replace("ZTOL%d" % z, str(ztol(z)))
    for z in reversed(range(MAX_POSSIBLE_ZLEVEL)):
        txt = txt.replace("ZRES%d" % z, str(ztol(z)))
    return yload(txt, Loader=Loader)
    #return yload(codecs.open(fname, mode="r", encoding="utf-8"), Loader=Loader)

def ztol(z):
    return 40075016.6855785/((256)*2**z)

def zarea(z):
    zt = ztol(max(0,z-2))
    return zt*zt

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
    print "Generates imposm3 mapping definition file and update.sql"
    sys.exit(-1)

projectdir = sys.argv[1]
builddir = sys.argv[2]

# load project
layers = loadyaml(os.path.join(projectdir, "layers-list.yaml"))
project = collections.defaultdict(dict)
update_sql = ""

for l in layers:
    print "Layer:", l
    current = loadyaml(os.path.join(projectdir, l, "mapping.yaml"))
    schema = loadyaml(os.path.join(projectdir, l, l + ".yaml")).get("schema", [])
    for k in current:
        if k == "auto_generalized_tables":
            for gk in current[k]:
                gt = current[k][gk]
                zmin = gt["zmin"]
                zmax = gt["zmax"]
                area_filter = gt.get("area_filter", False)
                source = gk
                for i in range(zmin, zmax+1):
                    rec_name = source + "_z%d" % i
                    if i < zmax: s = source + "_z%d" % (i+1)
                    else: s = source
                    rec = { "source": s, "tolerance": ztol(i) }
                    if area_filter: rec["sql_filter"] = "area > " + str(zarea(i))
                    project["generalized_tables"][rec_name] = rec
        elif k in ["generalized_tables", "tables"]:
            if current[k] is not None:
                project[k].update(current[k])
    for sql in schema:
        current_sql = os.path.join(projectdir, l, sql)
        if os.path.exists(current_sql):
            sql = open(current_sql, "r").read()
            for z in reversed(range(MAX_POSSIBLE_ZLEVEL)):
                sql = sql.replace("ZAREA%d" % z, str(zarea(z)))
            for z in reversed(range(MAX_POSSIBLE_ZLEVEL)):
                sql = sql.replace("ZTOL%d" % z, str(ztol(z)))
            update_sql += '--- ' + l + "\n" + sql + "\n\n"

mkdir_p(builddir)
with open(os.path.join(builddir, "mapping.yaml"), mode="w") as f:
    f.write(ydump(dict(project), Dumper=Dumper))

update_sql += "VACUUM ANALYZE;\n"
with open(os.path.join(builddir, "update.sql"), mode="w") as f:
    f.write(update_sql)
