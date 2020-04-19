# Python Program that Builds the programs for different uses: Public, SAS Development, CCF
# the parts used for building are located in /parts
# P_IMPORT: will import for public only
# C_IMPORT: will import for ccf
# D_IMPORT: will import for ccfall
# U_IMPORT: will import for ui
# V_IMPORT: will import for ui_public
# X_IMPORT: will import for all
#   If X then P then only P - not C or U
#   If X then C then only C - not P or U
#   If X then U then only U - not P or C
# T_IMPORT: will import for test versions
#   If X then T then only T - not P or C or U

from shutil import copyfile

# write the COVID_19.sas program
p=open('./public/COVID_19.sas','w')
c=open('./ccf/COVID_19_SIRonly.sas','w') 
d=open('./ccf/COVID_19_ALL.sas','w')
t=open('./COVID_19_test.sas','w')
u=open('./UI/COVID_19.sas','w')
v=open('./UI_public/COVID_19.sas','w')

def subpart(file,type):
    with open('./parts/'+file) as part:
        for piece in part:
            if piece.startswith('X_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                subpart(file,type)
            elif piece.startswith('_IMPORT: ',1):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                subpart(file,piece[0:1])
            elif type=='X':
                p.write(piece)
                c.write(piece)
                d.write(piece)
                t.write(piece)
                u.write(piece)
                v.write(piece)
            else:
                # p.write(piece) - make generic so variable named type is the prefix (case matters)
                exec(type.lower()+'.write(piece)')

subpart('driver.sas','X')

p.close()
c.close()
d.close()
t.close()
u.close()
v.close()

copyfile('./public/COVID_19.sas', '../COVID_19.sas')
copyfile('./public/run_scenarios.csv', '../run_scenarios.csv')
copyfile('./public/run_scenarios.csv', './ccf/run_scenarios.csv')
