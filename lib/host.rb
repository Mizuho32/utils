require 'pathname'
require 'socket'
require 'yaml'

# per-host layer: <root>/hosts/<hostname>/<component>/
module Host
  extend self

  # <root>/.host (not tracked) if exists, for machines sharing the same hostname
  def hostname(root)
    file = Pathname(root) / ".host"
    name = file.read.strip if file.exist?
    name.to_s.empty? ? Socket.gethostname[/^[^.]+/] : name
  end

  def dir(component_dir)
    component_dir = Pathname(component_dir).expand_path
    component_dir.parent / "hosts" / hostname(component_dir.parent) / component_dir.basename
  end

  # hosts/<hostname>/<component>/vars.yaml, nil if not exists
  def vars(component_dir)
    path = dir(component_dir) / "vars.yaml"
    YAML.load_file(path) if path.exist?
  end

  # <component>/loc.yaml with hosts/<hostname>/<component>/loc.yaml merged over it
  # nil in the latter removes the entry
  def loc(component_dir)
    common = YAML.load_file(Pathname(component_dir) / "loc.yaml", aliases: true)
    path   = dir(component_dir) / "loc.yaml"
    return common unless path.exist?

    deep_merge(common, YAML.load_file(path, aliases: true))
  end

  private def deep_merge(base, over)
    base.merge(over){|_, b, o|
      b.is_a?(Hash) && o.is_a?(Hash) ? deep_merge(b, o) : o
    }.compact
  end
end
