"silent! %s/    /  /g
silent! %s/\vdef (.*)(\(.*\)):/\1: \2 ->/
for i in [1, 2, 3, 4, 5]
  silent! %s/\v[a-z]@<=_([a-z])%([a-z]*: .*-\>$)@=/\u\1/i
  silent! %s/\v[a-z]@<=_([a-z])%([a-z]*\()@=/\u\1/i
endfor
silent! %s/\v\(self, /(/
silent! %s/\v\(self\) -\>/->/
silent! %s/\vself\./@/g
silent! %s/\v:$//
silent! %s/\v\{0\}(.*)\.format\((.{-})\)/#{\2}\1
silent! %s/__init__/constructor/
silent! %s/None/null/g
silent! %s/\v:@<! \((.{-},.{-})\)%( -\>)@!/ [\1]/g
silent! %s/\vjson.dumps\(/JSON.stringify(/g
silent! %s/\vjson.loads\(/JSON.parse(/g
silent! %s/"""/###/g
silent! %s/ elif / else if /g
for i in [1, 2, 3, 4, 5]
  silent! %s/\n\n\n/\r\r/g
endfor
silent! %s/ is not null/ isnt null/g

silent! %s/\v\@assertEqual\((.*), (.*)\)/\1.should.equal \2/
silent! %s/\v\@assertTrue\((.*)\)/\1.should.be.true/
silent! %s/\v\@assertFalse\((.*)\)/\1.should.be.false/
silent! %s/\v%(^[^"]*)@<=u"/"/g
silent! %s/\vu"%([^"]*"[^"]*$)@=/"/g
for i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  silent! %s/\v%(^ *test[a-z ]*)@<=([A-Z])%([a-zA-Z]*: )@=/ \l\1/g
endfor
silent! %s/\v%(^ *)@<=test ([a-z ]*): /it '\1', /g
silent! %s/\vclass ([A-Za-z]+)TestCase\(.*\)/describe '\1', ->/
silent! %s/\vclass ([A-Za-z]+)\(object\)/class \1/
silent! %s/\vclass ([A-Za-z]+)\((.*)\)/class \1 extends \2/
silent! %s/\*args/args/g
silent! %s/\*\*kwargs/kwargs/g
silent! %s/\v\[([0-9]+):\]/.substr(\1)/g
silent! %s/\v([^ ]*)\.copy\(\)/JSON.parse(JSON.stringify(\1))/g
