unit AH.Core.GrandsAnciens;

  interface

    uses

      System.SysUtils, System.Generics.Collections;

    type

      EGrandsAnciensInvalidesException = class(Exception);

      /// <summary>Règles de bataille contre un Grand Ancien.</summary>
      TReglesBataille = record
        /// <summary>Modificateur des attaques des investigateurs (ex. -3 pour Yig). 0 si non précisé.</summary>
        Combat : Integer;
        /// <summary>Capacité spéciale de défense du Grand Ancien (ex. "Immunité physique"). Vide si aucune.</summary>
        Defense : string;
      end;

      /// <summary>
      /// Représente un Grand Ancien et ses règles générales. Ne contient PAS les règles propres à
      /// une étape précise du guide (voir TGestionnaireGrandsAnciens.TryObtenirRegleEtape) : ce
      /// record reste volontairement scalaire, sans champ de type classe, pour rester librement
      /// copiable sans risque de possession ambiguë (voir la discussion sur TBrancheEtape).
      /// </summary>
      TGrandAncien = record
        /// <summary>Nom du Grand Ancien (ex. "Cthulhu").</summary>
        Nom : string;
        /// <summary>Nom du fichier image. Vide si non précisé.</summary>
        Image : string;
        /// <summary>Taille de l'échelle du destin propre à ce Grand Ancien.</summary>
        TailleEchelleDestin : Integer;
        /// <summary>Règle affichée tant que le Grand Ancien est endormi. Vide si aucune.</summary>
        EnSommeil : string;
        /// <summary>Règle affichée en permanence. Vide si aucune.</summary>
        Special : string;
        /// <summary>Règle décrivant ses adorateurs, affichée tant que la bataille finale n'a pas commencé. Vide si aucune.</summary>
        Adorateurs : string;
        /// <summary>Règles spécifiques à la bataille finale.</summary>
        Bataille : TReglesBataille;
      end;

      /// <summary>
      /// Charge et expose les Grands Anciens et leurs règles spéciales, définis dans un fichier de
      /// configuration JSON. Les règles rattachées à une étape précise du guide (IdEtape) sont
      /// consultées comme les conseils (TGestionnaireConseils) : par un couple (Grand Ancien,
      /// IdEtape), sans jamais exposer de structure interne mutable à l'appelant.
      /// </summary>
      TGestionnaireGrandsAnciens = class
        private
          FGrandsAnciensParNom : TDictionary<string, TGrandAncien>;
          /// <summary>Clé externe : nom du Grand Ancien (en minuscules). Valeur : dictionnaire IdEtape → texte de règle.</summary>
          FReglesEtapesParGrandAncien: TObjectDictionary<string, TDictionary<string, string>>;
        public
          constructor Create;
          destructor Destroy; override;

          /// <param name="ACheminFichier">Chemin du fichier grands_anciens.json.</param>
          /// <exception cref="EFileNotFoundException">Levée si le fichier est introuvable.</exception>
          /// <exception cref="EGrandsAnciensInvalidesException">
          /// Levée si le JSON est malformé, ou si une entrée n'a pas de "Nom".
          /// </exception>
          procedure ChargerDepuisFichier(const ACheminFichier : string);

          /// <summary>Noms de tous les Grands Anciens chargés, dans leur casse d'origine.</summary>
          function Noms : TArray<string>;

          /// <param name="ANomGrandAncien">Nom du Grand Ancien recherché, insensible à la casse.</param>
          /// <param name="AGrandAncien">Grand Ancien trouvé si la fonction retourne True.</param>
          /// <returns>True si ce Grand Ancien est connu, False sinon.</returns>
          function TryObtenirGrandAncien(const ANomGrandAncien : string; out AGrandAncien : TGrandAncien) : Boolean;

          /// <param name="ANomGrandAncien">Nom du Grand Ancien en jeu, insensible à la casse.</param>
          /// <param name="AIdEtape">Identifiant du nœud d'étape (TNoeudEtape.Id) pour lequel chercher une règle spéciale.</param>
          /// <param name="ATexte">Texte de la règle trouvée si la fonction retourne True.</param>
          /// <returns>True si ce Grand Ancien a une règle spéciale déclarée pour cette étape, False sinon.</returns>
          function TryObtenirRegleEtape(const ANomGrandAncien, AIdEtape : string; out ATexte : string) : Boolean;
      end;

  implementation

    uses

      SuperObject;

    { TGestionnaireGrandsAnciens }

    constructor TGestionnaireGrandsAnciens.Create;
      begin
        inherited Create;

        FGrandsAnciensParNom := TDictionary<string, TGrandAncien>.Create;
        FReglesEtapesParGrandAncien := TObjectDictionary<string, TDictionary<string, string>>.Create([doOwnsValues]);
      end;

    destructor TGestionnaireGrandsAnciens.Destroy;
      begin
        FReglesEtapesParGrandAncien.Free;
        FGrandsAnciensParNom.Free;

        inherited;
      end;

    procedure TGestionnaireGrandsAnciens.ChargerDepuisFichier(const ACheminFichier : string);
      var
        Tableau : ISuperArray;
        i : Integer;
        Racine, EntreeJSON, ReglesJSON, BatailleJSON, EtapesJSON : ISuperObject;
        GrandAncien : TGrandAncien;
        NomCle : string;
        ReglesEtapes : TDictionary<string, string>;
        Iter : TSuperObjectIter;
      begin
        if not FileExists(ACheminFichier) then
          raise EFileNotFoundException.CreateFmt('Fichier des Grands Anciens introuvable : "%s".',
                                                 [ACheminFichier]);

        Racine := TSuperObject.ParseFile(ACheminFichier, False);
        if not Assigned(Racine) then
          raise EGrandsAnciensInvalidesException.CreateFmt('JSON invalide dans le fichier "%s".',
                                                           [ACheminFichier]);

        Tableau := Racine.A['GrandsAnciens'];
        if not Assigned(Tableau) then
          raise EGrandsAnciensInvalidesException.CreateFmt(
            'Le fichier "%s" ne contient pas de tableau racine "GrandsAnciens".',
            [ACheminFichier]);

        FGrandsAnciensParNom.Clear;
        FReglesEtapesParGrandAncien.Clear;

        for i := 0 to Tableau.Length - 1 do
          begin
            EntreeJSON := Tableau.O[i];

            if EntreeJSON.S['Nom'] = EmptyStr then
              raise EGrandsAnciensInvalidesException.CreateFmt(
                'Un Grand Ancien sans "Nom" a été rencontré dans "%s".', [ACheminFichier]);

            with GrandAncien do
              begin
                Nom := EntreeJSON.S['Nom'];
                Image := EntreeJSON.S['Image'];
                TailleEchelleDestin := EntreeJSON.I['TailleEchelleDestin'];
                EnSommeil := EmptyStr;
                Special := EmptyStr;
                Adorateurs := EmptyStr;
                Bataille.Combat := 0;
                Bataille.Defense := EmptyStr;
              end;

            ReglesEtapes := TDictionary<string, string>.Create;

            ReglesJSON := EntreeJSON.O['Regles'];
            if Assigned(ReglesJSON) then
              begin
                GrandAncien.EnSommeil := ReglesJSON.S['EnSommeil'];
                GrandAncien.Special := ReglesJSON.S['Special'];
                GrandAncien.Adorateurs := ReglesJSON.S['Adorateurs'];

                BatailleJSON := ReglesJSON.O['Bataille'];
                if Assigned(BatailleJSON) then
                  begin
                    GrandAncien.Bataille.Combat := BatailleJSON.I['Combat'];
                    GrandAncien.Bataille.Defense := BatailleJSON.S['Defense'];
                  end;

                EtapesJSON := ReglesJSON.O['Etapes'];
                if Assigned(EtapesJSON) then
                  if ObjectFindFirst(EtapesJSON, Iter) then
                    repeat
                      ReglesEtapes.AddOrSetValue(Iter.key, Iter.val.AsString);
                    until not ObjectFindNext(Iter);
              end;

            NomCle := LowerCase(GrandAncien.Nom);
            FGrandsAnciensParNom.AddOrSetValue(NomCle, GrandAncien);
            FReglesEtapesParGrandAncien.AddOrSetValue(NomCle, ReglesEtapes);
          end;
      end;

    function TGestionnaireGrandsAnciens.Noms : TArray<string>;
      var
        GrandAncien : TGrandAncien;
        Resultat : TList<string>;
      begin
        Resultat := TList<string>.Create;
        try
          for GrandAncien in FGrandsAnciensParNom.Values do
            Resultat.Add(GrandAncien.Nom);
          Result := Resultat.ToArray;
        finally
          Resultat.Free;
        end;
      end;

    function TGestionnaireGrandsAnciens.TryObtenirGrandAncien(const ANomGrandAncien : string; out AGrandAncien: TGrandAncien): Boolean;
      begin
        Result := FGrandsAnciensParNom.TryGetValue(LowerCase(ANomGrandAncien), AGrandAncien);
      end;

    function TGestionnaireGrandsAnciens.TryObtenirRegleEtape(const ANomGrandAncien, AIdEtape : string; out ATexte : string) : Boolean;
      var
        ReglesEtapes : TDictionary<string, string>;
      begin
        Result := False;
        ATexte := EmptyStr;
        if FReglesEtapesParGrandAncien.TryGetValue(LowerCase(ANomGrandAncien), ReglesEtapes) then
          Result := ReglesEtapes.TryGetValue(AIdEtape, ATexte);
      end;

end.
