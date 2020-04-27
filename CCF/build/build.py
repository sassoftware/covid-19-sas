# Python Program that Builds the programs for different uses: Public, SAS Development, CCF
# the parts used for building are located in /parts
# P_IMPORT: will import for public only
# C_IMPORT: will import for ccf
# D_IMPORT: will import for ccfall
# T_IMPORT: will import for test versions
# U_IMPORT: will import for ui
# V_IMPORT: will import for ui_public
# X_IMPORT: will import for all
#   If X then P then only P - not C or U
#   If X then C then only C - not P or U
#   If X then U then only U - not P or C
#   If X then T then only T - not P or C or U

from shutil import copyfile
from graphviz import Digraph
dot = Digraph(comment = 'Build Diagram',strict=True)
dot.attr(rankdir='LR')

# file to create
fp='./public/COVID_19.sas'
fc='./ccf/COVID_19_SIRonly.sas'
fd='./ccf/COVID_19_ALL.sas'
ft='./COVID_19_test.sas'
fu='./UI/COVID_19.sas'
fv='./UI_public/COVID_19.sas'

# open files to write
p=open(fp,'w')
c=open(fc,'w') 
d=open(fd,'w')
t=open(ft,'w')
u=open(fu,'w')
v=open(fv,'w')

# recursive function to call parts and write to files
def subpart(file,type,node):
    with open('./parts/'+file) as part:
        order=0
        for piece in part:
            if piece.startswith('_IMPORT: ',1):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                # setup next node and edge from current to next: first for type not changing, second for types changing
                order+=1
                if type==piece[0:1] or piece[0:1]=='X':
                    dot.node(node+'_'+str(order),file)
                    dot.edge(node,node+'_'+str(order))
                    subpart(file,type,node+'_'+str(order))
                elif type=='X':
                    # put a node and edge to the type
                    dot.node(node+'_'+piece[0:1],eval('f'+piece[0:1].lower()),shape='box',style='filled',fillcolor='lightgrey')
                    dot.edge(node,node+'_'+piece[0:1])
                    # node and edge to file from the type
                    dot.node(node+'_'+piece[0:1]+'_'+str(order),file)
                    dot.edge(node+'_'+piece[0:1],node+'_'+piece[0:1]+'_'+str(order))
                    subpart(file,piece[0:1],node+'_'+piece[0:1]+'_'+str(order))
            elif type=='X':
                p.write(piece)
                c.write(piece)
                d.write(piece)
                t.write(piece)
                u.write(piece)
                v.write(piece)
            else:
                exec(type.lower()+'.write(piece)')
    return order

# start the build
dot.node(str(0),'driver.sas')
subpart('driver.sas','X',str(0))

# close the files
p.close()
c.close()
d.close()
t.close()
u.close()
v.close()

# move the public version to the main repository folder
copyfile('./public/COVID_19.sas', '../COVID_19.sas')
copyfile('./public/run_scenarios.csv', '../run_scenarios.csv')
copyfile('./public/run_scenarios.csv', './ccf/run_scenarios.csv')

# write the graphviz plot to an svg for inclusion in the /build/readme.md
dot.format = 'SVG'
dot.render('build')