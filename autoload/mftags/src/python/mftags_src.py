
# for support of python2
from __future__ import print_function

import os
import os.path as op
import glob
import sys
import copy

g_tag_path = []
debug = 0
dic_ext_filetype = {'c':'c', 'h':'c', 'cpp':'cpp', 'py':'python', 'vim':'vim'}
g_func_list_dict = {}
str_split = '@-@-'
src_dir_path = ''

#just return
def search_tag(tag_files):
    tmp_tag_files = tag_files
    for tf in tag_files:
        g_tag_path.append(op.join(os.getcwd(), tf))
    if debug >= 2:
        print("get tag files: ", end="")
        print(g_tag_path)

    return

def set_src_path(path):
    global src_dir_path
    src_dir_path = path

def make_lang_list(fpath):
    lang_list = {}
    with open(fpath, 'r') as f:
        for line in f:
            line = line.replace('\n', '')
            if line.startswith('#') or (len(line) <= 2):
                continue
            if line.startswith('lang:'):
                lang = line[5:]
                if debug >= 3:
                    print(lang)
                lang_list[lang] = {}
            else:
                line = line[2:].split(' ')
                if debug >= 3:
                    print(line)
                # kind_char, kind, syntax_link
                kc, K, sl = line
                if sl == 'blank':
                    sl = ''
                lang_list[lang][kc] = [K,sl]

    return lang_list

def make_tag_syntax_file(tag_file_path, filetype, out_dir, enable_kinds):
    """ This function makes syntax setting file at the same directory of tag file.
        tag_file_path: path to tag file.
        file type: current opening file type. ex) c, c++, python ...
        out_dir: directory where syntax file put.
        enable_kinds: ctags kinds which this func. make syntax of.
    """

    lang_list = make_lang_list(op.join(src_dir_path,'src/txt/mftags_lang_list'))
    if debug >= 3:
        for k in lang_list:
            print(k)
            print(lang_list[k])
    if filetype in lang_list:
        tag_name = lang_list[filetype]
        tag_list = {}
        for kc in tag_name:
            tag_list[kc] = []
    else:
        print("not supported file type")
        return

    tag_file_path = tag_file_path.replace('/',os.sep)   #adjust os path problem.
    with open(tag_file_path, 'r') as f:
        for line in f:
            if line.startswith('!'):
                continue
            line = line.replace("\n","")
            kind = line[line.rfind('"')+2]
            line = line.split("\t")
            name = line[0]
            fname = line[1]
            ftype = fname[fname.rfind(".")+1:]
            # exclude incorrect filetype
            if ftype in list(dic_ext_filetype.keys()):
                if dic_ext_filetype[ftype] != filetype:
                    continue
            else:
                # include no extention file
                if ftype != fname:
                    continue

            try:
                tag_list[kind].append(name)
            except KeyError:
                if debug >= 1:
                    print("\nThis is not a correct kind.")
                    print("language : ",filetype, "kind : ",kind)
                continue
    
    """
    for k in tag_list:
        print k
        print tag_list[k]
    """

    vim_ignore_strs = ["[","]"]
    syntax_file = op.join(out_dir, '.%s_tag_syntax.vim' % filetype)
    with open(syntax_file, 'a') as f:
        f.write('" from '+tag_file_path+'\n')
        for kind in tag_list:
            if not (kind in enable_kinds):
                continue
            for i in tag_list[kind]:
                syntax_str = "syntax keyword MF%s%s %s\n" % (filetype, tag_name[kind][0], i.replace(' ', '\ '))
                for vis in vim_ignore_strs:
                    if vis in i:
                        syntax_str = '"'+syntax_str
                        break
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
        syntax_file = op.join(out_dir, '.%s_tag_syntax.vim' % filetype)
        with open(syntax_file, 'w') as f:
            'remove tag syntax file'

    for tagfile in g_tag_path:
        make_tag_syntax_file(tagfile, filetype, out_dir, enable_kinds)

