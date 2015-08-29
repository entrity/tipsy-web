class IngredientsController < ApplicationController
  respond_to :json, :html
  MAX_RESULTS = 15

  def index
    @ingredients = Ingredient.default_scoped
    if params[:fuzzy].present?
      @ingredients = @ingredients.fuzzy_find(params[:fuzzy])
    elsif request.format.html?
      @ingredients = @ingredients.order(:name)
    end
    params[:exclude_ids].reject!{|item| item =~ /\D/ } if params[:exclude_ids].present?
    @ingredients = @ingredients.where(id:params[:id]) if params[:id].present?
    @ingredients = @ingredients.where('id NOT IN (?)', params[:exclude_ids]) if params[:exclude_ids].present?
    @ingredients = @ingredients.for_drink(params[:drink_id]) if params[:drink_id].present?
    @ingredients = @ingredients.select(params[:select]) if params[:select].present?
    @ingredients = @ingredients.paginate page:params[:page], per_page:MAX_RESULTS
    set_pagination_headers @ingredients
    respond_with @ingredients
  end

  def show
    get_ingredient
    if request.format.json?
      respond_with @ingredient
    else
      @canonical_url = 'http://tipsyology.com' + get_ingredient.url_path
      @drinks = @ingredient.drinks
        .order('random()')
        .limit(MAX_RESULTS)
    end
  end

  def edit
    render layout:'application', text:%q(<ng-include src="'/ingredients/edit.html'"></ng-include>)
  end
  alias_method :new, :edit

  def names
    if params[:id].blank?
      respond_with Hash.new
    else
      sql = Ingredient.where(id:params[:id]).select([:id,:name]).to_sql
      res = Ingredient.connection.execute(sql)
      map = Hash[res.map{|x| [x['id'], x['name']] }]
      respond_with map
    end
  end

  # Get published revisions
  def revisions
    @revisions = get_ingredient.revisions.where(status:Flaggable::APPROVED)
    respond_with @revisions
  end

  private

    def get_ingredient
      @ingredient ||= Ingredient.find params[:id]
    end

end
