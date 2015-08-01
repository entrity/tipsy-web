module Patchable

  # Make a diff between prev & post; then apply the diff as a patch to target
  # @return patched target
  def patch prev, post, target
    patcher = DiffMatchPatch.new
    patches = patcher.patch_make(prev, post)
    text, results = patcher.patch_apply(patches, target)
    return text
  end

end
