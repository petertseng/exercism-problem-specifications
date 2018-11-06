# can use list-tracks to update this.
TRACKS = %w(
ballerina
bash
c
ceylon
cfml
clojure
coffeescript
common-lisp
coq
cpp
crystal
csharp
d
dart
delphi
elisp
elixir
elm
erlang
factor
fortran
fsharp
gnu-apl
go
groovy
haskell
haxe
idris
java
javascript
julia
kotlin
lfe
lua
mips
nim
objective-c
ocaml
perl5
perl6
pharo
php
plsql
pony
powershell
prolog
purescript
python
r
racket
reasonml
ruby
rust
scala
scheme
sml
swift
typescript
vbnet
vimscript
)

`mkdir -p configs`

TRACKS.each { |t|
  puts t
  `wget -O configs/#{t}.json https://raw.githubusercontent.com/exercism/#{t}/master/config.json`
  sleep 1
}
