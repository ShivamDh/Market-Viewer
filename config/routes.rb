Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root 'stock#index'

  post 'stock/delete_stock/:id' => 'stock#delete_stock', as: 'stock'

end