def make_tag_list(tag_dict):
    """ make list from tag dictionary """
    tag_list = tag_dict.keys()
    # needless because keys doesn't overlap.
    # tag_list = list(set(tag_list))
    # but, in python3, type of tag_list is not list, it is dict_key.
    tag_list = list(tag_list)
    tag_list.sort()
    return tag_list

def return_list_from_tag(filetype, return_kind):
    """ This function makes a list of functions, variables, etc..
        file type: current opening file type. ex) c, c++, python ...
        return_kind: a character of the kind which this function returns.
    """
    global g_func_list_dict
    if (filetype in g_func_list_dict) and (return_kind in g_func_list_dict[filetype]):
        if debug >= 1:
            print("already exists buffer. {} {}".format(filetype, return_kind))
        tag_list = make_tag_list(g_func_list_dict[filetype][return_kind])
        tag_list.insert(0, g_func_list_dict[filetype][return_kind+'_0'])
        return tag_list

    lang_list = make_lang_list(op.join(src_dir_path,'src/txt/mftags_lang_list'))
    if debug >= 3:
        for k in lang_list:
            print(k)
            print(lang_list[k])
    if filetype in lang_list:
        if return_kind in lang_list[filetype]:
            tag_name = lang_list[filetype][return_kind][0]
            tag_dict = {}
        else:
            print("not supported kind '%s' for file type '%s'"  % (return_kind, filetype))
            return
    else:
        print("not supported file type '%s' " % filetype)
        return

    for tag_path in g_tag_path:
        if debug >= 2:
            print("tag file:: %s" % tag_path)
        tag_path = tag_path.replace('/',os.sep)   #adjust os path problem.
        with open(tag_path, 'r') as f:
            for line in f:
                if line.startswith('!'):
                    continue
                line = line.replace("\n","")
                kind = line[line.rfind('"')+2]
                def_str = line[line.find('/^')+2:line.rfind('$/;"')]
                def_str = def_str.replace('\\\\', str_split)
                def_str = def_str.replace('\\', '')
                def_str = def_str.replace(str_split, '\\')
                line = line.split("\t")
                name = line[0]
                fname = op.join(op.dirname(tag_path),line[1])
                ftype = fname[fname.rfind(".")+1:]
                # excepting incorrect filetype
                if ftype in list(dic_ext_filetype.keys()):
                    if dic_ext_filetype[ftype] != filetype:
                        continue
                if kind == return_kind:
                    try:
                        tag_key = "\t\t"+name
                        if tag_key in tag_dict:
                            tag_dict[tag_key].append(fname+str_split+def_str)
                        else:
                            tag_dict[tag_key] = [fname+str_split+def_str]
                    except KeyError:
                        if debug >= 1:
                            print("\nThis is not a correct kind.")
                            print("language : ",filetype, "kind : ",kind)
                        continue
    if debug >= 2:
        print("tag_dict: ", end="")
        print(tag_dict)
    
    if filetype not in g_func_list_dict:
        g_func_list_dict[filetype] = {}

    g_func_list_dict[filetype][return_kind] = copy.deepcopy(tag_dict)
    g_func_list_dict[filetype][return_kind+'_0'] = "\t"+tag_name
    tag_list = make_tag_list(tag_dict)
    tag_list.insert(0, g_func_list_dict[filetype][return_kind+'_0'])
    return tag_list

def show_list_on_buf(filetypes, return_kinds):
    """ this function add lines about kind to current buffer
        file type: list of file types. ex) c, c++, python ...
        return_kinds: list of character(s) of the kind which this function returns.
    """

    #import vim
    cur_buf = vim.current.buffer
    clean_buf()

    #print text in buffer
    if debug >= 1:
        print('filetypes:{}'.format(filetypes))

    for i,fy in enumerate(filetypes):
        cur_buf.append('---{}---'.format(fy))
        for k in return_kinds[i]:
            kind_list = return_list_from_tag(fy, k)
            if debug >= 2:
                print('kind list: ', end='')
                print(kind_list)
            if kind_list == None:
                return
            for kl in kind_list:
                cur_buf.append(kl)

            cur_buf.append("")

