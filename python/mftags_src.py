
import os
import os.path as op
import glob

g_tag_path = []

def search_tag(tags, file_path):
    ##ref: http://vim-jp.org/vim-users-jp/2010/06/13/Hack-154.html
    # ./tags ... search from opening file
    # tags ... search from current directory
    tags = tags.replace(os.sep,'/')
    tags = tags.split(',')
    global g_tag_path

    for tag in tags:
        bottomup = False
        print "\ninput tag:: ",tag
        if "**" in tag:
            print 'Now this function does not support "**"'
            continue
        if ';' in tag:
            top_dir = tag[tag.find(';')+1:]
            if top_dir.endswith(os.sep):
                top_dir = top_dir[:-1]
            tag = tag[:tag.find(';')]
            bottomup = True
            print "top: ",top_dir

        if tag.startswith('./'):
            tag = tag[2:]
            cwd = op.dirname(file_path)
        else:
            cwd = os.getcwd()
        files = glob.glob(op.join(cwd,tag))
        if bottomup:
            tag_file_name = op.basename(tag)
            if '*' in tag:
                tag = tag[:tag.find('*')]
            cdir = op.join(cwd, tag)
            while cdir != '':
                tf = op.join(cdir,tag_file_name)
                if op.isfile(tf):
                    files.append(tf)
                cdir = cdir[:cdir.rfind(os.sep)]
                if cdir.endswith(':'):
                    #for windows
                    break
                print "cdir:: ",cdir

        print files
        g_tag_path += files
    return

def make_tag_syntax_file(file_path, filetype):
    """ This function makes syntax setting file at the same directory of tag file.
        file_path: path to tag file.
        file type: current opening file type. ex) c, c++, python ...
    """
    from mftags_lang_list import lang_list
    file_path = file_path.replace('/',os.sep)   #adjust os path problem.
    if lang_list.has_key(filetype):
        tag_list,tag_name = lang_list[filetype]
    else:
        print "not supported file type"
        exit

    with open(file_path) as f:
        for line in f:
            if line.startswith('!'):
                continue
            line = line.replace("\n","")
            kind = line[line.rfind('"')+2]
            line = line.split("\t")
            name = line[0]
            try:
                tag_list[kind].append(name)
            except KeyError:
                print "\nThis is not a correct kind."
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

def make_tag_syntax_files(filetype):
    print g_tag_path
    """
    for tagfile in g_tag_path:
        make_tag_syntax_file(tagfile, filetype)
    """

if __name__ == "__main__":
    #make_tag_syntax_file("../../tags","vim") 
    #search_tag('tags;,./tags;,./tags;/Users/fujino/workspace/work/test/,/Users/fujino/workspace/work/tags,./../*/tags;','path/to/file')
    print 'read mftag_src.py'

