s" out.txt" w/o create-file throw value fd-out
s" Hello, world!" fd-out write-line
fd-out close-file throw
bye
