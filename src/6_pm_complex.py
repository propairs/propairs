#### defines 
cmd.bg_color('white')
cmd.set('sphere_transparency','0.3')
cmd.set("ray_orthoscopic", "on")
cmd.set("ignore_case", "0")
cmd.set("max_threads", "1") # parallelization is done externally

cmd.set_color("pred"  ,[0.55, 0.00, 0.00])
cmd.set_color("pgreen",[0.00, 0.35, 0.00])
cmd.set_color("pblue" ,[0.00, 0.00, 0.35])
cmd.set_color("dblue" ,[0.05, 0.19, 0.57])
cmd.set_color("blue"  ,[0.02, 0.50, 0.72])
cmd.set_color("mblue" ,[0.50, 0.70, 0.90])
cmd.set_color("lblue" ,[0.80, 0.50, 1.00]) 
cmd.set_color("lgreen",[0.80, 1.00, 0.50])
cmd.set_color("green" ,[0.00, 0.53, 0.22])
cmd.set_color("yellow",[0.95, 0.78, 0.00])
cmd.set_color("orange",[1.00, 0.40, 0.00])

colb1="colb1"
colb2="colb2"
colbr="colbr"
colu1="colu1"
colu2="colu2"
colu1r="colu1r"
colu2r="colu2r"

#chain colors
cmd.set_color("colb1", [0.80, 0.50, 1.00])
cmd.set_color("colb2", [0.80, 1.00, 0.50])
cmd.set_color("colbr", [0.80, 0.75, 0.75])
cmd.set_color("colu1", [0.30, 0.30, 0.65])
cmd.set_color("colu2", [0.10, 0.45, 0.10])
cmd.set_color("colu1r",[0.00, 0.00, 0.75])
cmd.set_color("colu2r",[0.00, 0.75, 0.00])

colcofb_matched   = "colcofb_matched"
colcofu_matched   = "colcofu_matched"
colcofb_unmatched = "colcofb_unmatched"
colcofb_other     = "colcofb_other"
colcofu_other     = "colcofu_other"

#cofactor colors
cmd.set_color("colcofb_matched"   ,[0.50, 0.70, 0.90])
cmd.set_color("colcofb_unmatched" ,[1.00, 0.40, 0.00])
cmd.set_color("colcofb_other"     ,[0.30, 0.30, 0.30])
cmd.set_color("colcofu_matched"   ,[1.00, 0.40, 0.40])
cmd.set_color("colcofu_unmatched" ,[0.95, 0.78, 0.00])
cmd.set_color("colcofu_other"     ,[0.70, 0.70, 0.70])


#selection names
sb1="sb1"
sb2="sb2"
su1="su1"
su2="su2"

cofign="cofign"
cofb1="cofb1"
cofb2="cofb2"
cofu1="cofu1"
cofu2="cofu2"
cofbu="cofbu"
cofbo1="cofbo1"
cofbo2="cofbo2"
cofuo1="cofuo1"
cofuo2="cofuo2"


cofsb1 ="cofsb1"
cofsb2 ="cofsb2"
cofsu1 ="cofsu1"
cofsu2 ="cofsu2"
cofsbu ="cofsbu"
cofsbo1="cofsbo1"
cofsbo2="cofsbo2"
cofsuo1="cofsuo1"
cofsuo2="cofsuo2"



#### load and transpose
cmd.load(ppdbdir+ppdbidB  + ".pdb",  bpdb)
cmd.load(ppdbdir+ppdbidU1 + ".pdb", u1pdb)
cmd.transform_selection(u1pdb, pu1rot, homogenous=1)

if (cfgHasU2 == True):
   #superpose
   cmd.load(ppdbdir+ppdbidU2 + ".pdb", u2pdb)
   cmd.transform_selection(u2pdb, pu2rot, homogenous=1)
else:
   pcofactorU2 = []
   cmd.create(u2pdb, "none")
   pchainsU2="X"


