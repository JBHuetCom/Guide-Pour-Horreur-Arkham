unit AH.Core.EvaluateurCondition;

  interface

  uses

    AH.Core.Noeud, AH.Core.Contexte;

  type
    /// <summary>
    /// Résout la branche applicable d'un nœud ntCondition en comparant la valeur du champ
    /// désigné dans TContextePartie à la ValeurDeclenchante de chaque branche déclarée.
    /// </summary>
    TEvaluateurCondition = class
      public
        /// <param name="ANoeud">Nœud de type ntCondition à résoudre.</param>
        /// <param name="AContexte">Contexte de partie utilisé pour l'évaluation.</param>
        /// <returns>Le sous-nœud de la première branche dont ValeurDeclenchante correspond à la valeur courante du champ.</returns>
        /// <exception cref="EArgumentException">
        /// Levée si aucune branche ne correspond à la valeur courante du champ (contenu mal formé).
        /// </exception>
        class function ResoudreBranche(ANoeud : TNoeudEtape; AContexte : TContextePartie) : TNoeudEtape;
    end;

  implementation

    uses

      System.SysUtils, System.Variants;

    { TEvaluateurCondition }

    class function TEvaluateurCondition.ResoudreBranche(ANoeud : TNoeudEtape; AContexte : TContextePartie) : TNoeudEtape;
      var
        ValeurCourante: Variant;
        BrancheIndex: Integer;
      begin
        ValeurCourante := AContexte.LireChamp(ANoeud.ChampContexte);
        for BrancheIndex := 0 to ANoeud.Branches.Count - 1 do
          if ANoeud.Branches[BrancheIndex].ValeurDeclenchante = ValeurCourante then
            Exit(ANoeud.Branches[BrancheIndex].Noeud);

        Result := nil;
      end;

end.
