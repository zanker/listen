require "spec_helper"

describe Listen::Adapters::Java do
  if jruby_with_java51?
    if Listen::Adapters::Java.usable?
      it "is usable when using JRuby on Java 1.7+" do
        described_class.should be_usable
      end

      it_should_behave_like "a filesystem adapter"
      it_should_behave_like "an adapter that call properly listener#on_change"
    else
      it "isn't usable on #{RUBY_ENGINE}" do
        described_class.should_not be_usable
      end
    end

  else
    it "isn't usable without JRuby on Java 1.7+" do
      described_class.should_not be_usable
    end
  end
end
