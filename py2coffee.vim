"silent! %s/    /  /g
silent! %s/\vdef (.*)(\(.*\)):/\1: \2 ->/
for i in [1, 2, 3, 4, 5]
  silent! %s/\v[a-z]@<=_([a-z])%([a-z]*: )@=/\u\1/i
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
