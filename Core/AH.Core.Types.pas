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
    /// <param name="AText">Chaîne à convertir, insensible à la casse (ex. "ntCondition").</param>
    /// <param name="AType">(OUT) Valeur convertie si la fonction retourne True.</param>
    /// <returns>True si AText correspond à une valeur connue de TTypeNoeud, False sinon.</returns>
    function TryStrToTypeNoeud(const AText : string; out AType : TTypeNoeud) : Boolean;

  implementation

    uses
      System.SysUtils;

    function TryStrToTypeNoeud(const AText : string; out AType : TTypeNoeud) : Boolean;
      begin
        Result := True;
        if SameText(AText, 'ntSequence') then
          AType := ntSequence
        else
          if SameText(AText, 'ntBouclePorInvestigateur') then
            AType := ntBouclePorInvestigateur
          else
            if SameText(AText, 'ntInstruction') then
              AType := ntInstruction
            else
              if SameText(AText, 'ntChoix') then
                AType := ntChoix
              else
                if SameText(AText, 'ntCondition') then
                  AType := ntCondition
                else
                  if SameText(AText, 'ntSaisie') then
                    AType := ntSaisie
                  else Result := False;
      end;

end.
