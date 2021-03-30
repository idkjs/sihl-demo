let ml_template =
  {|
include Model

exception Exception of string

let clean =
  if Sihl.Configuration.is_production ()
  then
    raise
    @@ Exception
         "Could not clean repository in production, this is most likely not what \
          you want."
  else Repo.clean
;;

let find name = Repo.find name
let query = Repo.find_all

let insert ({{name}} : t) =
  let open Lwt.Syntax in
  let* found = find {{name}}.name in
  match found with
  | None ->
    let* () = Repo.insert {{name}} in
    let* inserted = Repo.find {{name}}.name in
    (match inserted with
    | Some {{name} -> Lwt.return (Ok {{name}})
    | None ->
      Logs.err (fun m ->
          m "Failed to insert {{name}} '%a'" pp {{name});
      Lwt.return @@ Error "Failed to insert {{name}}")
  | Some _ ->
    Lwt.return
    @@ Error (Format.sprintf "{{name}} '%s' already exists" {{name}}.name)
;;

let create {{create_args}} : (t, string) Result.t Lwt.t =
  let open Lwt.Syntax in
  let* {{name}} = find name in
  match {{name}} with
  | None -> insert @@ create {{create_args}}
  | Some {{name}} ->
    Lwt.return
      (Error (Format.sprintf "{{name}} '%s' already exists" {{name}}.name))
;;

let update _ ({{name}} : t) =
  let open Lwt.Syntax in
  let* () = Repo.update {{name}} in
  let* updated = Repo.find {{name}}.id in
  match updated with
  | Some updated -> Lwt.return (Ok updated)
  | None -> Lwt.return @@ Error "Failed to update {{name}}"
;;

let delete ({{name}} : t) =
  Repo.delete {{name}} |> Lwt.map Result.ok
;;
|}
;;

let mli_template =
  {|
type t = {{model_type}}

val schema : (unit, {{ctor_type}}, t) Conformist.t

exception Exception of string

val clean : unit -> unit Lwt.t
val find : string -> t option Lwt.t
val query : unit -> t list Lwt.t
val create : string -> bool -> int -> (t, string) result Lwt.t
val insert : t -> (t, string) result Lwt.t
val update : string -> t -> (t, string) result Lwt.t
val delete : t -> (unit, string) result Lwt.t
|}
;;

let mli_params =
  [ "model_type", "{ name : string }"
  ; "ctor_type", "string -> bool -> int -> t"
  ]
;;

let generate (name : string) (schema : Gen_core.schema) : unit =
  let create_args =
    schema |> List.map ~f:(fun (name, _) -> name) |> String.concat ~sep:" "
  in
  let ml_path = Format.sprintf "app/context/%s/%s.ml" name name in
  Gen_core.write_file
    ml_template
    [ "name", name; "create_args", create_args ]
    ml_path;
  let mli_path = Format.sprintf "app/context/%s/%s.mli" name name in
  Gen_core.write_file
    mli_template
    [ "model_type", Gen_model.model_type schema
    ; "ctor_type", Gen_model.ctor_type schema
    ]
    mli_path
;;
