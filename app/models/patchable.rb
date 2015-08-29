module Patchable

  module ClassMethods
    def publishable_field field, opts={}
      publishable_fields << Field.new(field, opts)
    end

  end

  def self.included(base)
    class << base
      attr_accessor :publishable_fields
    end
    base.publishable_fields = []
    base.extend(ClassMethods)
  end

  # Make a diff between prev & post; then apply the diff as a patch to target
  # @return patched target
  def self.patch prev, post, target
    patcher = DiffMatchPatch.new
    patches = patcher.patch_make(prev, post)
    text, results = patcher.patch_apply(patches, target)
    return text
  end

  def publish!
    # Set revision_id
    patchable.revision_id = id
    # Iterate publishable fields
    self.class.publishable_fields.each do |obj|
      obj.patch? ? obj.patch(self, false) : obj.set(self, patchable)
    end
    # Yield
    yield if block_given?
    # Save changes
    patchable.save!
    super # Flaggable.publish!
  end

  # Set status and rollback revisable's revision
  def unpublish!
    # Get latest approved revision (or current revision's parent, in case of data failure)
    last_revision = patchable.revisions.where(status:Flaggable::APPROVED).last || parent
    # Set revision_id
    patchable.revision_id = last_revision.try(:id)
    # Iterate publishable fields
    self.class.publishable_fields.each do |obj|
      obj.patch? ? obj.patch(self, true) : obj.set(last_revision, patchable)
    end
    # Yield
    yield if block_given?
    # Save changes
    patchable.save!
    super # Flaggable.publish!
  end

  class Field
    attr_reader :field, :opts

    # @param field - If it is a Proc, it gets called on prev_obj and post_obj.
    # You must specify option :prev_key to override this.
    # @param opts
    #   - :patch
    #   - :prev_key - name of field on prev_object if different than default
    #   - :foreign_key - name of field on patchable (if different than field). This is required if field is a Proc
    def initialize field, opts
      @field = field
      @opts = opts
    end

    def patch?
      @opts[:patch] # Patch difference between
    end

    # Set patchable[foreign_key] by patch
    def patch revision, reverse=false
      prev, post = reverse ? [curval(revision), preval(revision)] : [preval(revision), curval(revision)]
      target     = revision.patchable[foreign_key]
      revision.patchable.assign_attributes(foreign_key => Patchable.patch(prev||'', post||'', target||''))  
    end

    # Set patchable[foreign_key] by simple copy
    # @param patchable is needed becaues revision may be nil
    def set revision, patchable
      val = curval(revision)
      unless val.nil? && @opts[:allow_nil] == false
        patchable.assign_attributes(foreign_key =>  val)
      end
    end

    def getval(obj, *keys)
      if obj
        output = nil
        keys.each do |key|
          next if key.nil?
          if key.is_a?(Proc)
            break output = obj.instance_eval(&key)
          elsif obj.respond_to?(key)
            break output = obj.send(key)
          end
        end
        output
      end
    end

    def preval(obj)
      keys = [@opts[:prev_key], field.is_a?(Proc) ? field : "prev_#{field}"]
      output = getval(obj, *keys)
      if output.nil? # Set and return value from patchable if nil on obj
        keys.each do |key|
          if (key.is_a?(String) || key.is_a?(Symbol)) && obj.respond_to?(key)
            obj.assign_attributes key => obj.patchable[foreign_key]
            break obj[key]
          end
        end
      else
        output
      end
    end

    def curval(obj)
      getval(obj, field)
    end

    def foreign_key
      @opts[:foreign_key] || field
    end

  end

end
