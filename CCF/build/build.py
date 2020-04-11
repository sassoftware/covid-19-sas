# Python Program that Builds the programs for different uses: Public, SAS Development, CCF
# the parts used for building are located in /parts
# P_IMPORT: will import for public only
# C_IMPORT: will import for ccf
# X_IMPORT: will import for all
#   If X then P then only P - not C
#   If X then C then only C - not P
# T_IMPORT: will import for test versions
#   If X then T then only T - not P or C

from shutil import copyfile

# write the COVID_19.sas program
covid=open('./public/COVID_19.sas','w')
ccf=open('./ccf/COVID_19_SIRonly.sas','w') 
ccfall=open('./ccf/COVID_19_ALL.sas','w')
test=open('./COVID_19_test.sas','w')
ui=open('./UI/COVID_19.sas','w')

def subpart(file,type):
    with open('./parts/'+file) as part:
        for piece in part:
            if piece.startswith('X_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                if type=='P': subpart(file,'P')
                elif type=='C': subpart(file,'C')
                elif type=='T': subpart(file,'T')
                else: subpart(file,'X')
            elif piece.startswith('P_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                if type=='P': subpart(file,'P')
                elif type=='X': subpart(file,'P')
            elif piece.startswith('C_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                subpart(file,'C')
            elif piece.startswith('T_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                else:
                    file = piece[10:]
                print(file)
                subpart(file,'T')
            elif type=='X':
                covid.write(piece)
                ui.write(piece)
                ccf.write(piece)
                ccfall.write(piece)
                test.write(piece)
            elif type=='C':
                ccf.write(piece)
                ccfall.write(piece)
            elif type=='P':
                covid.write(piece)
                ui.write(piece)
                ccfall.write(piece)
                test.write(piece)
            elif type=='T':
                test.write(piece)

subpart('driver.sas','X')

covid.close()
ccf.close()
ccfall.close()
test.close()
ui.close()

copyfile('./public/COVID_19.sas', '../COVID_19.sas')
copyfile('./public/run_scenarios.csv', '../run_scenarios.csv')
copyfile('./public/run_scenarios.csv', './ccf/run_scenarios.csv')
