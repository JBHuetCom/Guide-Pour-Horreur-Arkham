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
        Branche: TBrancheEtape;
      begin
        ValeurCourante := AContexte.LireChamp(ANoeud.ChampContexte);
        for Branche in ANoeud.Branches do
          if Branche.ValeurDeclenchante = ValeurCourante then
            Exit(Branche.Noeud);

        raise EArgumentException.CreateFmt(
          'Aucune branche du nœud "%s" ne correspond à la valeur courante (%s) du champ "%s".',
          [ANoeud.Id, VarToStr(ValeurCourante), ANoeud.ChampContexte]);
      end;

end.