def jump_func(filetype, kind, tag_name):
    """ this function searches the function or something like that
        and returnes the file and line
        filetype: current opening file type. ex) c, c++, python ...
        tag_name: string of a line MFfunclist window.
    """

    kind_list = make_lang_list(op.join(src_dir_path,'src/txt/mftags_lang_list'))[filetype]
    for kc in kind_list:
        if kind_list[kc][0] == kind:
            kind = kc
    if len(kind) != 1:
        if debug >= 1:
            print('cannot find kind character for %s. return.' % kind)
        return
    def_list = g_func_list_dict[filetype][kind][tag_name]
    if len(def_list) == 1:
        fy, ly = def_list[0].split(str_split)
        if debug >= 2:
            print('searching:: %s in %s' % (ly, fy))
        with open(fy) as f:
            for lnum,line in enumerate(f):
                if ly in line:
                    ret = 'silent e +%d %s' % (lnum+1, fy)
                    if debug >= 1:
                        print('1; '+ret)
                    vim.command(ret)
                    return
    else:
        file_list = []
        line_list = []
        for ls in def_list:
            fy, ly = ls.split(str_split)
            if debug >= 2:
                print('searching:: %s in %s' % (ly, fy))
            with open(fy, 'r') as f:
                for lnum,line in enumerate(f):
                    if ly in line:
                        file_list.append(fy)
                        line_list.append(lnum+1)

        file_num = len(file_list)
        if file_num == 0:
            print("can't find matching line.")
            return

        for num in range(file_num):
            print('  %d  %s :  %d lines' % (num, file_list[num], line_list[num]))

        """ python in vim doesn't support input. {{{
        if sys.version_info[0] == 2:
            in_num = raw_input('Type number and <Enter> (empty cancels) ')
        else:
            in_num = input('Type number and <Enter> (empty cancels) ')

        try:
            in_num = int(in_num)
        except ValueError:
            return

        ret = 'e +%d %s' % (line_list[in_num], file_list[in_num])
        if debug >= 2:
            print('2; '+ret)
        vim.command(ret)
        return
        }}} """
        vim.command('let g:tmp_dic = {}')
        for i in range(file_num):
            vim.command('let g:tmp_dic[%d] = ["%s", "%d"]' % (i, file_list[i], line_list[i]))
        if debug >= 1:
            print()
            print('2; set vim variables')
        return

def show_def(filetype, kind, tag_name):
    """ search and display the definition of the function/variable/class/ etc...
        this function is for mapping of <space><space>
    """
    kind_list = make_lang_list(op.join(src_dir_path,'src/txt/mftags_lang_list'))[filetype]
    for kc in kind_list:
        if kind_list[kc][0] == kind:
            kind = kc
    if len(kind) != 1:
        if debug >= 1:
            print('cannot find kind character for %s. return.' % kind)
        return
    for ly in g_func_list_dict[filetype][kind][tag_name]:
        print(ly.split(str_split)[1])

def clean_tag():
    global g_tag_path
    g_tag_path = []
    if debug >= 1:
        print("clean tag path file")
        print(g_tag_path)

def clean_buf():
    #import vim
    cur_buf = vim.current.buffer

    # buffer clear
    cur_buf[:] = None

def delete_buffer():
    global g_func_list_dict
    if debug >= 1:
        print("clean buffer\n", g_func_list_dict)
    g_func_list_dict = {}

# search function {{{
""" 
def search_tag(tags, file_path):
    ##ref: http://vim-jp.org/vim-users-jp/2010/06/13/Hack-154.html
    # ./tags ... search from opening file
    # tags ... search from current directory
    tags = tags.replace(os.sep,'/')
    tags = tags.split(',')
    global g_tag_path
    if debug:
        print g_tag_path

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
""" # }}}

