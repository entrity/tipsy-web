class IngredientRevisionsController < RevisionsController

  private

    def revision_params
      params.permit(
        :ingredient_id,
        :parent_id,
        :name,
        :description,
        :prev_description,
        :canonical_id,
        :prev_canonical_id,
      )
    end
end