b1chains = '+'.join(pchainsB1)
b2chains = '+'.join(pchainsB2)
u1chains = '+'.join(pchainsU1)
u2chains = '+'.join(pchainsU2)

#helper functions

def cofSelectIgnore(_cofign, fn):
   l = []
   with open(fn, 'r') as f:
      for line in f:
         line = line.rstrip()
         if line != "":
            l.append(line)
   cmd.select(_cofign, "resn " + "+".join(l))
def cofSelectStr(pdb, cofactorlist):
   retstr = "none"
   if len(cofactorlist) > 0:
      retstr = '%s and (' %pdb
      for i,cofactor in enumerate(cofactorlist):
        retstr += '(chain %s and resid %s)'%cofactor 
        if len(cofactorlist) > 1 and i < len(cofactorlist)-1:
          retstr += ' or '
      retstr += ')'
   return retstr
def cofSelect(_cofselname, pdb, cofactorlist):      
   selstr = cofSelectStr(pdb, cofactorlist)
   cmd.select(_cofselname, selstr)
def cofSurf(_cofSurfName, _cofSelName):      
   mapName = _cofSurfName + "_map"
   cmd.set("gaussian_resolution", 2.5)
   cmd.do("map_new " + mapName + ", gaussian, 0.5, " + _cofSelName)
   cmd.do("isosurface " + _cofSurfName  +  ", " + mapName)
   cmd.do("set transparency=0.6, " + _cofSurfName)
   cmd.color("red", _cofSurfName)   
def cofShow(_cofsel, _cofselsurf, color):
   #cmd.show("spheres", _cofsel)
   cmd.show("sticks" , _cofsel)
   cmd.color(color   , _cofsel)
   cmd.show("surface" , _cofselsurf)
   cmd.color(color   , _cofselsurf)
def b1Show():
   cmd.color(colb1, sb1)
   cmd.show("cartoon", sb1)
   cofShow(cofb1, cofsb1, colcofb_matched)
   cofShow(cofbo1, cofsbo1, colcofb_other)
def b2Show():
   cmd.color(colb2, sb2)
   cmd.show("cartoon", sb2)
   cofShow(cofb2, cofsb2, colcofb_matched)
   cofShow(cofbo2, cofsbo2, colcofb_other)
def u1Show():
   cmd.color(colu1, su1)
   cmd.show("cartoon", su1)
   cofShow(cofu1, cofsu1, colcofu_matched)
   cofShow(cofuo1, cofsuo1, colcofu_other)   
def u2Show():
   cmd.color(colu2, su2)
   cmd.show("cartoon", su2)
   cofShow(cofu2, cofsu2, colcofu_matched)
   cofShow(cofuo2, cofsuo2, colcofu_other)   
def hideStuff():
   cmd.hide("everything")
def ray(title):
   if cfgPngPrefix != "":
      cmd.viewport(cfgImgWidth, cfgImgWidth*3/4)
      cmd.ray(cfgImgWidth, cfgImgWidth*3/4)
      cmd.do("png " + cfgPngPrefix + "_p" + title + ".png")
   if cfgVrmlPrefix != "":
      cmd.save(cfgVrmlPrefix + "_p" + title + ".wrl")

      
      
#select cofactors   
cofSelectIgnore(cofign, cfgCofIgnorelist)
cofSelect(cofb1, bpdb,  pcofactorB1)
cofSelect(cofb2, bpdb,  pcofactorB2)
cofSelect(cofu1, u1pdb, pcofactorU1)
cofSelect(cofu2, u2pdb, pcofactorU2)
# cofbu (unmatched): all cofB in interface but not the already selected ones
cmd.select(cofbu, cofSelectStr(bpdb, pcofactorBa) + " and not (cofu1 or cofu2)")

