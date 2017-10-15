
import os
import os.path as op

def search_tag(tags):
    return file_path

def make_tag_syntax_file(file_path, filetype):
    """ This function makes syntax setting file at the same directory of tag file.
        file_path: path to tag file.
        file type: current opening file type. ex) c, c++, python ...
    """
    file_path = file_path.replace('/',os.sep)   #adjust os path problem.
    if (filetype == 'c') or (filetype == 'C++'):
        tag_list = {'c':[],\
                    'd':[],\
                    'e':[],\
                    'f':[],\
                    'g':[],\
                    'l':[],\
                    'm':[],\
                    'n':[],\
                    'p':[],\
                    's':[],\
                    't':[],\
                    'u':[],\
                    'v':[],\
                    'x':[]}
        tag_name = {'c':['Class', 'MFclass'],\
                    'd':['Definitions', ''],\
                    'e':['Enumerators', 'MFenum'],\
                    'f':['Function_definitions', 'MFfunction'],\
                    'g':['Enumeration_names', 'MFtypedef'],\
                    'l':['Local_variables', 'MFvariable'],\
                    'm':['Members', 'MFmember'],\
                    'n':['Namespaces', 'MFnamespace'],\
                    'p':['Prototypes', 'MFfunction'],\
                    's':['Structure', 'MFstructure'],\
                    't':['Typedefs', 'MFtypedef'],\
                    'u':['Union', 'MFtypedef'],\
                    'v':['Variables', 'MFvariable'],\
                    'x':['External_and_forward_variable_declarations', 'MFdeclaration'] }
    elif filetype == 'python':
        tag_list = {'c':[],\
                    'f':[],\
                    'm':[],\
                    'v':[],\
                    'i':[]}
        tag_name = {'c':['Classes' ,'MFclass'],\
                    'f':['Functions' ,'MFfunction'],\
                    'm':['Members' ,'MFmember'],\
                    'v':['Variables' ,'MFvariable'],\
                    'i':['Imports' ,'MFimport']}
    elif filetype == 'vim':
        tag_list = {'a':[],\
                    'c':[],\
                    'f':[],\
                    'm':[],\
                    'v':[]}
        tag_name = {'a':['Autocommand_groups', 'MFautocmd'],\
                    'c':['User_defined_commands' ,'MFcommand'],\
                    'f':['Function_definitions' ,'MFfunction'],\
                    'm':['Maps', 'MFmap'],\
                    'v':['Variables', 'MFvariable']}
    else:
        print "not supported file type"
        exit

    with open(file_path) as f:
        for line in f:
            if line.startswith('!'):
                continue
            line = line.replace("\n","")
            kind = line[line.find(';')+3]
            line = line.split("\t")
            name = line[0]
            try:
                tag_list[kind].append(name)
            except KeyError:
                print "This is not a correct kind."
                print "language : ",filetype, "kind : ",kind
    
    """
    for k in tag_list:
        print k
        print tag_list[k]
    """

    tag_dir = op.dirname(file_path)
    with open(op.join(tag_dir,'tag_syntax.vim'), 'w') as f:
        for kind in tag_list:
            for i in tag_list[kind]:
                syntax_str = "syntax keyword MF%s%s %s\n" % (filetype, tag_name[kind][0], i)
                f.write(syntax_str)
        for kind in tag_name:
            highlight_str = "highlight default link MF%s%s %s\n" % (filetype, tag_name[kind][0], tag_name[kind][1])
            f.write(highlight_str)

    return

if __name__ == "__main__":
    make_tag_syntax_file("../../tags","vim") 

