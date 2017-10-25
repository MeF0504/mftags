
import os
import os.path as op
import glob

g_tag_path = []
debug = False

def search_tag(tags, file_path):
    ##ref: http://vim-jp.org/vim-users-jp/2010/06/13/Hack-154.html
    # ./tags ... search from opening file
    # tags ... search from current directory
    tags = tags.replace(os.sep,'/')
    tags = tags.split(',')
    global g_tag_path

    for tag in tags:
        bottomup = False
        if debug:
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
            if debug:
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
                if debug:
                    print "cdir:: ",cdir

        if debug:
            print files
        g_tag_path += files

    g_tag_path = list(set(g_tag_path))
    for g_tag in g_tag_path:
        print 'read tag file at ',g_tag
    return

def make_tag_syntax_file(file_path, filetype, out_dir, enable_kinds):
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
        exit()

    with open(file_path, 'r') as f:
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
                if debug:
                    print "\nThis is not a correct kind."
                    print "language : ",filetype, "kind : ",kind
                continue
    
    """
    for k in tag_list:
        print k
        print tag_list[k]
    """

    syntax_file = op.join(out_dir, '%s_tag_syntax.vim' % filetype)
    with open(syntax_file, 'a') as f:
        for kind in tag_list:
            if not (kind in enable_kinds):
                continue
            for i in tag_list[kind]:
                syntax_str = "syntax keyword MF%s%s %s\n" % (filetype, tag_name[kind][0], i)
                f.write(syntax_str)
        for kind in tag_name:
            if tag_name[kind][1] == '':
                continue
            highlight_str = "highlight default link MF%s%s %s\n" % (filetype, tag_name[kind][0], tag_name[kind][1])
            f.write(highlight_str)

        f.write('highlight default MFdef ctermfg=213 guifg=Orchid1\n\n')

    return

def make_tag_syntax_files(filetype, out_dir, overwrite, enable_kinds):
    if overwrite == '1':
        syntax_file = op.join(out_dir, '%s_tag_syntax.vim' % filetype)
        with open(syntax_file, 'w') as f:
            'remove tag syntax file'

    for tagfile in g_tag_path:
        make_tag_syntax_file(tagfile, filetype, out_dir, enable_kinds)

