
"pyfile <sfile>:h:h/src/hello.py
pyfile <sfile>:h/test1.py

let s:values = []
let s:functions = []

python import vim

"python test1_func(vim.eval("s:values"), vim.eval("s:functions"))
"python vim.eval("s:values") = test1_func()
python print test1_func()
python vim.command("let s:str = '%s'" % "ssttrr")

echo s:values
echo s:functions
echo s:str

