Rails.application.routes.draw do
  root "application#home"
  get "/dashboard", to: "application#dashboard"
  post "nova/", to: "application#nova"
end
