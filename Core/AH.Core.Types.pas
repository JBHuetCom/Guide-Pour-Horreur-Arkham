unit AH.Core.Types;

  interface

    type
      /// <summary>Nature d'un nœud dans l'arbre de contenu d'une partie.</summary>
      TTypeNoeud = (
        ntSequence,               // Regroupe des enfants exécutés dans l'ordre
        ntBouclePorInvestigateur, // Répète ses enfants pour chaque investigateur, dans l'ordre de jeu
        ntInstruction,            // Feuille : texte informatif validé par le joueur
        ntChoix,                  // Feuille : plusieurs branches choisies manuellement par les joueurs
        ntCondition,              // Branchement automatique évalué sur TContextePartie
        ntSaisie                  // Demande une valeur au joueur, alimentant TContextePartie
      );

    /// <summary>Convertit le nom textuel d'un nœud (tel qu'écrit dans le JSON de contenu) en TTypeNoeud.</summary>
    /// <param name="ATypeNoeudTexte">Chaîne à convertir, insensible à la casse (ex. "ntCondition").</param>
    /// <param name="ATypeNoeud">(OUT) Valeur convertie si la fonction retourne True.</param>
    /// <returns>True si AText correspond à une valeur connue de TTypeNoeud, False sinon.</returns>
    function TryStrToTypeNoeud(const ATypeNoeudTexte : string; out ATypeNoeud : TTypeNoeud) : Boolean;

  implementation

    uses
      System.SysUtils;

    function TryStrToTypeNoeud(const ATypeNoeudTexte : string; out ATypeNoeud : TTypeNoeud) : Boolean;
      begin
        Result := True;
        if SameText(ATypeNoeudTexte, 'ntSequence') then
          ATypeNoeud := ntSequence
        else
          if SameText(ATypeNoeudTexte, 'ntBouclePorInvestigateur') then
            ATypeNoeud := ntBouclePorInvestigateur
          else
            if SameText(ATypeNoeudTexte, 'ntInstruction') then
              ATypeNoeud := ntInstruction
            else
              if SameText(ATypeNoeudTexte, 'ntChoix') then
                ATypeNoeud := ntChoix
              else
                if SameText(ATypeNoeudTexte, 'ntCondition') then
                  ATypeNoeud := ntCondition
                else
                  if SameText(ATypeNoeudTexte, 'ntSaisie') then
                    ATypeNoeud := ntSaisie
                  else Result := False;
      end;

end.
