unit AH.Core.ChargeurContenu;

  interface

    uses

      System.SysUtils,
      SuperObject,
      AH.Core.Noeud;

    type

      /// <summary>Erreur de contenu : JSON malformé ou incohérent avec le schéma attendu.</summary>
      EChargeurContenuException = class(Exception);

      /// <summary>
      /// Construit un arbre TNoeudEtape à partir d'un contenu JSON conforme au schéma décrit
      /// dans la documentation de conception : nœuds ntSequence/ntBouclePorJoueur portant un
      /// tableau "Enfants", nœuds ntCondition/ntChoix portant un tableau "Branches"
      /// ({"Valeur":..., "Libelle":"...", "Noeud":{...}}), nœuds ntInstruction/ntSaisie portant
      /// "Texte" et éventuellement "Illustration".
      /// </summary>
      TChargeurContenu = class
        public
          /// <param name="ACheminFichier">Chemin d'un fichier .json conforme au schéma de contenu.</param>
          /// <returns>La racine de l'arbre construit. L'appelant en devient propriétaire.</returns>
          /// <exception cref="EFileNotFoundException">Levée si ACheminFichier n'existe pas.</exception>
          /// <exception cref="EChargeurContenuException">
          /// Levée si le JSON est malformé ou si un champ obligatoire est manquant.
          /// </exception>
          class function ChargerDepuisFichier(const ACheminFichier : string) : TNoeudEtape;

          /// <param name="AJSON">Contenu JSON déjà parsé, racine d'un nœud unique.</param>
          /// <returns>Le nœud TNoeudEtape (et son sous-arbre complet) correspondant à AJSON.</returns>
          /// <exception cref="EChargeurContenuException">
          /// Levée si un champ obligatoire est manquant ou si "Type" ne correspond à aucun TTypeNoeud connu.
          /// </exception>
          class function ChargerNoeud(const AJSON : ISuperObject) : TNoeudEtape;
      end;

  implementation

    uses
      System.Variants,
      AH.Core.Types;

    /// <summary>Convertit une valeur scalaire SuperObject ("Valeur" d'une branche) en Variant comparable.</summary>
    function ValeurVariantDepuisJSON(const AJSON : ISuperObject) : Variant;
      begin
        if AJSON = nil then
          Exit(Null);

        case AJSON.DataType of
          stBoolean: Result := AJSON.AsBoolean;
          stInt:     Result := AJSON.AsInteger;
          stDouble:  Result := AJSON.AsDouble;
          stString:  Result := AJSON.AsString;
        else
          Result := Null;
        end;
      end;

    { TChargeurContenu }

    class function TChargeurContenu.ChargerDepuisFichier(const ACheminFichier : string) : TNoeudEtape;
      var
        Contenu : ISuperObject;
      begin
        if not FileExists(ACheminFichier) then
          raise EFileNotFoundException.CreateFmt(
            'Fichier de contenu introuvable : "%s".',
            [ACheminFichier]);

        Contenu := TSuperObject.ParseFile(ACheminFichier, False);
        if not Assigned(Contenu) then
          raise EChargeurContenuException.CreateFmt(
            'JSON invalide dans le fichier "%s".',
            [ACheminFichier]);

        Result := ChargerNoeud(Contenu);
      end;

    class function TChargeurContenu.ChargerNoeud(const AJSON : ISuperObject) : TNoeudEtape;
      var
        i, j : Integer;
        Id, TypeTexte : string;
        ListeTemp : TArray<string>;
        Enfants, Branches, TableauTexteListe : ISuperArray;
        BrancheJSON : ISuperObject;
        TypeNoeud : TTypeNoeud;
        ValeurBranche : Variant;
        LibelleBranche : string;
        NoeudBranche : TNoeudEtape;
      begin
        Id := AJSON.S['Id'];
        if Id = EmptyStr then
          raise EChargeurContenuException.Create('Un nœud de contenu sans "Id" a été rencontré.');

        TypeTexte := AJSON.S['Type'];
        if not TryStrToTypeNoeud(TypeTexte, TypeNoeud) then
          raise EChargeurContenuException.CreateFmt(
            'Nœud "%s" : type inconnu "%s".',
            [Id, TypeTexte]);

        Result := TNoeudEtape.Create(Id, TypeNoeud);
        try
          with Result do
            begin
              Titre := AJSON.S['Titre'];
              Texte := AJSON.S['Texte'];
              TableauTexteListe := AJSON.A['TexteListe'];
              if Assigned(TableauTexteListe) then
                begin
                  SetLength(ListeTemp, TableauTexteListe.Length);
                  for j := 0 to TableauTexteListe.Length - 1 do
                    ListeTemp[j] := TableauTexteListe.S[j];
                  Result.TexteListe := ListeTemp;
                end;
              Illustration := AJSON.S['Illustration'];
              ChampContexte := AJSON.S['Champ'];
            end;

          case TypeNoeud of
            ntSequence, ntBouclePorInvestigateur:
              begin
                Enfants := AJSON.A['Enfants'];
                if Assigned(Enfants) then
                  for i := 0 to Enfants.Length - 1 do
                    Result.AjouterEnfant(ChargerNoeud(Enfants.O[i]));
              end;
            ntCondition, ntChoix:
              begin
                Branches := AJSON.A['Branches'];
                if not Assigned(Branches)
                   or (Branches.Length = 0)
                then
                  raise EChargeurContenuException.CreateFmt(
                    'Nœud "%s" (%s) : au moins une branche est requise.',
                    [Id, TypeTexte]);

                for i := 0 to Branches.Length - 1 do
                  begin
                    BrancheJSON := Branches.O[i];

                    // Ordre d'évaluation explicite et garanti : Delphi ne garantit pas l'ordre
                    // d'évaluation des arguments d'un appel de fonction (empiriquement droite-à-gauche),
                    // ce qui est fragile ici puisque NoeudBranche est construit par un appel récursif
                    // potentiellement profond (tout un sous-arbre). On force l'ordre via des variables
                    // locales plutôt que de le laisser à la discrétion du compilateur.
                    ValeurBranche := ValeurVariantDepuisJSON(BrancheJSON['Valeur']);
                    LibelleBranche := BrancheJSON.S['Libelle'];
                    NoeudBranche := ChargerNoeud(BrancheJSON.O['Noeud']);

                    Result.AjouterBranche(ValeurBranche, LibelleBranche, NoeudBranche);
                  end;
              end;
              ntSaisie:
              if AJSON.O['ValeurForcee'] <> nil then
                begin
                  Result.ValeurForcee := ValeurVariantDepuisJSON(AJSON.O['ValeurForcee']);
                  Result.PossedeValeurForcee := True;
                end;
          end;
        except
          Result.Free;
          raise;
        end;
      end;

end.