#select binding partners of complex and unbound
cmd.select(sb1, "bpdb and chain "  + b1chains + " and not (cofb1 or cofb2)")
cmd.select(sb2, "bpdb and chain "  + b2chains + " and not (cofb1 or cofb2)")
cmd.select(su1, "u1pdb and chain " + u1chains + " and not (cofu1)")
cmd.select(su2, "u2pdb and chain " + u2chains + " and not (cofu1)")

# cofXoX (remaining): all cof close to X but not the already selected
cmd.select(cofbo1, "byres ( ( bpdb and not (polymer or cofign or sb1 or sb2 or cofb1 or cofb2 or cofbu)  ) within 6 of sb1)")
cmd.select(cofbo2, "byres ( ( bpdb and not (polymer or cofign or sb2 or sb1 or cofb2 or cofb1 or cofbu)  ) within 6 of sb2) and not cofbo1")
cmd.select(cofuo1, "byres ( ( u1pdb and not (polymer or cofign or su1 or cofu1)  ) within 6 of su1)")
cmd.select(cofuo2, "byres ( ( u2pdb and not (polymer or cofign or su2 or cofu2)  ) within 6 of su2)")



cofSurf(cofsb1 ,cofb1)
cofSurf(cofsb2 ,cofb2)
cofSurf(cofsu1 ,cofu1)
cofSurf(cofsu2 ,cofu2)
cofSurf(cofsbu ,cofbu)
cofSurf(cofsbo1,cofbo1)
cofSurf(cofsbo2,cofbo2)
cofSurf(cofsuo1,cofuo1)
cofSurf(cofsuo2,cofuo2)


# camera
cmd.select("none")
cmd.orient("sb1 or sb2")
cmd.zoom("sb1 or sb2", -10, 0, 1)





# patch for interesting example from paper (not really needed)
if ppdbidB=="1bgx1":
   cmd.turn("y", 192)


# set number of rotations
numsteps = 1
if cfgImgRotate == True:
   numsteps = 30


# create images
stepangle = 360/numsteps
for i in range(1, numsteps+1):
   hideStuff()
   #b1Show()
   #b2Show()
   #u1Show()
   #u2Show()
   ray("0000_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   #b2Show()
   #u1Show()
   u2Show()
   ray("0001_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   #b2Show()
   u1Show()
   #u2Show()
   ray("0010_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   #b2Show()
   u1Show()
   u2Show()
   ray("0011_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   b2Show()
   #u1Show()
   #u2Show()
   ray("0100_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   b2Show()
   #u1Show()
   u2Show()
   ray("0101_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   b2Show()
   u1Show()
   #u2Show()
   ray("0110_" + str(i).zfill(2))
   hideStuff()
   #b1Show()
   b2Show()
   u1Show()
   u2Show()
   ray("0111_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   #b2Show()
   #u1Show()
   #u2Show()
   ray("1000_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   #b2Show()
   #u1Show()
   u2Show()
   ray("1001_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   #b2Show()
   u1Show()
   #u2Show()
   ray("1010_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   #b2Show()
   u1Show()
   u2Show()
   ray("1011_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   b2Show()
   #u1Show()
   #u2Show()
   ray("1100_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   b2Show()
   #u1Show()
   u2Show()
   ray("1101_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   b2Show()
   u1Show()
   #u2Show()
   ray("1110_" + str(i).zfill(2))
   hideStuff()
   b1Show()
   b2Show()
   u1Show()
   u2Show()
   ray("1111_" + str(i).zfill(2))
   cmd.turn("y", stepangle)



# PDB out
if cfgPdbPrefix != "":
   cmd.save(cfgPdbPrefix + "_b1.pdb", "sb1 or cofb1 or cofbo1")
   cmd.save(cfgPdbPrefix + "_b2.pdb", "sb2 or cofb2 or cofbo2")
   cmd.save(cfgPdbPrefix + "_u1.pdb", "su1 or cofu1 or cofuo1") 
   cmd.save(cfgPdbPrefix + "_u2.pdb", "su2 or cofu2 or cofuo2")



