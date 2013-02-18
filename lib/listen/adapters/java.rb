module Listen
  module Adapters
    class Java < Adapter
      extend DependencyManager

      def initialize(directories, options = {}, &callback)
        super
        @threads, @watchers = [], []

        java_import java.nio.file.StandardWatchEventKinds
        java_import java.nio.file.Path
        java_import java.nio.file.FileSystems
      end

      # Starts the adapter.
      #
      # @param [Boolean] blocking whether or not to block the current thread after starting
      #
      def start(blocking = true)
        @mutex.synchronize do
          return if @stop == false
          super
        end

        init_worker

        @poll_thread = Thread.new { poll_changed_dirs } if @report_changes
        @threads.each {|t| t.join} if blocking
      end

      # Stops the adapter.
      #
      def stop
        @mutex.synchronize do
          return if @stop == true
          super
        end

        @watchers.each {|w| w.close if w.open?}
        @threads.each {|t| t.terminate}

        @poll_thread.join if @poll_thread
      end

      # Checks if we're running JRuby and Java 1.7 or higher
      #
      # @return [Boolean] whether usable or not
      #
      def self.usable?
        unless RUBY_ENGINE == "jruby" and java.lang.System.getProperties["java.class.version"].to_f >= 51
          return false
        end

        super
      end

    private
      def init_worker
        @threads = @directories.map do |d|
          Thread.new(d) do |directory|
            begin
              directory = File.expand_path("#{directory}")

              # Convert the directory into a Java path
              path = FileSystems.getDefault().getPath(directory)
              puts path.to_s
              # Get the watcher
              watcher = path.getFileSystem().newWatchService()
              # Register what events we want
              path.register(watcher, StandardWatchEventKinds::ENTRY_CREATE, StandardWatchEventKinds::ENTRY_MODIFY, StandardWatchEventKinds::ENTRY_DELETE)

              @watchers.push(watcher)

              event = nil
              while true do
                event = watcher.take

                unless @paused
                  @mutex.synchronize do
                    event.pollEvents.each do |event|
                      # Using the event context will return a path relative to the cwd rather than the watched directory
                      # which is why we have to resolve the path.
                      @changed_dirs << File.dirname(path.resolve(event.context).to_s)
                    end
                  end
                end

                # Event is no longer valid (file deleted for example)
                # reset must be called or else it will never receive another event
                unless event.reset
                  event.cancel
                end
              end

              event.cancel if event

            rescue java.nio.file.ClosedWatchServiceException
            end
          end
        end
      end
    end

  end
end