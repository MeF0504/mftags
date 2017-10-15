"""
#with open("/Users/fujino/workspace/work/tags","r") as f:
with open("/Volumes/SDHC/takuro/Documents/sample_codes/tags","r") as f:
    for line in f:
        L = line.split('\t')
        if len(L) >3:
            print L[0]
            print L[3]
"""
values = []
functions = []

def test1_func():#values, functions):
    values = []
    functions = []
    #with open("/Volumes/SDHC/takuro/Documents/sample_codes/tags","r") as f:
    with open("S:/takuro/Documents/sample_codes/tags", "r" ) as f:
        for line in f:
            line = line.replace("\n","")
            L = line.split('\t')
            print L
            """
            if (len(L) > 3) and (L[3] == "v"):
                print L[0]
                values.append(L[0])
            elif (len(L) > 3) and (L[3] == "f"):
                print L[0]
                functions.append(L[0])
            """

    #print values
    #print functions

    return values

#print values, functions
test1_func()    #values, functions)
#print values, functions
