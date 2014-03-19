require 'shellwords'
require 'dragonfly'

module Dragonfly
  class Shell

    # Exceptions
    class CommandFailed < RuntimeError; end

    def run(command, opts={})
      command = escape_args(command) unless opts[:escape] == false
      Dragonfly.debug("shell command: #{command}")
      run_command(command)
    end

    def escape_args(args)
      args.shellsplit.map do |arg|
        quote arg.gsub(/\\?'/, %q('\\\\''))
      end.join(' ')
    end

    def quote(string)
      q = Dragonfly.running_on_windows? ? '"' : "'"
      q + string + q
    end

    private

    # Annoyingly, Open3 seems buggy on jruby/1.8.7:
    # Some versions don't yield a wait_thread in the block and
    # you can't run sub-shells (if explicitly turning shell-escaping off)
    if RUBY_PLATFORM == 'java' || RUBY_VERSION < '1.9'

      # Unfortunately we have no control over stderr this way
      def run_command(command)
        result = `#{command}`
        status = $?
        raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus}" unless status.success?
        result
      end

    else

      def run_command(command)
        out = nil
        IO.popen(command) { |o| out = out.read; out.close }
        status = $?
        raise CommandFailed, "Command failed (#{command}) with exit status #{status.exitstatus}" unless status.success?
        out
      end

    end

  end
end
