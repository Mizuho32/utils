function noasdf
  set PATH (string match -v $HOME/.asdf/shims $PATH)
  set PATH (string match -v $HOME/.asdf/bin $PATH)
end
