open Sihl.Web.Http

(* All the HTML HTTP entry points are listed here.

   Don't put actual logic here to keep it declarative and easy to read. The
   overall scope of the web app should be clear after scanning the routes. *)

let middlewares =
  [ Opium.Middleware.content_length
  ; Opium.Middleware.etag
  ; Sihl.Web.Middleware.session ()
  ; Sihl.Web.Middleware.form
  ; Sihl.Web.Middleware.csrf ()
  ; Sihl.Web.Middleware.flash ()
  ; Sihl.Web.Middleware.user (fun user_id -> Service.User.find_opt ~user_id)
  ]
;;

(* TODO [jerben] add authentication middleware *)
let router_private =
  Sihl.Web.Http.router
    ~middlewares
    ~scope:"/"
    [ get "/ingredients" Handler.Ingredients.index
    ; post "/ingredients" Handler.Ingredients.create
    ; post "/ingredients/:name/delete" Handler.Ingredients.delete
    ; get "/pizzas" Handler.Pizzas.index
    ; post "/pizzas" Handler.Pizzas.index
    ; delete "/pizzas/:name" Handler.Pizzas.delete
    ]
;;

let router_public =
  Sihl.Web.Http.router
    ~middlewares
    ~scope:"/"
    [ get "/" Handler.Welcome.index
    ; get "/login" Handler.Auth.login_index
    ; post "/login" Handler.Auth.login_create
    ; get "/registration" Handler.Auth.registration_index
    ; post "/registration" Handler.Auth.registration_create
    ]
;;
