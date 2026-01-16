module RedmineCkeditor
  module TempfilePatch
    def initialize(basename="", tmpdir=nil, mode: 0, **options)
      super.tap do |f|
        f.binmode if basename == "raw-upload."
      end
    end
  end
end

Tempfile.prepend RedmineCkeditor::TempfilePatch
