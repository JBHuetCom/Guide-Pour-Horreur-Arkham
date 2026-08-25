unit AH.Core.GrandsAnciens;

  interface

    uses

      System.SysUtils, System.Generics.Collections, System.Classes;

    type

      /// <summary>Règles de bataille contre un Grand Ancien.</summary>
      TReglesBataille = record
        /// <summary>Modificateur des attaques des investigateurs (ex: -1 pour Azathoth).</summary>
        Combat : Integer;
        /// <summary>Capacité spéciale de défense du Grand Ancien.</summary>
        Defense : string;
      end;

      /// <summary>Règles spéciales associées à un Grand Ancien.</summary>
      TReglesGrandAncien = record
        /// <summary>Liste des étapes où des règles spéciales doivent être affichées.</summary>
        Etapes : TArray<string>;
        /// <summary>Règle affichée tant que le Grand Ancien est endormi.</summary>
        EnSommeil : string;
        /// <summary>Règle affichée en permanence.</summary>
        Special : string;
        /// <summary>Règle affichée tant que la bataille n'a pas commencé.</summary>
        Adorateurs : string;
        /// <summary>Règles spécifiques à la bataille finale.</summary>
        Bataille : TReglesBataille;
      end;

      /// <summary>
      /// Représente un Grand Ancien avec ses règles et son illustration.
      /// </summary>
      TGrandAncien = record
        /// <summary>Nom du Grand Ancien (ex: "Azathoth").</summary>
        Nom : string;
        /// <summary>Nom du fichier image (ex: "azathoth.png"). Peut être EmptyStr.</summary>
        Image : string;
        /// <summary>Taille maximale de l'échelle du destin.</summary>
        TailleEchelleDestin : Integer;
        /// <summary>Règles spéciales du Grand Ancien. Certains champs peuvent manquer.</summary>
        Regles : TReglesGrandAncien;
      end;

      /// <summary>
      /// Gestionnaire des Grands Anciens, chargé depuis un fichier JSON.
      /// </summary>
      TGestionnaireGrandsAnciens = class
        private
          FGrandsAnciensParNom : TDictionary<string, TGrandAncien>;
        public
          constructor Create;
          destructor Destroy; override;

          /// <param name="ACheminFichier">Chemin du fichier grands_anciens.json.</param>
          /// <exception cref="EFileNotFoundException">Levé si le fichier est introuvable.</exception>
          procedure ChargerDepuisFichier(const ACheminFichier : string);

          /// <summary>Liste de tous les noms de Grands Anciens chargés.</summary>
          function Noms : TArray<string>;

          /// <param name="ANomGrandAncien">Nom du Grand Ancien recherché (insensible à la casse).</param>
          /// <param name="AGrandAncien">Grand Ancien trouvé si la fonction retourne True.</param>
          /// <returns>True si le Grand Ancien existe, False sinon.</returns>
          function TryObtenirGrandAncien(const ANomGrandAncien : string; out AGrandAncien : TGrandAncien) : Boolean;
      end;

  implementation

    uses

      SuperObject;

    constructor TGestionnaireGrandsAnciens.Create;
      begin
        inherited Create;

        FGrandsAnciensParNom := TDictionary<string, TGrandAncien>.Create;
      end;

    destructor TGestionnaireGrandsAnciens.Destroy;
      begin
        FGrandsAnciensParNom.Free;

        inherited;
      end;

    procedure TGestionnaireGrandsAnciens.ChargerDepuisFichier(const ACheminFichier : string);
      var
        Racine : ISuperObject;
        Tableau : ISuperArray;
        i : Integer;
        GrandAncien : TGrandAncien;
        ReglesObj, BatailleObj : ISuperObject;
      begin
        if not FileExists(ACheminFichier) then
          raise EFileNotFoundException.CreateFmt('Fichier des Grands Anciens introuvable: "%s".',
                                                 [ACheminFichier]);

        Racine := TSuperObject.ParseFile(ACheminFichier, False);
        if Racine = nil then
          raise Exception.Create('JSON invalide dans grands_anciens.json');

        Tableau := Racine.A['GrandsAnciens'];
        if Tableau = nil then
          raise Exception.Create('Le fichier ne contient pas de tableau "GrandsAnciens".');

        FGrandsAnciensParNom.Clear;
        for i := 0 to Tableau.Length - 1 do
          begin
            // Initialiser avec des valeurs par défaut
            with GrandAncien do
              begin
                Nom := EmptyStr;
                Image := EmptyStr;
                TailleEchelleDestin := 0;
                with Regles do
                  begin
                    Etapes := nil;
                    EnSommeil := EmptyStr;
                    Special := EmptyStr;
                    Adorateurs := EmptyStr;
                    Bataille.Combat := 0;
                    Bataille.Defense := EmptyStr;
                  end;
              end;

            // Charger les données
            with Tableau.O[i] do
              begin
                GrandAncien.Nom := S['Nom'];
                if S['Image'] <> EmptyStr then
                  GrandAncien.Image := S['Image'];

                if not TryStrToInt(S['TailleEchelleDestin'], GrandAncien.TailleEchelleDestin) then
                  GrandAncien.TailleEchelleDestin := 0;

                // Charger les règles
                ReglesObj := O['Regles'];
                if ReglesObj <> nil then
                  begin
                    // Etapes
                    if ReglesObj.A['Etapes'] <> nil then
                      GrandAncien.Regles.Etapes := ReglesObj.A['Etapes'].AsStringArray;

                    // EnSommeil
                    if ReglesObj.S['EnSommeil'] <> EmptyStr then
                      GrandAncien.Regles.EnSommeil := ReglesObj.S['EnSommeil'];

                    // Special
                    if ReglesObj.S['Special'] <> EmptyStr then
                      GrandAncien.Regles.Special := ReglesObj.S['Special'];

                    // Adorateurs
                    if ReglesObj.S['Adorateurs'] <> EmptyStr then
                      GrandAncien.Regles.Adorateurs := ReglesObj.S['Adorateurs'];

                    // Bataille
                    BatailleObj := ReglesObj.O['Bataille'];
                    if BatailleObj <> nil then
                      begin
                        if TryStrToInt(BatailleObj.S['Combat'], GrandAncien.Regles.Bataille.Combat) = False then
                          GrandAncien.Regles.Bataille.Combat := 0;

                        if BatailleObj.S['Défense'] <> EmptyStr then
                          GrandAncien.Regles.Bataille.Defense := BatailleObj.S['Défense'];
                      end;
                  end;
              end;

            if GrandAncien.Nom <> EmptyStr then
              FGrandsAnciensParNom.AddOrSetValue(AnsiLowerCase(GrandAncien.Nom), GrandAncien);
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

    function TGestionnaireGrandsAnciens.TryObtenirGrandAncien(const ANomGrandAncien : string;
                                                              out AGrandAncien : TGrandAncien) : Boolean;
      begin
        Result := FGrandsAnciensParNom.TryGetValue(AnsiLowerCase(ANomGrandAncien), AGrandAncien);
      end;

end.
