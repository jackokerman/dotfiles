def executable_paths(command)
  paths = []
  search_path = [
    ENV.fetch("PATH", ""),
    ENV.fetch("HOMEBREW_DOTFILES_HOST_PATH", ""),
  ].join(File::PATH_SEPARATOR)

  search_path.split(File::PATH_SEPARATOR).each do |dir|
    path = File.join(dir, command)
    next unless File.file?(path) && File.executable?(path)

    paths << begin
      File.realpath(path)
    rescue StandardError
      path
    end
  end

  paths.uniq
end

def homebrew_managed_path?(path)
  prefix = ENV["HOMEBREW_PREFIX"].to_s
  return false if prefix.empty?

  real_prefix = begin
    File.realpath(prefix)
  rescue StandardError
    prefix
  end

  path == real_prefix || path.start_with?("#{real_prefix}/")
end

def host_provides_command?(command)
  executable_paths(command).any? { |path| !homebrew_managed_path?(path) }
end
