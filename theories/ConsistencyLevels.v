(** * Consistency levels *)
From Coq Require Import
     List.

Import ListNotations.

From LibTx Require Import
     SLOT.

Notation "'[[' a ']]'" := (fun x => x = a) (at level 2, a as pattern, only parsing).

Notation "'![[' a ']]'" := (fun x => x <> a) (at level 1, a as pattern, only parsing).

Section find_pairs.
  Context {T : Type}.
  Variable cause : T -> Prop.
  Variable effect : T -> Prop.
  Variable insert : T -> Prop.

  (* TODO: this implementation is inefficient *)
  Inductive pair : list T -> Prop :=
  | pair_found : forall a b t,
      cause a ->
      effect b ->
      pair (a :: b :: t)
  | pair_skip : forall a t,
      pair t ->
      pair (a :: t)
  | pair_insert : forall a b t,
      insert b ->
      pair (a :: t) ->
      pair (a :: b :: t).
End find_pairs.

Section defs.
  Context {TxId Key Value : Type}.

  Inductive Event :=
  | read : Key -> option Value -> TxId -> Event
  | write : Key -> option Value -> TxId -> Event
  | commit : TxId -> Event
  | abort : TxId -> Event.

  Definition History := list Event.

  (** Transaction has been committed: *)
  Definition committed (tx : TxId) history :=
    Exists [[ commit tx ]] history.

  Definition read_your_writes history : Prop :=
    forall tx (key : Key) (val1 val2 val3 : option Value),
      committed tx history ->
      pair [[ write key val1 tx ]]
           [[ read key val2 tx ]]
           ![[ write key val3 tx ]]
           history ->
      val1 = val2.

  Definition monotonic_reads history : Prop :=
    forall tx (key : Key) (val1 val2 val3 : option Value),
      committed tx history ->
      pair [[ read key val1 tx ]]
           [[ read key val2 tx ]]
           ![[ write key val3 tx ]]
           history ->
      val1 = val2.
End defs.
