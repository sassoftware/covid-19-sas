# Python Program that Builds the programs for different uses: Public, SAS Development, CCF
# the parts used for building are located in /parts
# P_IMPORT: will import for public only
# C_IMPORT: will import for ccf
# X_IMPORT: will import for all

from shutil import copyfile

# write the COVID_19.sas program
covid=open('./public/COVID_19.sas', 'w')
ccf=open('./ccf/COVID_19_SIRonly.sas','w') 
ccfall=open('./ccf/COVID_19_ALL.sas','w')

def subpart(file,type):
    with open('./parts/'+file) as part:
        for piece in part:
            if piece.startswith('X_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                    covid.write('\n')
                    ccf.write('\n')
                    ccfall.write('\n')
                else:
                    file = piece[10:]
                print(file)
                subpart(file,'X')
            elif piece.startswith('P_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                    covid.write('\n')
                    ccfall.write('\n')
                else:
                    file = piece[10:]
                print(file)
                subpart(file,'P')
            elif piece.startswith('C_IMPORT: '):
                if '\n' in piece:
                    file = piece[10:len(piece)-1]
                    ccf.write('\n')
                    ccfall.write('\n')
                else:
                    file = piece[10:]
                print(file)
                subpart(file,'C')
            elif type=='X':
                covid.write(piece)
                ccf.write(piece)
                ccfall.write(piece)
            elif type=='C':
                ccf.write(piece)
                ccfall.write(piece)
            elif type=='P':
                covid.write(piece)
                ccfall.write(piece)

subpart('driver.sas','X')

covid.close()
ccf.close()
ccfall.close()

copyfile('./public/COVID_19.sas', '../COVID_19.sas')
copyfile('./public/run_scenarios.csv', '../run_scenarios.csv')
copyfile('./public/run_scenarios.csv', './ccf/run_scenarios.csv')


