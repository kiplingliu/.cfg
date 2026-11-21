$env.config.show_banner = "short"
$env.config.edit_mode = "vi"

$env.config.history.file_format = "sqlite"
$env.config.history.isolation = true

$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"

$env.config.completions.algorithm = "substring"

$env.config.keybindings ++= [
  {
    modifier: control
    keycode: char_u
    mode: vi_insert
    event: { edit: cutfromstart }
  }
  {
    modifier: control
    keycode: 'char_['
    mode: vi_insert
    event: {
      send: switchmode
      mode: vi_normal
    }
  }
]

alias ll = ls -l

# Doesn't work b/c nu sends literal unevaluated strings to the completer
# alias cfg = git $"--git-dir=($nu.home-dir | path join .cfg)" $"--work-tree=($nu.home-dir)"

def cfg-env [] {
  { GIT_DIR: ($nu.home-dir | path join .cfg), GIT_WORK_TREE: $nu.home-dir }
}
def "nu-complete cfg" [place: record] {
  with-env (cfg-env) {
    carapace git nushell git ...($place.command | skip 1) | from json
  }
}
def --wrapped cfg [...args: string@"nu-complete cfg"] {
  with-env (cfg-env) { git ...$args }
}

def pwsh-json [script: string] {
  let wrapped = $"& { ($script) } 6>$null | ConvertTo-Json"
  pwsh -NoProfile -Command $wrapped | from json
}

def regen [bin: string, file: string, gen: closure] {
  let exe = which $bin | get -o 0.path
  if $exe == null { return }
  let out = $nu.user-autoload-dirs | first | path join $file
  if not ($out | path exists) or ((ls -D $exe).0.modified > (ls $out).0.modified) {
    mkdir ($out | path dirname)
    do $gen | save -f $out
  }
}

regen carapace 01-carapace.nu {|| carapace _carapace nushell }
regen fzf fzf.nu {|| fzf --nushell }
regen zoxide zoxide.nu {|| zoxide init nushell }

