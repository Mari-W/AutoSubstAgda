module Kits where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; drop; _++_)
open import Data.List.Membership.Propositional public using (_∈_)
open import Data.List.Relation.Unary.Any public using (here; there)
open import Data.List.Relation.Unary.All as All public using (All; []; _∷_)
open import Data.Product using (∃-syntax; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong; subst; module ≡-Reasoning)
open ≡-Reasoning

infix  4  _∋_

data _∋_ {ℓ} {A : Set ℓ} : List A → A → Set ℓ where
  zero  : ∀ {xs x} → (x ∷ xs) ∋ x
  suc   : ∀ {xs x y} → xs ∋ x → (y ∷ xs) ∋ x

data SortTy : Set where Var NoVar : SortTy

record Syntax : Set₁ where
  field
    Sort         : SortTy → Set
    _⊢_          : ∀ {st} → List (Sort Var) → Sort st → Set
    `_           : ∀ {S} {s : Sort Var} → S ∋ s → S ⊢ s
    `-injective  : ∀ {S s} {x₁ x₂ : S ∋ s} → ` x₁ ≡ ` x₂ → x₁ ≡ x₂

  private variable
    st                         : SortTy
    s s₁ s₂ s₃ s' s₁' s₂' s₃'  : Sort st
    S S₁ S₂ S₃ S' S₁' S₂' S₃'  : List (Sort Var)
    x y z x₁ x₂                : S ∋ s

  Scoped = List (Sort Var) → Sort Var → Set

  variable _∋/⊢_  _∋/⊢₁_ _∋/⊢₂_ : Scoped

  record Kit (_∋/⊢_ : List (Sort Var) → Sort Var → Set) : Set where
    field
      -- Operations
      id/`            : S ∋ s → S ∋/⊢ s
      `/id            : S ∋/⊢ s → S ⊢ s
      wk              : ∀ s' → S ∋/⊢ s → (s' ∷ S) ∋/⊢ s

      -- Axioms
      `/`-is-`        : ∀ (x : S ∋ s) → `/id (id/` x) ≡ ` x
      id/`-injective  : id/` x₁ ≡ id/` x₂ → x₁ ≡ x₂
      `/id-injective  :  ∀ {x/t₁ x/t₂ : S ∋/⊢ s} →
                         `/id x/t₁ ≡ `/id x/t₂ → x/t₁ ≡ x/t₂
      wk-id/`         :  ∀ s' (x : S ∋ s) →
                         wk s' (id/` x) ≡ id/` (suc x)

    _→ₖ_ : List (Sort Var) → List (Sort Var) → Set
    S₁ →ₖ S₂ = ∀ s → S₁ ∋ s → S₂ ∋/⊢ s

    infixl  8  _&_
    _&_ : S₁ ∋ s → S₁ →ₖ S₂ → S₂ ∋/⊢ s
    x & ϕ = ϕ _ x 

    wkm : ∀ s → S₁ →ₖ S₂ → S₁ →ₖ (s ∷ S₂)
    wkm s ϕ _ x = wk s (ϕ _ x)

    _∷ₖ_ : S₂ ∋/⊢ s → S₁ →ₖ S₂ → (s ∷ S₁) →ₖ S₂
    (x/t ∷ₖ ϕ) _ zero     = x/t
    (x/t ∷ₖ ϕ) _ (suc x)  = ϕ _ x

    _↑_ : S₁ →ₖ S₂ → ∀ s → (s ∷ S₁) →ₖ (s ∷ S₂)
    ϕ ↑ s = id/` zero ∷ₖ wkm s ϕ

    _↑*_ : S₁ →ₖ S₂ → ∀ S → (S ++ S₁) →ₖ (S ++ S₂)
    ϕ ↑* []       = ϕ
    ϕ ↑* (s ∷ S)  = (ϕ ↑* S) ↑ s
      
    id : S →ₖ S
    id s x = id/` x

    ⦅_⦆ : S ∋/⊢ s → (s ∷ S) →ₖ S
    ⦅ x/t ⦆ = x/t ∷ₖ id

    weaken : ∀ s → S →ₖ (s ∷ S)
    weaken s = wkm s id

    _~_ : (ϕ₁ ϕ₂ : S₁ →ₖ S₂) → Set
    _~_ {S₁} ϕ₁ ϕ₂ = ∀ s (x : S₁ ∋ s) → ϕ₁ s x ≡ ϕ₂ s x

    -- Not necessary in the full framework.
    postulate
      ~-ext : ∀ {ϕ₁ ϕ₂ : S₁ →ₖ S₂} → ϕ₁ ~ ϕ₂ → ϕ₁ ≡ ϕ₂

    id↑~id : (id {S} ↑ s) ~ id {s ∷ S}
    id↑~id s zero    = refl
    id↑~id s (suc x) =
      (id ↑ _) s (suc x) ≡⟨⟩
      wk _ (id/` x)      ≡⟨ wk-id/` _ x ⟩
      id/` (suc x)       ≡⟨⟩
      id s (suc x)       ∎


    id↑*~id : ∀ S → (id ↑* S) ~ id {S ++ S'}
    id↑*~id []      sx x = refl
    id↑*~id (s ∷ S) sx x =
      ((id ↑* S) ↑ s) sx x ≡⟨ cong (λ ■ → (■ ↑ s) sx x) (~-ext (id↑*~id S)) ⟩
      (id ↑ s) sx x        ≡⟨ id↑~id sx x ⟩
      id sx x              ∎


  _∋/⊢[_]_ :  List (Sort Var) → Kit _∋/⊢_ → Sort Var → Set
  _∋/⊢[_]_ {_∋/⊢_} S K s = S ∋/⊢ s

  _–[_]→_ :  List (Sort Var) → Kit _∋/⊢_ →
             List (Sort Var) → Set
  S₁ –[ K ]→ S₂ = Kit._→ₖ_ K S₁ S₂

  open Kit ⦃ … ⦄ public

  record Traversal : Set₁ where
    infixl   5  _⋯_

    field
      _⋯_    :  ∀ ⦃ K : Kit _∋/⊢_ ⦄ →
                S₁ ⊢ s → S₁ –[ K ]→ S₂ → S₂ ⊢ s
      ⋯-var  :  ∀  ⦃ K : Kit _∋/⊢_ ⦄ (x : S₁ ∋ s) (ϕ : S₁ –[ K ]→ S₂) →
                (` x) ⋯ ϕ ≡ `/id (x & ϕ)
      ⋯-id   :  ∀  ⦃ K : Kit _∋/⊢_ ⦄ (t : S ⊢ s) →
                t ⋯ id ⦃ K ⦄ ≡ t

    module Example {_∋/⊢_ : Scoped} ⦃ K : Kit _∋/⊢_ ⦄ where
      ex₁ : Set
      ex₁ = ∀ {S s} →
        ∀ s' (x : S ∋ s) →
        wk s' (id/` x) ≡ id/` (suc x)

      ex₂ : Set
      ex₂ =  ∀ {S s} →
          ∀ s' (x/t : S ∋/⊢ s) →
          `/id (wk s' x/t) ≡ `/id x/t ⋯ weaken s'

    instance
      Kᵣ : Kit _∋_
      Kᵣ = record
        { id/`            = λ x → x
        ; `/id            = `_
        ; wk              = λ s' x → suc x
        ; `/`-is-`        = λ x → refl
        ; id/`-injective  = λ eq → eq
        ; `/id-injective  = `-injective
        ; wk-id/`         = λ s' x → refl }

      Kₛ : Kit _⊢_
      Kₛ = record
        { id/`            = `_
        ; `/id            = λ t → t
        ; `/`-is-`        = λ x → refl
        ; wk              = λ s' t → t ⋯ weaken ⦃ Kᵣ ⦄ s'
        ; id/`-injective  = `-injective
        ; `/id-injective  = λ eq → eq
        ; wk-id/`         = λ s' x → ⋯-var x (weaken ⦃ Kᵣ ⦄ s') }

    open Kit Kᵣ public using () renaming 
      (_→ₖ_ to _→ᵣ_; wkm to wkmᵣ; _∷ₖ_ to _∷ᵣ_; _↑_ to _↑ᵣ_;
       id to idᵣ; ⦅_⦆ to ⦅_⦆ᵣ; weaken to weakenᵣ)
    open Kit Kₛ public using () renaming 
      (_→ₖ_ to _→ₛ_; wkm to wkmₛ; _∷ₖ_ to _∷ₛ_; _↑_ to _↑ₛ_;
       id to idₛ; ⦅_⦆ to ⦅_⦆ₛ; weaken to weakenₛ)

    -- Counterpart to wk-id/`
    record WkKit (K : Kit _∋/⊢_): Set₁ where
      private instance _ = K
      field
        wk-`/id :  ∀ s {S s'} (x/t : S ∋/⊢ s') →
                   `/id x/t ⋯ weakenᵣ s ≡ `/id (wk s x/t)

    instance
      Wᵣ : WkKit Kᵣ
      Wᵣ = record { wk-`/id = λ s x → ⋯-var x (weaken s) }

      Wₛ : WkKit Kₛ
      Wₛ = record { wk-`/id = λ s t → refl }

    open WkKit ⦃ … ⦄ public

    record ComposeKit  (K₁ : Kit _∋/⊢₁_) (K₂ : Kit _∋/⊢₂_)
                       (K₁⊔K₂ : Kit _∋/⊢_) : Set where
      private instance _ = K₁; _ = K₂; _ = K₁⊔K₂
      infixl  8  _&/⋯_
      field
        _&/⋯_     :  S₁ ∋/⊢[ K₁ ] s → S₁ –[ K₂ ]→ S₂ → S₂ ∋/⊢[ K₁⊔K₂ ] s
        &/⋯-⋯     :  (x/t : S₁ ∋/⊢[ K₁ ] s) (ϕ : S₁ –[ K₂ ]→ S₂) →
                     `/id (x/t &/⋯ ϕ) ≡ `/id x/t ⋯ ϕ
        &/⋯-wk-↑  :  (x/t : S₁ ∋/⊢[ K₁ ] s) (ϕ : S₁ –[ K₂ ]→ S₂) →
                     wk s' (x/t &/⋯ ϕ) ≡ wk s' x/t &/⋯ (ϕ ↑ s')

      _·ₖ_ : S₁ –[ K₁ ]→ S₂ → S₂ –[ K₂ ]→ S₃ → S₁ –[ K₁⊔K₂ ]→ S₃
      (ϕ₁ ·ₖ ϕ₂) _ x = (x & ϕ₁) &/⋯ ϕ₂ 

      &/⋯-& :  ∀ (x : S₁ ∋ s) (ϕ : S₁ –[ K₂ ]→ S₂) →
               `/id (id/` ⦃ K₁ ⦄ x &/⋯ ϕ) ≡ `/id (x & ϕ)
      &/⋯-& x ϕ = 
          `/id (id/` x &/⋯ ϕ)       ≡⟨ &/⋯-⋯ (id/` x) ϕ ⟩
          `/id ⦃ K₁ ⦄ (id/` x) ⋯ ϕ  ≡⟨ cong (_⋯ ϕ) (`/`-is-` ⦃ K₁ ⦄ x) ⟩
          ` x ⋯ ϕ                   ≡⟨ ⋯-var ⦃ K₂ ⦄ x ϕ ⟩
          `/id ⦃ K₂ ⦄  (x & ϕ)      ∎

      dist-↑-· :  ∀ s (ϕ₁ : S₁ –[ K₁ ]→ S₂) (ϕ₂ : S₂ –[ K₂ ]→ S₃) →
                  ((ϕ₁ ·ₖ ϕ₂) ↑ s) ~ ((ϕ₁ ↑ s) ·ₖ (ϕ₂ ↑ s))
      dist-↑-· s ϕ₁ ϕ₂ s₁ x@zero = `/id-injective (
        `/id ⦃ K₁⊔K₂ ⦄ (x & ((ϕ₁ ·ₖ ϕ₂) ↑ s))        ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (id/` zero)                   ≡⟨ `/`-is-` ⦃ K₁⊔K₂ ⦄ zero ⟩
        ` zero                                       ≡⟨ sym (`/`-is-` ⦃ K₂ ⦄ zero) ⟩
        `/id ⦃ K₂ ⦄ (id/` zero)                      ≡⟨⟩
        `/id ⦃ K₂ ⦄ (zero & (ϕ₂ ↑ s))                ≡⟨ sym (&/⋯-& (id/` zero) (ϕ₂ ↑ s)) ⟩
        `/id ⦃ K₁⊔K₂ ⦄ (id/` zero &/⋯ (ϕ₂ ↑ s))      ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (x & (ϕ₁ ↑ s) &/⋯ (ϕ₂ ↑ s))   ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (x & ((ϕ₁ ↑ s) ·ₖ (ϕ₂ ↑ s)))  ∎
        )
      dist-↑-· s ϕ₁ ϕ₂ s₁ x@(suc y) = `/id-injective (
        `/id ⦃ K₁⊔K₂ ⦄ (x & ((ϕ₁ ·ₖ ϕ₂) ↑ s))        ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (wk _ (y & (ϕ₁ ·ₖ ϕ₂)))       ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (wk _ (y & ϕ₁ &/⋯ ϕ₂))        ≡⟨ cong `/id (&/⋯-wk-↑ (y & ϕ₁) ϕ₂) ⟩
        `/id ⦃ K₁⊔K₂ ⦄ (wk _ (y & ϕ₁) &/⋯ (ϕ₂ ↑ s))  ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (x & (ϕ₁ ↑ s) &/⋯ (ϕ₂ ↑ s))   ≡⟨⟩
        `/id ⦃ K₁⊔K₂ ⦄ (x & ((ϕ₁ ↑ s) ·ₖ (ϕ₂ ↑ s)))  ∎
        )

      dist-↑*-· :  ∀ S (ϕ₁ : S₁ –[ K₁ ]→ S₂) (ϕ₂ : S₂ –[ K₂ ]→ S₃) →
                   ((ϕ₁ ·ₖ ϕ₂) ↑* S) ~ ((ϕ₁ ↑* S) ·ₖ (ϕ₂ ↑* S))
      dist-↑*-· []      ϕ₁ ϕ₂ sx x = refl
      dist-↑*-· (s ∷ S) ϕ₁ ϕ₂ sx x =
        ((ϕ₁ ·ₖ ϕ₂) ↑* (s ∷ S)) sx x              ≡⟨⟩
        (((ϕ₁ ·ₖ ϕ₂) ↑* S) ↑ s) sx x              ≡⟨ cong (λ ■ → (■ ↑ s) sx x) (~-ext (dist-↑*-· S ϕ₁ ϕ₂)) ⟩
        (((ϕ₁ ↑* S) ·ₖ (ϕ₂ ↑* S)) ↑ s) sx x       ≡⟨ dist-↑-· s (ϕ₁ ↑* S) (ϕ₂ ↑* S) sx x ⟩
        (((ϕ₁ ↑* S) ↑ s) ·ₖ ((ϕ₂ ↑* S) ↑ s)) sx x ≡⟨⟩
        ((ϕ₁ ↑* (s ∷ S)) ·ₖ (ϕ₂ ↑* (s ∷ S))) sx x ∎

    _·[_]_ :  ∀ {K₁ : Kit _∋/⊢₁_} {K₂ : Kit _∋/⊢₂_} {K₁⊔K₂ : Kit _∋/⊢_} →
              S₁ –[ K₁ ]→ S₂ → ComposeKit K₁ K₂ K₁⊔K₂ →
              S₂ –[ K₂ ]→ S₃ → S₁ –[ K₁⊔K₂ ]→ S₃
    ϕ₁ ·[ C ] ϕ₂ = ϕ₁ ·ₖ ϕ₂ where open ComposeKit C

    open ComposeKit ⦃ … ⦄ public

    record ComposeTraversal : Set₁ where
      field
        ⋯-fusion :
          ∀ ⦃ K₁ : Kit _∋/⊢₁_ ⦄ ⦃ K₂ : Kit _∋/⊢₂_ ⦄ ⦃ K : Kit _∋/⊢_ ⦄
            ⦃ W₁ : WkKit K₁ ⦄ ⦃ C : ComposeKit K₁ K₂ K ⦄
            (t : S₁ ⊢ s) (ϕ₁ : S₁ –[ K₁ ]→ S₂) (ϕ₂ : S₂ –[ K₂ ]→ S₃)
          → (t ⋯ ϕ₁) ⋯ ϕ₂ ≡ t ⋯ (ϕ₁ ·ₖ ϕ₂)

      ↑-wk :  ∀  ⦃ K : Kit _∋/⊢_ ⦄ ⦃ W : WkKit K ⦄
                 ⦃ C₁ : ComposeKit K Kᵣ K ⦄ ⦃ C₂ : ComposeKit Kᵣ K K ⦄ 
                 (ϕ : S₁ –[ K ]→ S₂) s
              → (ϕ ·ₖ weaken s) ~ (weaken s ·ₖ (ϕ ↑ s))
      ↑-wk {S₁} {S₂} ϕ s sx x = `/id-injective (
          `/id ((ϕ ·ₖ weakenᵣ s) sx x)        ≡⟨⟩
          `/id (x & ϕ &/⋯ weakenᵣ s)          ≡⟨ &/⋯-⋯ (x & ϕ) (weakenᵣ s) ⟩
          `/id (`/id (x & ϕ) ⋯ weakenᵣ s)     ≡⟨ wk-`/id s (x & ϕ) ⟩
          `/id (suc x & (ϕ ↑ s))              ≡⟨ sym (&/⋯-& (suc x) (ϕ ↑ s)) ⟩
          `/id (suc x &/⋯ (ϕ ↑ s))            ≡⟨⟩
          `/id (x & weakenᵣ s &/⋯ (ϕ ↑ s))    ≡⟨⟩
          `/id ((weakenᵣ s ·ₖ (ϕ ↑ s)) sx x)  ∎)

      ⋯-↑-wk : ∀  ⦃ K : Kit _∋/⊢_ ⦄ ⦃ W : WkKit K ⦄
                  ⦃ C₁ : ComposeKit K Kᵣ K ⦄ ⦃ C₂ : ComposeKit Kᵣ K K ⦄ 
                  (t : S₁ ⊢ s) (ϕ : S₁ –[ K ]→ S₂) s
               → t ⋯ ϕ ⋯ weakenᵣ s ≡ t ⋯ weakenᵣ s ⋯ (ϕ ↑ s)
      ⋯-↑-wk t ϕ s =
        t ⋯ ϕ ⋯ weakenᵣ s           ≡⟨ ⋯-fusion t ϕ (weakenᵣ s) ⟩
        t ⋯ (ϕ ·ₖ weakenᵣ s)        ≡⟨ cong (t ⋯_) (~-ext (↑-wk ϕ s)) ⟩
        t ⋯ (weakenᵣ s ·ₖ (ϕ ↑ s))  ≡⟨ sym (⋯-fusion t (weakenᵣ s) (ϕ ↑ s)) ⟩
        t ⋯ weakenᵣ s ⋯ (ϕ ↑ s)     ∎

      instance
        Cᵣ : ⦃ K₂ : Kit _∋/⊢_ ⦄ → ComposeKit Kᵣ K₂ K₂
        Cᵣ = record
          { _&/⋯_     = _&_
          ; &/⋯-⋯     = λ x ϕ → sym (⋯-var x ϕ)
          ; &/⋯-wk-↑  = λ x ϕ → refl }

        Cₛ :  ⦃ K₂ : Kit _∋/⊢_ ⦄ ⦃ W₂ : WkKit K₂ ⦄
              ⦃ C : ComposeKit K₂ Kᵣ K₂ ⦄ → ComposeKit Kₛ K₂ Kₛ
        Cₛ ⦃ C = C ⦄ = record
          { _&/⋯_     = _⋯_
          ; &/⋯-⋯     = λ t ϕ → refl
          ; &/⋯-wk-↑  = λ t ϕ → ⋯-↑-wk t ϕ _ }

      -- Only for demonstration:
      Cᵣᵣ : ComposeKit Kᵣ Kᵣ Kᵣ;  Cᵣᵣ = Cᵣ
      Cᵣₛ : ComposeKit Kᵣ Kₛ Kₛ;  Cᵣₛ = Cᵣ
      Cₛᵣ : ComposeKit Kₛ Kᵣ Kₛ;  Cₛᵣ = Cₛ
      Cₛₛ : ComposeKit Kₛ Kᵣ Kₛ;  Cₛₛ = Cₛ

      wk-cancels-⦅⦆ :
        ∀ ⦃ K : Kit _∋/⊢_ ⦄ (x/t : S ∋/⊢[ K ] s) →
        (weakenᵣ s ·[ Cᵣ ] ⦅ x/t ⦆) ~ id
      wk-cancels-⦅⦆ ⦃ K ⦄ x/t sx x = `/id-injective (
          `/id ⦃ K ⦄ (x & (weakenᵣ _ ·[ Cᵣ ] ⦅ x/t ⦆))  ≡⟨⟩
          `/id ⦃ K ⦄ (id/` (suc x) &/⋯ ⦅ x/t ⦆)         ≡⟨ &/⋯-& ⦃ Cᵣ ⦃ K ⦄ ⦄ (suc x) ⦅ x/t ⦆ ⟩
          `/id ⦃ K ⦄ (id/` x)                           ≡⟨⟩
          `/id ⦃ K ⦄ (x & id)                           ∎)

      wk-cancels-⦅⦆-⋯ :
        ∀ ⦃ K : Kit _∋/⊢_ ⦄ (t : S ⊢ s') (x/t : S ∋/⊢[ K ] s) →
        t ⋯ weakenᵣ s ⋯ ⦅ x/t ⦆ ≡ t
      wk-cancels-⦅⦆-⋯ t x/t =
        t ⋯ weakenᵣ _ ⋯ ⦅ x/t ⦆     ≡⟨ ⋯-fusion t (weakenᵣ _) ⦅ x/t ⦆ ⟩
        t ⋯ (weakenᵣ _ ·ₖ ⦅ x/t ⦆)  ≡⟨ cong (t ⋯_) (~-ext (wk-cancels-⦅⦆ x/t)) ⟩
        t ⋯ id                      ≡⟨ ⋯-id t ⟩
        t                           ∎

      dist-↑-⦅⦆ :
        ∀  ⦃ K₁ : Kit _∋/⊢₁_ ⦄ ⦃ K₂ : Kit _∋/⊢₂_ ⦄ ⦃ K : Kit _∋/⊢_ ⦄
           ⦃ W₂ : WkKit K₂ ⦄
           ⦃ C₁ : ComposeKit K₁ K₂ K ⦄ ⦃ C₂ : ComposeKit K₂ K K ⦄
           (x/t : S₁ ∋/⊢[ K₁ ] s) (ϕ : S₁ –[ K₂ ]→ S₂) →
        (⦅ x/t ⦆ ·[ C₁ ] ϕ) ~ ((ϕ ↑ s) ·[ C₂ ] ⦅ (x/t &/⋯ ϕ) ⦆)
      dist-↑-⦅⦆ {s = s} ⦃ K₁ ⦄ ⦃ K₂ ⦄ ⦃ K ⦄ ⦃ W₂ ⦄ ⦃ C₁ ⦄ ⦃ C₂ ⦄ x/t ϕ sx x@zero = `/id-injective (
          `/id ⦃ K ⦄ (x & (⦅ x/t ⦆ ·[ C₁ ] ϕ))                ≡⟨⟩
          `/id ⦃ K ⦄ (x/t &/⋯ ϕ)                              ≡⟨⟩
          `/id ⦃ K ⦄ (zero & ⦅ (x/t &/⋯ ϕ) ⦆)                 ≡⟨ sym (&/⋯-& ⦃ C₂ ⦄ zero ⦅ (x/t &/⋯ ϕ) ⦆) ⟩
          `/id ⦃ K ⦄ (id/` ⦃ K₂ ⦄ zero &/⋯ ⦅ (x/t &/⋯ ϕ) ⦆)   ≡⟨⟩
          `/id ⦃ K ⦄ (x & ((ϕ ↑ s) ·[ C₂ ] ⦅ (x/t &/⋯ ϕ) ⦆))  ∎)
      dist-↑-⦅⦆ {s = s} ⦃ K₁ ⦄ ⦃ K₂ ⦄ ⦃ K ⦄ ⦃ W₂ ⦄ ⦃ C₁ ⦄ ⦃ C₂ ⦄ x/t ϕ sx x@(suc y) = `/id-injective (
          `/id (x & (⦅ x/t ⦆ ·[ C₁ ] ϕ))                ≡⟨⟩
          `/id (id/` ⦃ K₁ ⦄ y &/⋯ ϕ)                    ≡⟨ &/⋯-& ⦃ C₁ ⦄ y ϕ ⟩
          `/id (y & ϕ)                                  ≡⟨ sym (wk-cancels-⦅⦆-⋯ (`/id (y & ϕ)) (x/t &/⋯ ϕ)) ⟩
          `/id (y & ϕ) ⋯ weakenᵣ s ⋯ ⦅ (x/t &/⋯ ϕ) ⦆    ≡⟨ cong (_⋯ ⦅ x/t &/⋯ ϕ ⦆) (wk-`/id s (y & ϕ)) ⟩
          `/id (wk s (y & ϕ)) ⋯ ⦅ (x/t &/⋯ ϕ) ⦆         ≡⟨ sym (&/⋯-⋯ (wk s (y & ϕ)) ⦅ (x/t &/⋯ ϕ) ⦆) ⟩
          `/id (wk s (y & ϕ) &/⋯ ⦅ (x/t &/⋯ ϕ) ⦆)       ≡⟨⟩
          `/id (x & ((ϕ ↑ s) ·[ C₂ ] ⦅ (x/t &/⋯ ϕ) ⦆))  ∎)

      dist-↑-⦅⦆-⋯ :
        ∀  ⦃ K₁ : Kit _∋/⊢₁_ ⦄ ⦃ K₂ : Kit _∋/⊢₂_ ⦄ ⦃ K : Kit _∋/⊢_ ⦄
           ⦃ W₁ : WkKit K₁ ⦄ ⦃ W₂ : WkKit K₂ ⦄
           ⦃ C₁ : ComposeKit K₁ K₂ K ⦄ ⦃ C₂ : ComposeKit K₂ K K ⦄
           (t : (s ∷ S₁) ⊢ s') (x/t : S₁ ∋/⊢[ K₁ ] s) (ϕ : S₁ –[ K₂ ]→ S₂) →
        t ⋯ ⦅ x/t ⦆ ⋯ ϕ ≡ t ⋯ (ϕ ↑ s) ⋯ ⦅ (x/t &/⋯ ϕ) ⦆
      dist-↑-⦅⦆-⋯ t x/t ϕ =
        t ⋯ ⦅ x/t ⦆ ⋯ ϕ                   ≡⟨ ⋯-fusion t ⦅ x/t ⦆ ϕ ⟩
        t ⋯ (⦅ x/t ⦆ ·ₖ ϕ)                ≡⟨ cong (t ⋯_) (~-ext (dist-↑-⦅⦆ x/t ϕ)) ⟩
        t ⋯ ((ϕ ↑ _) ·ₖ ⦅ (x/t &/⋯ ϕ) ⦆)  ≡⟨ sym (⋯-fusion t (ϕ ↑ _) ⦅ x/t &/⋯ ϕ ⦆ ) ⟩
        t ⋯ (ϕ ↑ _) ⋯ ⦅ (x/t &/⋯ ϕ) ⦆     ∎

      record Types : Set₁ where
        field
          ↑ᵗ : ∀ {st} → Sort st → ∃[ st' ] Sort st'

        _∶⊢_ : ∀ {t} → List (Sort Var) → Sort t → Set
        S ∶⊢ s = S ⊢ proj₂ (↑ᵗ s)

        depth : ∀ {ℓ} {A : Set ℓ} {x : A} {xs : List A} → xs ∋ x → ℕ
        depth zero     = zero
        depth (suc x)  = suc (depth x)

        -- We need to drop one extra using `suc`, because otherwise the types in a
        -- context are allowed to use themselves.
        drop-∈ :  ∀ {ℓ} {A : Set ℓ} {x : A} {xs : List A} →
                  xs ∋ x → List A → List A
        drop-∈ e xs = drop (suc (depth e)) xs

        Ctx : List (Sort Var) → Set
        Ctx S = ∀ s → (x : S ∋ s) → drop-∈ x S ∶⊢ s

        []ₜ : Ctx []
        []ₜ _ ()

        _∷ₜ_ : S ∶⊢ s → Ctx S → Ctx (s ∷ S)
        (t ∷ₜ Γ) _ zero     = t
        (t ∷ₜ Γ) _ (suc x)  = Γ _ x

        wk-drop-∈ : (x : S ∋ s) → drop-∈ x S ⊢ s' → S ⊢ s'
        wk-drop-∈ zero     t = t ⋯ weakenᵣ _
        wk-drop-∈ (suc x)  t = wk-drop-∈ x t ⋯ weakenᵣ _

        wk-telescope : Ctx S → S ∋ s → S ∶⊢ s
        wk-telescope Γ x = wk-drop-∈ x (Γ _ x)

        infix   4  _∋_∶_
        _∋_∶_ : Ctx S → S ∋ s → S ∶⊢ s → Set
        Γ ∋ x ∶ t = wk-telescope Γ x ≡ t

        record Typing : Set₁ where
          infix   4  _⊢_∶_
          field
            _⊢_∶_ : ∀ {s : Sort st} → Ctx S → S ⊢ s → S ∶⊢ s → Set

            ⊢` : ∀ {Γ : Ctx S} {x : S ∋ s} {t} →
                Γ ∋ x ∶ t → Γ ⊢ ` x ∶ t

          record TypingKit (K : Kit _∋/⊢_) : Set₁ where
            private instance _ = K
            infix   4  _∋/⊢_∶_  _∋*/⊢*_∶_
            infixl  6  _∋↑/⊢↑_
            field
              _∋/⊢_∶_      : Ctx S → S ∋/⊢ s → S ∶⊢ s → Set
              id/⊢`        : ∀ {t : S ∶⊢ s} {Γ : Ctx S} →
                             Γ ∋ x ∶ t → Γ ∋/⊢ id/` x ∶ t
              ⊢`/id        : ∀ {e : S ∋/⊢ s} {t : S ∶⊢ s} {Γ : Ctx S} →
                             Γ ∋/⊢ e ∶ t → Γ ⊢ `/id e ∶ t
              ∋wk/⊢wk      : ∀ (Γ : Ctx S) (t' : S ∶⊢ s) (e : S ∋/⊢ s')
                               (t : S ∶⊢ s') →
                             Γ ∋/⊢ e ∶ t →
                             (t' ∷ₜ Γ) ∋/⊢ wk _ e ∶ (t ⋯ weakenᵣ _)

            _∋*/⊢*_∶_ : Ctx S₂ → S₁ –[ K ]→ S₂ → Ctx S₁ → Set
            _∋*/⊢*_∶_ {S₂} {S₁} Γ₂ ϕ Γ₁ =
              ∀ {s₁} (x : S₁ ∋ s₁) (t : S₁ ∶⊢ s₁) →
              Γ₁ ∋ x ∶ t →
              Γ₂ ∋/⊢ (x & ϕ) ∶ (t ⋯ ϕ)

            _∋↑/⊢↑_ :
              ⦃ W : WkKit K ⦄ ⦃ C₁ : ComposeKit K Kᵣ K ⦄
              {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {ϕ : S₁ –[ K ]→ S₂} →
              Γ₂             ∋*/⊢* ϕ       ∶ Γ₁ →
              (t : S₁ ∶⊢ s) →
              ((t ⋯ ϕ) ∷ₜ Γ₂) ∋*/⊢* (ϕ ↑ s) ∶ (t ∷ₜ Γ₁)
            _∋↑/⊢↑_ {S₁} {S₂} {s} {Γ₁} {Γ₂} {ϕ} ⊢ϕ t {sx} x@zero _ refl =
              subst (  ((t ⋯ ϕ) ∷ₜ Γ₂) ∋/⊢ (zero & (ϕ ↑ s)) ∶_ )
                    (  t ⋯ ϕ ⋯ weakenᵣ s                      ≡⟨ ⋯-↑-wk t ϕ s ⟩
                       t ⋯ weakenᵣ s ⋯ (ϕ ↑ s)                ≡⟨⟩
                       wk-telescope (t ∷ₜ Γ₁) zero ⋯ (ϕ ↑ s)  ∎ )
                    (  id/⊢` {x = zero} {Γ = (t ⋯ ϕ) ∷ₜ Γ₂} refl )
            _∋↑/⊢↑_ {S₁} {S₂} {s} {Γ₁} {Γ₂} {ϕ} ⊢ϕ t {sx} x@(suc y) _ refl =
              subst (((t ⋯ ϕ) ∷ₜ Γ₂) ∋/⊢ (suc y & (ϕ ↑ s)) ∶_)
                    (wk-telescope Γ₁ y ⋯ ϕ ⋯ weakenᵣ s         ≡⟨ ⋯-↑-wk _ ϕ s ⟩
                     wk-telescope Γ₁ y ⋯ weakenᵣ s ⋯ (ϕ ↑ s)   ≡⟨⟩
                     wk-telescope (t ∷ₜ Γ₁) (suc y) ⋯ (ϕ ↑ s)  ∎)
                    (∋wk/⊢wk _ _ _ _ (⊢ϕ y _ refl))

            ⊢⦅_⦆ : ∀ {s S} {Γ : Ctx S} {t : S ∋/⊢ s} {T : S ∶⊢ s}
              → Γ ∋/⊢ t ∶ T 
              → Γ ∋*/⊢* ⦅ t ⦆ ∶ (T ∷ₜ Γ)
            ⊢⦅_⦆ {s} {S} {Γ} {t} {T} ⊢x/t x@zero _ refl =
              subst (Γ ∋/⊢ t ∶_)
                    (T                                   ≡⟨ sym (wk-cancels-⦅⦆-⋯ T t) ⟩
                     T ⋯ weakenᵣ _ ⋯ ⦅ t ⦆               ≡⟨⟩
                     wk-telescope (T ∷ₜ Γ) zero ⋯ ⦅ t ⦆  ∎)
                    ⊢x/t
            ⊢⦅_⦆ {s} {S} {Γ} {t} {T} ⊢x/t x@(suc y) _ refl =
              subst (Γ ∋/⊢ id/` y ∶_)
                    (wk-telescope Γ y                       ≡⟨ sym (wk-cancels-⦅⦆-⋯ _ t) ⟩
                     wk-telescope Γ y ⋯ weakenᵣ _ ⋯ ⦅ t ⦆   ≡⟨⟩
                     wk-telescope (T ∷ₜ Γ) (suc y) ⋯ ⦅ t ⦆  ∎)
                    (id/⊢` refl)

          open TypingKit ⦃ … ⦄ public

          infixl  5  _∋*/⊢*[_]_∶_
          _∋*/⊢*[_]_∶_ :
            ∀ {K : Kit _∋/⊢_} {S₁ S₂}
            → Ctx S₂ → TypingKit K → S₁ –[ K ]→ S₂ → Ctx S₁ → Set
          Γ₂ ∋*/⊢*[ TK ] ϕ ∶ Γ₁ = Γ₂ ∋*/⊢* ϕ ∶ Γ₁ where instance _ = TK

          record TypingTraversal : Set₁ where
            field
              _⊢⋯_ :
                ∀  ⦃ K : Kit _∋/⊢_ ⦄ ⦃ W : WkKit K ⦄ ⦃ TK : TypingKit K ⦄
                   ⦃ C₁ : ComposeKit K Kᵣ K ⦄
                   ⦃ C₂ : ComposeKit K K K ⦄
                   ⦃ C₃ : ComposeKit K Kₛ Kₛ ⦄
                   {S₁ S₂ st} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {s : Sort st}
                   {e : S₁ ⊢ s} {t : S₁ ∶⊢ s} {ϕ : S₁ –[ K ]→ S₂} →
                Γ₁ ⊢ e ∶ t →
                Γ₂ ∋*/⊢*[ TK ] ϕ ∶ Γ₁ →
                Γ₂ ⊢ e ⋯ ϕ ∶ t ⋯ ϕ

            infixl  5  _⊢⋯_  _⊢⋯ᵣ_  _⊢⋯ₛ_

            instance
              TKᵣ : TypingKit Kᵣ
              TKᵣ = record
                { _∋/⊢_∶_     = _∋_∶_
                ; id/⊢`       = λ ⊢x → ⊢x
                ; ⊢`/id       = ⊢`
                ; ∋wk/⊢wk     = λ { Γ t' x t refl → refl } }

              TKₛ : TypingKit Kₛ
              TKₛ = record
                { _∋/⊢_∶_     = _⊢_∶_
                ; id/⊢`       = ⊢`
                ; ⊢`/id       = λ ⊢x → ⊢x
                ; ∋wk/⊢wk     = λ Γ t' e t ⊢e → ⊢e ⊢⋯ ∋wk/⊢wk Γ t' }

            open TypingKit TKᵣ public using () renaming
              (∋wk/⊢wk to ⊢wk; _∋*/⊢*_∶_ to _∋*_∶_; ⊢⦅_⦆ to ⊢⦅_⦆ᵣ)
            open TypingKit TKₛ public using () renaming
              (∋wk/⊢wk to ∋wk; _∋*/⊢*_∶_ to _⊢*_∶_; ⊢⦅_⦆ to ⊢⦅_⦆ₛ)

            -- Renaming preserves typing

            _⊢⋯ᵣ_ : ∀ {S₁ S₂ st} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {s : Sort st}
                      {e : S₁ ⊢ s} {t : S₁ ∶⊢ s} {ρ : S₁ →ᵣ S₂} →
                    Γ₁ ⊢ e ∶ t →
                    Γ₂ ∋* ρ ∶ Γ₁ →
                    Γ₂ ⊢ e ⋯ ρ ∶ t ⋯ ρ
            _⊢⋯ᵣ_ = _⊢⋯_

            -- Substitution preserves typing

            _⊢⋯ₛ_ : ∀ {S₁ S₂ st} {Γ₁ : Ctx S₁} {Γ₂ : Ctx S₂} {s : Sort st}
                      {e : S₁ ⊢ s} {t : S₁ ∶⊢ s} {σ : S₁ →ₛ S₂} →
                    Γ₁ ⊢ e ∶ t →
                    Γ₂ ⊢* σ ∶ Γ₁ →
                    Γ₂ ⊢ e ⋯ σ ∶ t ⋯ σ
            _⊢⋯ₛ_ = _⊢⋯_
